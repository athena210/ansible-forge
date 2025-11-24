# ansible-role-docker-engine

## Установка вручную

Установка роли выполняется обычным клонированием репозитория

```shell
cd ansible/roles
git clone 'https://github.com/athena210/ansible-role-docker-engine.git' docker_engine
```

## Установка списком

Установку можно выполнять из списка в файле `requirements-galaxy.yml`

```yaml
---
roles:
  - name: docker_engine
    src: https://github.com/athena210/ansible-role-docker-engine.git
    scm: git
    version: main
```

Запуск установки

```shell
cd ansible
ansible-galaxy install -p roles -r requirements-galaxy.yml
```
