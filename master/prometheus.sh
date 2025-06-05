#!/bin/bash

PROMETHEUS_CONFIG="/etc/prometheus/prometheus.yml"

# Обновление пакетов
echo "Обновление пакетов..."
#sudo apt-get update -qq


if ! command -v prometheus &> /dev/null; then
 sudo apt-get install -y prometheus
 echo 'Prometheus установлен.'
fi
 

cat <<'EOL' | sudo tee "$PROMETHEUS_CONFIG" > /dev/null
global:
  scrape_interval:     15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
  external_labels:
      monitor: 'example'
alerting:
  alertmanagers:
  - static_configs:
    - targets: ['localhost:9093']
rule_files:
scrape_configs:
  - job_name: 'prometheus'
    scrape_interval: 5s
    scrape_timeout: 5s
    static_configs:
      - targets: ['localhost:9090']

  - job_name: node
    static_configs:
      - targets: ['192.168.31.85:9100','192.168.31.221:9100','192.168.31.137:9100']
EOL
echo 'Конфигурация prometheus настроена'
sudo systemctl restart prometheus
sudo systemctl status prometheus


#GRAFANA

if ! command -v grafana &> /dev/null; then
 sudo apt install -y adduser libfontconfig1
 sudo dpkg -i /home/rasim/otus/grafana_10.0.3_amd64.deb
 echo 'Grafana установлена'
fi
 
sudo systemctl restart grafana-server.service
sudo systemctl status grafana-server.service 
