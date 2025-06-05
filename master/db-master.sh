#!/bin/bash

MYSQL_CONFIG="/etc/mysql/mysql.conf.d/mysqld.cnf"
APP_USER="app_user"                     # Пользователь для приложения
APP_PASS="123"                          # Пароль пользователя приложения
REPL_USER="repl_user"                   # Пользователь для репликации
REPL_PASS="123"                         # Пароль пользователя для репликации

user_exists() {
   sudo  mysql -Nse "SELECT EXISTS(SELECT 1 FROM mysql.user WHERE User='$1' AND Host='%')" 2>/dev/null
}


#Установка MySQL
echo "Обновление пакетов..."
#sudo apt update -qq
if ! command -v mysql &> /dev/null; then
sudo apt install mysql-server-8.0 -y
sudo systemctl enable mysql
fi

#Версия mysql
echo "MySQL version: $(mysql --version)"

#Настройки MySQL
cat <<'EOL' | sudo tee "$MYSQL_CONFIG" > /dev/null
[mysqld]
user                    = mysql
bind-address            = 0.0.0.0
key_buffer_size         = 16M
myisam-recover-options  = BACKUP
log_error               = /var/log/mysql/error.log
server-id               = 1
max_binlog_size         = 100M
gtid-mode               = ON
enforce-gtid-consistency
log-replica-updates
EOL
echo 'Конфигурация mysql настроена'

sudo systemctl restart mysql
sudo systemctl status mysql

#Пользователь для приложения

if [ "$(user_exists "$APP_USER")" -eq 0 ]; then
    echo "Создаю пользователя: $APP_USER"
   sudo mysql <<MYSQL_SCRIPT
        CREATE USER '$APP_USER'@'%' IDENTIFIED BY '$APP_PASS';
        GRANT ALL PRIVILEGES ON *.* TO '$APP_USER'@'%' WITH GRANT OPTION;
MYSQL_SCRIPT
else
    echo "Пользователь $APP_USER уже существует."
fi

#Пользователь для репликации
if [ "$(user_exists "$REPL_USER")" -eq 0 ]; then
    echo "Создаю пользователя: $REPL_USER"
   sudo mysql <<MYSQL_SCRIPT
        CREATE USER '$REPL_USER'@'%' IDENTIFIED BY '$REPL_PASS';
        GRANT REPLICATION SLAVE ON *.* TO '$REPL_USER'@'%';
MYSQL_SCRIPT
else
    echo "Пользователь $REPL_USER уже существует."
fi

