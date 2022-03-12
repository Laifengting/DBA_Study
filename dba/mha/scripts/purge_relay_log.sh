#!/bin/bash
#此脚本添加至定时任务，每天凌晨四点执行，定时任务示例如下：
# crontab -e # 编辑定时任务
# 0 4 * * * /bin/bash /usr/local/mha/scripts/purge_relay_log.sh
# crontab -l # 查看定时任务列表

user=mha
passwd=Lft123456~
port=3306
log_dir='/usr/local/mha/logs'
#relay日志的目录
work_dir='/mdata/mysql/logs/relay'
purge='/usr/bin/purge_relay_logs'
str1=$(date '+%Y-%m-%d_%H:%M:%S')

if [ ! -d $log_dir ]
then
   mkdir $log_dir -p
fi

$purge --user=$user --password=$passwd --disable_relay_log_purge --port=$port --workdir=$work_dir > ${log_dir}/purge_relay_logs_${str1}.log 2>&1
