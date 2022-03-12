#!/bin/bash
## 检查脚本配置文件要在两个系统中都存放
# 脚本文件 atlas_check.sh 配置
A=`ps -C mysql-proxy --no-header |wc -l`

# ps -C mysql-proxy --no-header |wc -l
# 这段脚本的意思是：在按命令名(-C) 查询进程输出不带标题(--no-header)的结果中 统计行数

if [ $A -eq 0 ];then
	/bin/bash /usr/local/mysql-proxy/bin/mysql-proxyd test start
	sleep 2
        if [ `ps -C mysql-proxy --no-header |wc -l` -eq 0 ];then
                # 关闭所有 keepalived
                systemctl stop keepalived

                # 提交当前主机的HOST 和 IP
                hostname > /usr/local/mysql-proxy/log/address.log
                ifconfig >> /usr/local/mysql-proxy/log/address.log
                ip a >> /usr/local/mysql-proxy/log/address.log

                # 发送邮件通知
                /usr/bin/sh /usr/local/mysql-proxy/send_email.sh

		# 停止监控
		p2=$(ps -ef | grep cront.sh | grep -v grep | awk '{print $2}')
		kill -9 $p2		
        fi
fi
