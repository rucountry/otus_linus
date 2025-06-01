#!/bin/bash
/usr/bin/mysqldump --add-drop-table --add-locks --create-options --disable-keys --extended-insert --single-transaction --quick --set-charset --events --routines --triggers --set-gtid-purged=OFF otus > /home/rasim/otus/otus.sql
