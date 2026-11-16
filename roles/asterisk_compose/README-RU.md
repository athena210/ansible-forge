# asterisk_compose

Это пример развертывания asterisk и certbot в docker compose.

Роль устанавливает docker compose в каталог заданный переменной `asterisk_compose__workdir`, где содержатся контейнеры сервера asterisk и контейнеры выпуска/обновления сертификатов на базе letsencrypt. Сертификаты опциональны и активируют шифрование канала сигнализации SIP между asterisk и абонентами. Asterisk настроен на провайдера Telphin, динамическое подключение к его серверам с резервированием входящей связи. Диалплан предусматривает одну линию для входящих и исходящих звонков, подключение группы пользователей, где один может звонить и принимать звонки из внешнего мира, а остальные могут созваниваться между собой или звонить наружу. Дополнительно устанавливается jail для fail2ban, который настроен на перехват логов asterisk из контейнера. Сам fail2ban здесь не прилагается, его следует устанавливать отдельно.

TODO: Нужно написать сервис для работы с очередью СМС сообщений.

В роли используется asterisk из репозитория alpine с дополнительно загруженными голосовыми сигналами на русском из официальных коллекций asterisk, а также предустановлен jinjanator для формирования конфигурации. Для запуска используется systemd сервис заданный переменной `asterisk_compose__name_systemd_service`. Для гибкости конфигурации вся папка /etc/asterisk формируется при каждом старте контейнера скриптом entrypoint. Если при запуске будет найден сертификат сервера, то для пользователей будут доступны подключения по SIP и SIPS одновременно, в противном случае поддержка SIPS не включится. В этом примере все пользователи имеют одинаковый пароль для упрощения. Список пользователей проходит двойное преобразование - из переменных роли в файл `userlist.yaml` в каталоке compose, затем при старте контейнера в `/etc/asterisk/users/users.txt`, откуда парсится скриптом в разные места конфигурации asterisk в нужных форматах.

Для работы с сертификатами letsencrypt используется образ на базе официального образа certbot, куда дополнительно устанавливается docker-cli чтобы перезагружать контейнер asterisk если сертификат обновится. Подтверждение владения доменными именами выполняется через certbot хуки, которые обновляют `_acme-challenge` записи типа TXT по DDNS. DNS хостер в этом примере Hurricane Electric, работа с ним жестко прописана в хуках. Для формирования красивого SIP адреса типа `123@example.com` нужно серверу asterisk выдать сертификат на два SAN - `tlf.example.com` и `example.com`. Подтверждение `example.com` с этого сервера может быть затруднено если сертификат на этот домен уже используется, например на web сервере, поэтому выбран такой manual метод подтверждения через хуки. На хост устанавливается systemd таймер и сервис, который раз в день выполняют запуск контейнера, обновляющего сертификат. При успешном обновлении из контейнера поступает команда на перезапуск контейнера asterisk. Первичный выпуск сертификата следует выполнить вручную командой
```shell
docker compose run --rm --service-ports --build --name certbot_issue cert_issue
```

Памятка по полезным командам
```shell
# первичный выпуск сертификата вручную
docker compose run --rm --service-ports --build --name certbot_issue cert_issue
# перевыпуск сертификата
docker compose run --rm --service-ports --build --name certbot_renew cert_renew
# почитать логи
journalctl CONTAINER_NAME=certbot_renew
journalctl CONTAINER_NAME=asterisk

```

## Использование роли

Параметры роли
|Переменная|default|Описание|
|-|-|-|
|asterisk_compose__workdir|/var/lib/asterisk-compose|Это рабочая папка для docker compose. Туда копируется asterisk-compose.yaml создается .env|
|asterisk_compose__name_systemd_service|asterisk-compose|Имя systemd сервиса, который будет стартовать docker compose.|
|asterisk_compose__alpine_ver_tlf||Версия alpine для основы образа asterisk|
|asterisk_compose__asterisk_line_id||ID линии Telphin|
|asterisk_compose__asterisk_line_password||Пароль линии Telphin|
|asterisk_compose__asterisk_line_tlf||Телефон линии Telphin|
|asterisk_compose__asterisk_server_dns_name||DNS сервера asterisk. Например tlf.example.com|
|asterisk_compose__asterisk_server_dns_domain||DNS домен сервера asterisk. Например example.com|
|asterisk_compose__asterisk_sms_password||Пароль для авторизации при отправке СМС скриптом|
|asterisk_compose__asterisk_client_password||Общий пароль для клиентов|
|asterisk_compose__asterisk_alien_password||Общий пароль для других клиентов. Например им можно задать другой диалплан, ограничить звонки итп|
|asterisk_compose__asterisk_trusted_addrs||Массив адресов, которые не должен блокировать fail2ban|
|asterisk_compose__asterisk_users||Список клиентов. num - тлф номер, name - callerid, grp - номера группы перехвата через запятую. Клиенты из одной группы могут перехватывать звонки друг друга|
|asterisk_compose__certbot_domains||Массив для DDNS обновления `_acme-challenge` TXT записей. name - домен в котором находится запись. dns_key - ключ авторизации|


Пример плейбука

```yaml
- name: Global play
  hosts: all

  roles:
    - role: asterisk_compose
      vars:
        asterisk_compose__workdir: /var/lib/asterisk-compose
        asterisk_compose__name_systemd_service: asterisk-compose
        asterisk_compose__alpine_ver_tlf: 3.24
        asterisk_compose__asterisk_line_id: 12345678
        asterisk_compose__asterisk_line_password: Password1
        asterisk_compose__asterisk_line_tlf: 70010020304
        asterisk_compose__asterisk_server_dns_name: tlf.example.com
        asterisk_compose__asterisk_server_dns_domain: example.com
        asterisk_compose__asterisk_sms_password: Password2
        asterisk_compose__asterisk_client_password: Password_client
        asterisk_compose__asterisk_alien_password: Password_guest
        asterisk_compose__asterisk_trusted_addrs:
          - 1.2.3.4
          - 5.6.7.8
        asterisk_compose__asterisk_users:
          - num: 991
            name: Alex
            grp: 1,2
          - num: 992
            name: Mike
            grp: 1
        asterisk_compose__certbot_domains:
          - name: tlf.example.com
            dns_key: DDNS_KEY_1
          - name: example.com
            dns_key: DDNS_KEY_2

```
