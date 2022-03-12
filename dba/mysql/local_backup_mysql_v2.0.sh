#!/bin/bash
############################
# File Name: local_backup_mysql.sh
# Author: Laifengting
# mail: 396096473@qq.com
# Created Time: Thu Dec 30 11:02:35 CST 2021
# Version: 2.1.9
############################

# 校验是否安装 pv
rpm -q pv >/dev/null || yum install pv -y >/dev/null 2>&1

# 校验是否安装 gzip
rpm -q gzip >/dev/null || yum install gzip -y >/dev/null 2>&1

# 创建变量记录时间，用于创建文件名
today=$(date '+%Y-%m-%d_%H-%M-%S')

echo -n "Please input the username of the mysql:"
read username
echo -n "Please input the password of the $username:"
read password

echo "Backup All Databases (A)"
echo "Backup Parts Of Databases (D)"
echo "Backup Parts Of Tables (T)"
echo -n "Please Choice Witch Backup Mode You Want To Use(Just Input A or D or T):"
read backupmode

case $backupmode in
    A)
        # 执行备份命令
        echo "开始备份"
        mysqldump -u$username -p$password \
        --single-transaction \
        --master-data=1 \
        --triggers --events --routines \
        -A | pv | gzip -c > all_databases_backup_$today.tgz
        echo "备份完成"
    ;;
    D)
        mysql -u$username -p$password -e "show Databases"
        echo -n "Please Choice The Name Of The Databases You Want To Backup,Separated By Space:"
        read dbnames
        # 执行备份命令
        echo "开始备份"
        mysqldump -u$username -p$password \
        --single-transaction \
        --master-data=1 \
        --triggers --events --routines \
        -B $dbnames | pv | gzip -c > $dbnames\_backup_$today.tgz
        echo "备份完成"
    ;;
    T)
        mysql -u$username -p$password -e "show Databases"
        echo -n "Please Input The Database Where You Want To Backup The Tables:"
        read dbname
        mysql -u$username -p$password -e "use $dbname;show tables;"
        echo -n "Please Choice The Name Of The Tables You Want To Backup,Separated By Space:"
        read tablenames
        # 执行备份命令
        echo "开始备份"
        mysqldump -u$username -p$password \
        --single-transaction \
        --master-data=1 \
        --triggers --events --routines \
        $dbname $tablenames | pv | gzip -c > $dbname\_$tablenames\_backup_$today.tgz
        echo "备份完成"
    ;;
esac
