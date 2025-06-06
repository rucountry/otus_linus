#!/bin/bash

set -e

# Configuration variables
PROJECT_DIR="/home/rasim/otus/product-app"
PROJECT_NAME="product-app"
NGINX_ROOT="/var/www/$PROJECT_NAME"
NGINX_CONFIG="/etc/nginx/sites-available/$PROJECT_NAME"

# Обновление пакетов
echo "Обновление пакетов..."
#sudo apt-get update -qq
sudo apt-get install -y prometheus-node-exporter

# Удаление nodejs и конфликтующих пакетов
#echo "Удаление nodejs и конфликтующих пакетов..."
#sudo apt-get purge -y nodejs npm libnode-dev nodejs-doc
#sudo rm -rf /etc/apt/sources.list.d/nodesource.list*
#sudo rm -rf /usr/lib/node_modules
#sudo rm -rf /var/lib/apt/lists/*
#sudo apt-get autoremove -y

# Установка nginx, если нет
if ! command -v nginx &> /dev/null; then
    echo "Установка nginx..."
    sudo apt-get install -y nginx
    echo "Включение nginx..."
    sudo systemctl enable nginx
fi

#--------------------------------------------------------------------------------------------------------------------------------------------------------------

if ! command -v node &> /dev/null; then
# Установка Node.js 22.x
echo "Загрузка Node.js 22.x..."
sudo apt-get install -y curl ca-certificates gnupg 
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
sudo apt-get update -qq
sudo apt-get install -y nodejs
fi

# Проверка версий NodeJS и NPM
echo "Node.js version: $(node -v)"
echo "npm version: $(npm -v)"

#--------------------------------------------------------------------------------------------------------------------------------------------------------------

# Установка angular cli, если не установлен
if ! command -v node &> /dev/null; then
echo "Установка Angular CLI ..."
sudo npm install -g @angular/cli
fi

echo "Angular CLI version $(ng --version)"

#--------------------------------------------------------------------------------------------------------------------------------------------------------------

# Установка зависимостей проекта
echo "Установка зависимостей проекта..."
cd "$PROJECT_DIR"
npm install --silent

#--------------------------------------------------------------------------------------------------------------------------------------------------------------

# Build Angular project
echo "Build Angular project..."
ng build

#-------------------------------------------------------------------------------------------------------------------------------------------------------------

# Создание директорий и деплой статики Angular
echo "Deploy to nginx..."
sudo mkdir -p "$NGINX_ROOT"
sudo cp -a "$PROJECT_DIR/dist/." "$NGINX_ROOT"

# Создание конфигурации nginx
echo "Конфигурация Nginx..."


cat <<'EOL' | sudo tee "$NGINX_CONFIG" > /dev/null
upstream backend {
    server 192.168.31.85:5000;  #back1
    server 192.168.31.221:5000;  #back2
}

server {
    listen 8080;
    server_name _;

    location / {
        root /var/www/product-app/product-app;
        try_files $uri $uri/ /index.html;
    }

    location /products {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Connection $http_connection;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Backend-Server $upstream_addr;
        add_header X-Backend-Server $upstream_addr always;
        client_max_body_size 100M;
        proxy_request_buffering off;
        
   }
}
EOL


# Подключение конфигурации
sudo ln -sf "$NGINX_CONFIG" "/etc/nginx/sites-enabled/"

# Test and reload Nginx
echo "Restarting Nginx..."
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl restart prometheus-node-exporter
