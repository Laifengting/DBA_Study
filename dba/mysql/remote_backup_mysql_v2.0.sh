#!/bin/bash
############################
# File Name: remote_backup_mysql.sh
# Author: Laifengting
# mail: 396096473@qq.com
# Created Time: Fri Dec 31 08:25:44 CST 2021
# Version: 2.1.9
############################

# 校验是否安装 gzip
rpm -q gzip >/dev/null || yum install gzip -y >/dev/null 2>&1

# 创建变量记录时间，用于创建文件名
today=$(date '+%Y-%m-%d_%H-%M-%S')

echo -n "Please Enter The Host Of The Mysql Server Witch You Want To Backup:"
read host

echo -n "Please Enter The Username Of The Mysql:"
read username

echo -n "Please Enter The Password Of The $username For The MySQL:"
read password

echo -n "Please Enter The Host Where You Want To Save The Backup File:"
read bakhost

echo "Backup All Databases (A)"
echo "Backup Parts Of Databases (D)"
echo "Backup Parts Of Tables (T)"
echo -n "Please Choice Witch Backup Mode You Want To Use(Just Enter A or D or T):"
read backupmode

case $backupmode in
    A)
        # 执行备份命令
        echo "开始备份"
        mysqldump -u$username -p$password -h$host \
        --single-transaction \
        --master-data=1 \
        --triggers --events --routines \
        -A | gzip -c | ssh root@$bakhost \
        'cat > /opt/all_databases_backup_$today.tgz'
        echo "备份完成"
    ;;
    D)
        mysql -u$username -p$password -h$host -e "show Databases"
        echo -n "Please Choice The Name Of The Databases You Want To Backup,Separated By Space:"
        read dbnames
        # 执行备份命令
        echo "开始备份"
        mysqldump -u$username -p$password -h$host \
        --single-transaction \
        --master-data=1 \
        --triggers --events --routines \
        -B $dbnames | gzip -c | ssh root@$bakhost \
        'cat > /opt/$dbnames\_backup_$today.tgz.tgz'
        echo "备份完成"
    ;;
    T)
        mysql -u$username -p$password -h$host -e "show Databases"
        echo -n "Please Input The Database Where You Want To Backup The Tables:"
        read dbname
        mysql -u$username -p$password -h$host -e "use $dbname;show tables;"
        echo -n "Please Choice The Name Of The Tables You Want To Backup,Separated By Space:"
        read tablenames
        # 执行备份命令
        echo "开始备份"
        mysqldump -u$username -p$password -h$host \
        --single-transaction \
        --master-data=1 \
        --triggers --events --routines \
        $dbname $tablenames  | gzip -c | ssh root@$bakhost \
        'cat > /opt/$dbname\_$tablenames\_backup_$today.tgz'
        echo "备份完成"
    ;;
esac
