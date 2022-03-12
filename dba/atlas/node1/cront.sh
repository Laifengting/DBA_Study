#!/bin/bash
while [ true ]; do
/bin/sleep 1
/bin/bash /usr/local/mysql-proxy/atlas_check.sh
done
