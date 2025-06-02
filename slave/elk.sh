#!/bin/bash

JAVA_CONFIG="/etc/elasticsearch/jvm.options.d/jvm.options"
ELASTICSEARCH_CONFIG="/etc/elasticsearch/elasticsearch.yml"
KIBANA_CONFIG="/etc/kibana/kibana.yml"
LOGSTASH_CONFIG="/etc/logstash/logstash.yml"
LOGSTASH_NGINX_ES_CONFIG="/etc/logstash/conf.d/logstash-nginx-es.conf"

#Установка JDK
echo "Обновление пакетов..."
#sudo apt update -qq
if ! command -v java &> /dev/null; then
sudo apt install default-jdk -y
fi

echo "$(java --version)"

#Установка Elastiksearch
if ! sudo systemctl is-enabled elasticsearch &>/dev/null; then
#sudo dpkg -i /home/rasim/otus/elasticsearch-8.9.1-amd64.deb 
echo "Установка elasticsearch прошла успешно"
fi

#Настройки JAVA
cat <<'EOL' | sudo tee "$JAVA_CONFIG" > /dev/null
-Xms1g
-Xmx1g
EOL

#Настройка Elasticsearch
cat <<'EOL' | sudo tee "$ELASTICSEARCH_CONFIG" > /dev/null
#node.name: node-1
#node.attr.rack: r1
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
#network.host: 192.168.0.1
#http.port: 9200
#discovery.seed_hosts: ["host1", "host2"]
#cluster.initial_master_nodes: ["node-1", "node-2"]
#action.destructive_requires_name: false
xpack.security.enabled: false
xpack.security.enrollment.enabled: false
xpack.security.http.ssl:
  enabled: false
  keystore.path: certs/http.p12
xpack.security.transport.ssl:
  enabled: false
  verification_mode: certificate
  keystore.path: certs/transport.p12
  truststore.path: certs/transport.p12
cluster.initial_master_nodes: ["otussqlslave"]
http.host: 0.0.0.0
#transport.host: 0.0.0.0
EOL

sudo systemctl daemon-reload
sudo systemctl enable --now elasticsearch.service
sudo systemctl restart elasticsearch.service

#Установка kibana
if ! sudo systemctl is-enabled kibana &>/dev/null; then
#sudo dpkg -i /home/rasim/otus/kibana-8.9.1-amd64.deb
echo "Установка kibana прошла успешно"
fi

#Настройки Kibana
cat <<'EOL' | sudo tee "$KIBANA_CONFIG" > /dev/null
server.host: "0.0.0.0"
logging:
  appenders:
    file:
      type: file
      fileName: /var/log/kibana/kibana.log
      layout:
        type: json
  root:
    appenders:
      - default
      - file
EOL

sudo systemctl daemon-reload
sudo systemctl enable --now kibana.service
sudo systemctl restart kibana.service


#Установка logstash
if ! sudo systemctl is-enabled logstash &>/dev/null; then
#sudo dpkg -i /home/rasim/otus/logstash-8.9.1-amd64.deb
echo "Установка logstash прошла успешно"
fi

#Настройки Logstash
cat <<'EOL' | sudo tee "$LOGSTASH_CONFIG" > /dev/null
path.logs: /var/log/logstash
path.data: /var/lib/logstash
path.config: /etc/logstash/conf.d
EOL

#Настройка Logstash nginx-es
cat <<'EOL' | sudo tee "$LOGSTASH_NGINX_ES_CONFIG" > /dev/null
input {
    beats {
        port => 5400
    }
}

filter {
 grok {
   match => [ "message" , "%{COMBINEDAPACHELOG}+%{GREEDYDATA:extra_fields}"]
   overwrite => [ "message" ]
 }
 mutate {
   convert => ["response", "integer"]
   convert => ["bytes", "integer"]
   convert => ["responsetime", "float"]
 }
 date {
   match => [ "timestamp" , "dd/MMM/YYYY:HH:mm:ss Z" ]
   remove_field => [ "timestamp" ]
 }
 useragent {
   source => "agent"
 }
}

output {
 elasticsearch {
   hosts => ["http://localhost:9200"]
   #cacert => '/etc/logstash/certs/http_ca.crt'
   #ssl => true
   index => "weblogs-%{+YYYY.MM.dd}"
   document_type => "nginx_logs"
 }
 stdout { codec => rubydebug }
}
EOL


sudo systemctl daemon-reload
sudo systemctl enable --now logstash.service
sudo systemctl restart logstash.service

