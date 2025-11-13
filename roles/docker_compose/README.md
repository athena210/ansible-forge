# ШАБЛОН РОЛИ для развертывания docker compose

Эта роль является шаблоном для деплоя docker compose вместе с управляющим systemd сервисом. В текущей версии роль загрузит демо `docker-compose.yaml`, демо переменную в `.env`, установит и запустит systemd сервис.
Полноценное использование роли подразумевает модификацию, добавление необходимых файлов и каталогов для compose итп.

## Использование роли

Параметры роли
|Переменная|default|Описание|
|-|-|-|
|docker_compose__workdir|/var/lib/docker-compose1|Это рабочая папка для docker-compose. Туда копируется docker-compose.yaml создается .env|
|docker_compose__name_systemd_service|docker-compose1|Имя systemd сервиса, который будет стартовать docker compose.|



Пример плейбука

```yaml
- name: Global play
  hosts: all

  roles:
    - role: docker_compose
      vars:
        docker_compose__workdir: /var/lib/docker-compose2
        docker_compose__name_systemd_service: my_project
```
