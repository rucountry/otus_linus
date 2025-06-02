#!/bin/bash

# Настройки
SERVICE_NAME="OtusEduWebApi"
PROJECT_DIR="/var/webapps/otus"          # Абсолютный путь!
PUBLISH_DIR="$PROJECT_DIR/publish"        # Теперь в системной директории
PROJECT_FILE="OtusEduWebApi.csproj"
RUNTIME="linux-x64"
PORT=5000

# Создаем рабочую директорию
sudo mkdir -p $PROJECT_DIR
sudo chown -R $USER:$USER $PROJECT_DIR    # Даем права текущему пользователю

# Установка зависимостей
sudo apt-get update
sudo apt-get install -y apt-transport-https
sudo apt-get install -y dotnet-sdk-8.0
sudo apt-get install -y prometheus-node-exporter

# Копируем проект в рабочую директорию (если скрипт запускается из репозитория)
cp -r /home/rasim/otus_linus/OtusEduWebApi/* $PROJECT_DIR
cd $PROJECT_DIR

# Восстановление зависимостей
dotnet restore

# Сборка
dotnet build -c Release --no-restore

# Публикация
dotnet publish -c Release -o $PUBLISH_DIR --runtime $RUNTIME --self-contained false

# Настройка прав для службы
sudo chown -R www-data:www-data $PUBLISH_DIR
sudo chmod 755 $PUBLISH_DIR

# Создание службы systemd
sudo tee /etc/systemd/system/$SERVICE_NAME.service > /dev/null <<EOF
[Unit]
Description=ASP.NET Web API Application on Kestrel

[Service]
WorkingDirectory=$PUBLISH_DIR
ExecStart=/usr/bin/dotnet $PUBLISH_DIR/${PROJECT_FILE%.*}.dll
Restart=always
RestartSec=10
SyslogIdentifier=$SERVICE_NAME
User=www-data
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=ASPNETCORE_URLS=http://0.0.0.0:$PORT

[Install]
WantedBy=multi-user.target
EOF

# Перезагрузка служб
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME
sudo systemctl restart $SERVICE_NAME
sudo systemctl restart prometheus-node-exporter

echo "Проверка статуса:"
sudo systemctl status $SERVICE_NAME
