#!/bin/bash
############################
# File Name: remote_backup_mysql.sh
# Author: Laifengting
# mail: 396096473@qq.com
# Created Time: Thu Dec 30 15:34:40 CST 2021
# Version: 1.2.2
############################

# 校验是否安装 gzip
rpm -q gzip >/dev/null || yum install gzip -y >/dev/null 2>&1

# 创建变量记录时间，用于创建文件名
today=$(date '+%Y-%m-%d_%H-%M-%S')

# 执行备份命令
echo "开始备份"
mysqldump -uroot -pLft123456~ \
--single-transaction \
--master-data=1 \
--triggers --events --routines \
-A | gzip -c | ssh root@47.100.192.243 \
'cat > /opt/all_databases_backup_$today.tgz'
echo "备份完成"
