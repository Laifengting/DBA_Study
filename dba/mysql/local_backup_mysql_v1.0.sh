#!/bin/bash
############################
# File Name: local_backup_mysql.sh
# Author: Laifengting
# mail: 396096473@qq.com
# Created Time: Thu Dec 30 11:02:35 CST 2021
# Version: 1.1.5
############################

# 校验是否安装 pv
rpm -q pv >/dev/null || yum install pv -y >/dev/null 2>&1

# 校验是否安装 gzip
rpm -q gzip >/dev/null || yum install gzip -y >/dev/null 2>&1

# 创建变量记录时间，用于创建文件名
today=$(date '+%Y-%m-%d_%H-%M-%S')

mysql -uroot -pLft123456~ -e 'show databases;'

echo -n "Please input the Name of the database which you want to backup:"

read dbname

# 执行备份命令
echo "开始备份"

mysqldump -uroot -pLft123456~ \
--single-transaction \
--master-data=1 \
--triggers --events --routines \
-B $dbname | pv | gzip -c > $dbname\_backup_$today.tgz

echo "备份完成"
