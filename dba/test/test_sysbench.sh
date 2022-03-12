#!/bin/bash
############################
# File Name: auto_install_mysql.sh
# Author: Laifengting
# mail: 396096473@qq.com
# Created Time: Fri 03 Dec 2021 01:17:51 PM CST
############################

## 数据库准备工作
# create database sbtest;
# sysbench oltp_point_select --tables=4 --table_size=1000000 --mysql-host=127.0.0.1 --mysql-port=3306 --mysql-user=root --mysql-password=Lft123456~ --threads=4 --events=0 --time=20 --report-interval=3 prepare

## #### test_sysbench.sh thread_num time
today=$(date '+%Y-%m-%d_%H-%M-%S')
echo '创建数据文件目录'
mkdir -p /mdata/test_sysbench_$today

# 全局参数信息 varialbes.sh
echo '获取 MySQL 所有变量信息'
mysql -e "show variables" >/mdata/test_sysbench_$today/variables.log &

# io 信息 io.sh
echo '获取系统 IO 信息'
iostat -xm 1 >/mdata/test_sysbench_$today/io.log &

# CPU 信息 cpu.sh
echo '获取系统 CPU 信息'
sar -P ALL 1 >/mdata/test_sysbench_$today/cpu.log &

# 全局状态信息 status.sh
echo '获取 MySQL 状态增量信息'
mysqladmin extended-status -i 1 -r -uroot -pLt201314~ >/mdata/test_sysbench_$today/status.log &

# sysbench 压测信息 sysbench.sh
echo '获取查询压测信息'
sysbench oltp_point_select \
    --tables=4 \
    --table_size=1000000 \
    --mysql-host=127.0.0.1 \
    --mysql-port=3306 \
    --mysql-user=root \
    --mysql-password=Lft123456~ \
    --threads=$1 \
    --events=0 \
    --time=$2 \
    --report-interval=1 run >/mdata/test_sysbench_$today/sysbench.log &

echo '等待压测完成'
sleep $2
echo '关闭获取 CPU 信息进程'
p1=$(ps -ef | grep sar | grep -v grep | awk '{print $2}')
kill -9 $p1
echo '关闭获取 MySQL 状态信息进程'
p2=$(ps -ef | grep mysqladmin | grep -v grep | awk '{print $2}')
kill -9 $p2
echo '关闭获取系统 IO 信息进程'
p3=$(ps -ef | grep iostat | grep -v grep | awk '{print $2}')
kill -9 $p3
