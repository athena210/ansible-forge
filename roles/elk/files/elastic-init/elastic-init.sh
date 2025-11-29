#!/bin/bash

if [ -z "${PROJECT_ELASTIC_PASSWORD}" ]; then
    echo "Set the PROJECT_ELASTIC_PASSWORD environment variable."
    exit 1
elif [ -z "${PROJECT_ELASTIC_KIBANA_PASSWORD}" ]; then
    echo "Set the PROJECT_ELASTIC_KIBANA_PASSWORD environment variable."
    exit 1
elif [ -z "${PROJECT_ELASTIC_LOGSTASH_PASSWORD}" ]; then
    echo "Set the PROJECT_ELASTIC_LOGSTASH_PASSWORD environment variable."
    exit 1
fi

# Here in PWD is the home dir /usr/share/elasticsearch
cd "${PWD}" || exit 1

if [ ! -f config/certs/ca.zip ]; then
    echo "Creating CA"
    ./bin/elasticsearch-certutil ca --silent --pem -out config/certs/ca.zip
    unzip config/certs/ca.zip -d config/certs
fi
if [ ! -f config/certs/certs.zip ]; then
    echo "Creating certs"
    cat << INST_FILE > config/certs/instances.yml
instances:
  - name: elastic1
    dns:
      - elastic1
      - localhost
    ip:
      - 127.0.0.1
INST_FILE
    bin/elasticsearch-certutil cert --silent --pem -out config/certs/certs.zip --in config/certs/instances.yml --ca-cert config/certs/ca/ca.crt --ca-key config/certs/ca/ca.key
    unzip config/certs/certs.zip -d config/certs
fi

echo "Setting file permissions"
chown -R 0:0 config/certs
find . -type d -exec chmod 755 '{}' \;
find . -type f -exec chmod 644 '{}' \;

echo "Waiting for Elasticsearch availability"
until curl -s --cacert config/certs/ca/ca.crt https://elastic1:9200 | grep -q "missing authentication credentials"; do
    sleep 30
done


echo "Creating ILM policy"
until curl -s -X PUT --cacert config/certs/ca/ca.crt \
    -u "elastic:${PROJECT_ELASTIC_PASSWORD}" \
    -H 'Content-Type: application/json' \
    https://elastic1:9200/_ilm/policy/MY_ILM_POLICY -d \
    '{
        "policy": {
            "phases": {
                "hot": {
                    "actions": {
                        "rollover": {
                            "max_primary_shard_size": "1gb"
                        }
                    }
                },
                "delete": {
                    "min_age": "5d",
                    "actions": {
                        "delete": {}
                    }
                }
            }
        }
    }' | grep -q '{"acknowledged":true}'; do
        sleep 10
done


echo "Creating a component template for mappings"
until curl -s -X PUT --cacert config/certs/ca/ca.crt \
    -u "elastic:${PROJECT_ELASTIC_PASSWORD}" \
    -H 'Content-Type: application/json' \
    https://elastic1:9200/_component_template/my-mappings -d \
    '{
        "template": {
            "mappings": {
                "properties": {
                    "@timestamp": {
                        "type": "date",
                        "format": "date_optional_time||epoch_millis"
                    },
                        "message": {
                        "type": "wildcard"
                    }
                }
            }
        },
        "_meta": {
            "description": "Mappings for @timestamp and message fields",
            "my-custom-meta-field": "More arbitrary metadata"
        }
    }' | grep -q '{"acknowledged":true}'; do
        sleep 10
done


echo "Creating a component template for index settings"
until curl -s -X PUT --cacert config/certs/ca/ca.crt \
    -u "elastic:${PROJECT_ELASTIC_PASSWORD}" \
    -H 'Content-Type: application/json' \
    https://elastic1:9200/_component_template/my-settings -d \
    '{
        "template": {
            "settings": {
                "index.lifecycle.name": "MY_ILM_POLICY"
            }
        },
        "_meta": {
            "description": "Settings for ILM",
            "my-custom-meta-field": "More arbitrary metadata"
        }
    }' | grep -q '{"acknowledged":true}'; do
        sleep 10
done


echo "Creating data stream template"
until curl -s -X PUT --cacert config/certs/ca/ca.crt \
    -u "elastic:${PROJECT_ELASTIC_PASSWORD}" \
    -H 'Content-Type: application/json' \
    https://elastic1:9200/_index_template/my_datastream_template -d \
    '{
        "index_patterns": ["logs-logstash-*"],
        "data_stream": {},
        "composed_of": [ "my-mappings", "my-settings" ],
        "priority": 500,
        "_meta": {
            "description": "Template for my time series data",
            "my-custom-meta-field": "More arbitrary metadata"
        }
    }' | grep -q '{"acknowledged":true}'; do
        sleep 10
done


echo "Setting kibana_system password"
until curl -s -X POST --cacert config/certs/ca/ca.crt \
    -u "elastic:${PROJECT_ELASTIC_PASSWORD}" \
    -H "Content-Type: application/json" \
    https://elastic1:9200/_security/user/kibana_system/_password \
    -d '{"password":"'${PROJECT_ELASTIC_KIBANA_PASSWORD}'"}' | grep -q "^{}"; do
        sleep 10
done


echo "Creating logstash_writer role"
# "names": ["logstash-*"],
# "privileges": ["write", "create", "create_index", "manage", "manage_ilm"]
until curl -s -X POST --cacert config/certs/ca/ca.crt \
    -u "elastic:${PROJECT_ELASTIC_PASSWORD}" \
    -H 'Content-Type: application/json' \
    https://elastic1:9200/_security/role/logstash_writer -d \
    '{
        "cluster": ["manage_index_templates", "monitor", "manage_ilm"],
        "indices": [
        {
            "names": ["logs-logstash-*", "logstash-*"],
            "privileges": ["auto_configure", "create_doc", "create_index", "view_index_metadata"]
        }
        ]
    }' | grep -q '"created":true'; do
        sleep 10
done


echo "Creating logstash_internal user"
until curl -s -X POST --cacert config/certs/ca/ca.crt \
    -u "elastic:${PROJECT_ELASTIC_PASSWORD}" \
    -H 'Content-Type: application/json' \
    https://elastic1:9200/_security/user/logstash_internal -d \
    '{
        "password" : "'${PROJECT_ELASTIC_LOGSTASH_PASSWORD}'",
        "roles" : [ "logstash_writer" ],
        "full_name" : "Internal Logstash User"
    }' | grep -q '"created":true'; do
        sleep 10
done


echo "Add kibana alert"
until curl -s -X POST \
    -u "elastic:${PROJECT_ELASTIC_PASSWORD}" \
    -H "Content-Type: application/json" \
    -H "kbn-xsrf: true" \
    http://kibana:5601/api/alerting/rule -d \
    '{
        "name": "http alarm",
        "consumer": "alerts",
        "rule_type_id": "logs.alert.document.count",
        "schedule": {
            "interval": "1m"
        },
        "params": {
            "timeSize": 1,
            "timeUnit": "m",
            "logView": {
                "type": "log-view-reference",
                "logViewId": "default"
            },
            "count": {
                "value": 1,
                "comparator": "more than or equals"
            },
            "criteria": [
                {
                    "field": "fields.input_type",
                    "comparator": "matches",
                    "value": "http"
                },
                {
                    "field": "json.content",
                    "comparator": "matches",
                    "value": "alarm"
                }
            ]
        },
        "actions": [],
        "notify_when": null,
        "throttle": null
    }' | grep -q '"created_by":"elastic"'; do
        sleep 10
done


echo "All done!"
