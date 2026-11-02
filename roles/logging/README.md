# Установка и настройка логов и ротации

Логирование systemd переносится с диска в память, уменьшается размер журналов в памяти. Устанавливается `rsyslog` и `logrotate`.




## Использование роли

Поддерживается только `debian` и `ubuntu` на архитектуре `amd_x64`.

Параметры роли
|Переменная|default|Описание|
|-|-|-|
|logging__store|volatile|Хранить логи volatile - ram, persistent - disk, none - redirect|
|logging__disk_size|10M|Занимать на диске под хранение логов|
|logging__ram_size|10M|Занимать в памяти под хранение логов|
|logging__file_size|2M|Размер каждого лог файла|
|logging__install_rsyslogd|false|Устанавливать rsyslogd и logrotate, копировать конфиги|
|logging__pkg_cache_update|true|Выполнять ли apt update при установке (часто необходимо на свежей ОС)|



Пример плейбука

```yaml
- name: Global play
  hosts: all

  roles:
    - role: logging
      vars:
        logging__disk_size: 128M
        logging__store: persistent
```
