# Registry setup

Устанавливает собственный docker registry, certbot и nginx реверс прокси. Весь комплекс запускается с docker compose, требуется предварительная установка docker engine.

Параметры роли
|Переменная|default|Описание|
|-|-|-|
|registry_setup__workdir|/var/lib/docker-registry|Рабочий каталог docker compose|
|registry_setup__name_systemd_registry|docker-registry|Systemd имя сервиса запуска docker compose|
|registry_setup__name_systemd_certbot|docker-registry-certbot|Systemd имя сервиса и таймера certbot|
|registry_setup__certbot_interval_hours|12|Systemd таймер проверки certbot запускается каждые 12 часов|
|registry_setup__domain_name||DNS имя registry|

```shell
# issue new cert
docker compose run --rm --service-ports certbot sh -c 'certbot certonly --agree-tos --standalone -n -d "$CERTBOT_DOMAIN"'
# renew cert
docker compose run --rm --service-ports certbot
# add registry auth
docker run --rm --entrypoint htpasswd httpd -Bbn testuser testpassword > auth/registry.htpasswd
```
