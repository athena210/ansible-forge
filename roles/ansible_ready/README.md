# Ansible_ready

# План

Скрипт подготовки, без ключа и правки ssh
``` shell

# debian-ubuntu
useradd -m --shell /bin/sh ansible && apt update && apt install -y python3 python3-pip

# alpine
adduser --disabled-password --shell /bin/sh ansible && apk update && apk add --no-cache python3 py3-pip

# opensuse
useradd -m --shell /bin/sh ansible && zypper refresh && zypper install openssh python3 python3-pip

# arch
# centos

cat > /etc/sudoers.d/ansible <<SUDOERS
Defaults:ansible !fqdn
Defaults:ansible !requiretty
ansible ALL=(ALL) NOPASSWD: ALL
SUDOERS
```

## Установка вручную

Установка роли выполняется обычным клонированием репозитория

```shell
cd ansible/roles
git clone 'https://github.com/athena210/ansible-role-ansible.git' ansible_ready
```

## Установка списком

Установку можно выполнять из списка в файле `requirements-galaxy.yml`

```yaml
---
roles:
  - src: https://github.com/athena210/ansible-role-ansible.git
    name: ansible_ready
    scm: git
    version: master
```

Запуск установки

```shell
cd ansible
ansible-galaxy install -p roles -r requirements-galaxy.yml
```

## Подготовка
Готовит хост для подключений ansible. На хосте должен быть установлен python3 и присутствовать пользователь с парольным входом и парольным sudo. На управляющей машине нужно установить `passlib`.

Пользователь и пароли должны быть заданы до запуска плейбука переменными `ansible_user`, `ansible_password` и `ansible_become_password`. Например из ansible-vault
``` shell
cat <<-VAULT | ansible-vault encrypt --output ansible/ssh_vault.yaml
ansible_user: superadmin
ansible_password: supersecret
ansible_become_password: supersecret
VAULT
```

Установить зависимости
``` shell
pipx runpip ansible install -r ansible/roles/ansible_ready/requirements-pip.txt
```

Приготовить новый ssh ключ для пользователя ansible
``` shell
ssh-keygen -t ed25519 -C ansible -N '' -f ansible/ansible-ssh.key
```

## Параметры роли

Поддерживается работа в семействах:
  - debian
  - alpine
  - suse
  - archlinux
  - redhat

|Переменная|default|Описание|
|-|-|-|
|ansible_ready__ssh_key_file|ansible/ansible-ssh.key.pub|Файл ключа, который будет добавлен на хост. Файл ищется в каталоге с плейбуком.|
|ansible_ready__pkg_cache_update|true|Сделать обновление кэша пакетов перед установкой python3 и pip3.|
|ansible_ready__home_basedir|/home|Каталог на хосте, где создаются домашние директории пользователей. Если хост создает в другом месте, то здесь надо изменить.|
|ansible_ready__ansible_password|Случайный если не задано|Пароль, который будет задан пользователю ansible.|
|ansible_ready__ssh_deny_root_and_password|true|Запретить вход по паролю и для root. Выполняет HUP sshd.|


Первый плейбук будет содержать одну роль, тк при ansible_ready__ssh_deny_root_and_password=true парольное соединение рвется после выполнения роли и нужно подключаться по ssh ключу.

Запустить плейбук.
``` shell
ansible-playbook --extra-vars @ssh_vault.yaml --ask-vault-pass playbook-ansible-ready.yaml
```
