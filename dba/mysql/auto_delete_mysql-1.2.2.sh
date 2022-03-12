#!/bin/bash
# 停止服务
# systemctl stop mysql.server
/etc/init.d/mysql.server stop
# echo 'The MySQL server is Stopped'

# 关闭开机自动启动。
systemctl disable mysql.server >/dev/null 2>&1
echo 'The MySQL server is Disabled'

# 移除在启动目录中的文件
rm -rf /etc/init.d/mysql.server
echo 'The MySQL server is Deleted'

# 删除配置文件
str1=$(date '+%Y%m%d%H%M%S')
mv /etc/my.cnf /etc/my.cnf.${str1}.bak
echo 'The MySQL Configuration is Deleted'

# 删除环境变量
rm -rf /etc/profile.d/mysql.sh

# 删除数据目录
mv /mdata/mysql /mdata/mysql.${str1}.bak
echo 'The MySQL Data is Deleted'

# 删除原先的软链接(如果有)
unlink /usr/local/mysql

# 删除用户
userdel -r mysql
groupdel mysql
echo 'The MySQL Remove is Finished'
