# Установка и настройка логов и ротации

Логирование systemd переносится с диска в память, уменьшается размер журналов в памяти. Устанавливается `rsyslog` и `logrotate`.


## Установка вручную

Установка роли выполняется обычным клонированием репозитория

```shell
cd ansible/roles
git clone 'https://github.com/athena210/ansible-role-logging.git' logging
```


## Установка списком

Установку можно выполнять из списка в файле `requirements-galaxy.yml`

```yaml
---
roles:
  - name: logging
    src: https://github.com/athena210/ansible-role-logging.git
    scm: git
    version: main
```

Запуск установки

```shell
cd ansible
ansible-galaxy install -p roles -r requirements-galaxy.yml
```


## Использование роли

Поддерживается только `debian` и `ubuntu` на архитектуре `amd_x64`.

Параметры роли
|Переменная|default|Описание|
|-|-|-|
|logging__pkg_cache_update|true|Выполнять ли apt update при установке (часто необходимо на свежей ОС)|

Пример плейбука

```yaml
- name: Global play
  hosts: all

  roles:
    - role: logging
      vars:
        logging__pkg_cache_update: true
```
