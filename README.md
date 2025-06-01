0. Перейдем в домашнюю директорию /home/rasim и склонируем текущий репозиторий командой git clone git@github.com:rucountry/otus_linus.git
1. Запускаем скрипт /home/rasim/otus_linus/front/script.sh на машине для фронта
2. Запускаем скрипт /home/rasim/otus_linus/back/script.sh на машинах для бекенда
3. Запускаем скрипт /home/rasim/otus_linus/master/db-master.sh на машине, где мастер нода БД
4. Запускаем скрипт /home/rasim/otus_linus/slave/db-slave.sh на машине, где резервная нода БД
5. Запускаем скрипт /home/rasim/otus_linus/master/prometheus.sh на машине, где мастер нода БД. Размещен будет Prometheus + Grafana
6. Запускаем скрипт /home/rasim/otus_linus/slave/elk.sh на машине, где резервная нода БД. Размещен будет на этой машине Elasticsearch + Logstash + Kibana
7. Запускаем скрипт /home/rasim/otus_linus/front/filebeat.sh на машине для фронта. Размещен будет filebeat для сбора логов nginx
----------------------------------------------------------------------------------------------------------------------------------------------
Создание и развертывание из бекапа
1. Запускаем скрипт /home/rasim/otus_linus/slave/bcp_otus.sh на резервной ноде БД 
2. Добавляем в скрипт в самое начало подключение к БД. use otus;
3. Копируем бекап на мастер ноду
4. Создаем пустую базу данных на мастер ноде командой create database otus;
5. Разворачиваем бекап командой mysql < otus.sql

