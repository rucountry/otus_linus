#!/bin/bash

MYSQL_CONFIG="/etc/mysql/mysql.conf.d/mysqld.cnf"

#Установка MySQL
echo "Обновление пакетов..."
sudo apt update -qq
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
server-id               = 2
max_binlog_size         = 100M
gtid-mode               = ON
relay-log               = relay-log-server
read-only               = ON
enforce-gtid-consistency
log-replica-updates
EOL
echo 'Конфигурация mysql настроена'

sudo systemctl restart mysql

echo "Настройка репликации"
   sudo mysql <<MYSQL_SCRIPT
        STOP REPLICA;
        CHANGE REPLICATION SOURCE TO SOURCE_HOST='192.168.31.213', SOURCE_USER='repl_user', SOURCE_PASSWORD='123', SOURCE_AUTO_POSITION=1, GET_SOURCE_PUBLIC_KEY=1;
        START REPLICA; 
MYSQL_SCRIPT

sudo systemctl status mysql


