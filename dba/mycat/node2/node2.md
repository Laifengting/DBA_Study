```bash
1. MyCAT基础架构准备
1.1 环境准备：
两台虚拟机 db01 db02
每台创建四个mysql实例：3307 3308 3309 3310

1.2 删除历史环境：
pkill mysqld
\rm -rf /data/330* 
\mv /etc/my.cnf /etc/my.cnf.bak


1.3 创建相关目录初始化数据
mkdir /mdata/33{07..10}/data -p
mysqld --initialize-insecure  --user=mysql --datadir=/mdata/3307/data --basedir=/usr/local/mysql
mysqld --initialize-insecure  --user=mysql --datadir=/mdata/3308/data --basedir=/usr/local/mysql
mysqld --initialize-insecure  --user=mysql --datadir=/mdata/3309/data --basedir=/usr/local/mysql
mysqld --initialize-insecure  --user=mysql --datadir=/mdata/3310/data --basedir=/usr/local/mysql


1.4 准备DB02配置文件和启动脚本
cat >/mdata/3307/my.cnf<<EOF
[mysqld]
basedir=/usr/local/mysql
datadir=/mdata/3307/data
socket=/mdata/3307/mysql.sock
port=3307
log-error=/mdata/3307/mysql-error.log
log_bin=/mdata/3307/mysql-bin
binlog_format=row
skip-name-resolve
server-id=17
gtid-mode=on
enforce-gtid-consistency=true
log-slave-updates=1
EOF

cat >/mdata/3308/my.cnf<<EOF
[mysqld]
basedir=/usr/local/mysql
datadir=/mdata/3308/data
port=3308
socket=/mdata/3308/mysql.sock
log-error=/mdata/3308/mysql-error.log
log_bin=/mdata/3308/mysql-bin
binlog_format=row
skip-name-resolve
server-id=18
gtid-mode=on
enforce-gtid-consistency=true
log-slave-updates=1
EOF

cat >/mdata/3309/my.cnf<<EOF
[mysqld]
basedir=/usr/local/mysql
datadir=/mdata/3309/data
socket=/mdata/3309/mysql.sock
port=3309
log-error=/mdata/3309/mysql-error.log
log_bin=/mdata/3309/mysql-bin
binlog_format=row
skip-name-resolve
server-id=19
gtid-mode=on
enforce-gtid-consistency=true
log-slave-updates=1
EOF


cat >/mdata/3310/my.cnf<<EOF
[mysqld]
basedir=/usr/local/mysql
datadir=/mdata/3310/data
socket=/mdata/3310/mysql.sock
port=3310
log-error=/mdata/3310/mysql-error.log
log_bin=/mdata/3310/mysql-bin
binlog_format=row
skip-name-resolve
server-id=20
gtid-mode=on
enforce-gtid-consistency=true
log-slave-updates=1
EOF

cat >/etc/systemd/system/mysqld3307.service<<EOF
[Unit]
Description=MySQL Server
Documentation=man:mysqld(8)
Documentation=http://dev.mysql.com/doc/refman/en/using-systemd.html
After=network.target
After=syslog.target
[Install]
WantedBy=multi-user.target
[Service]
User=mysql
Group=mysql
ExecStart=/usr/local/mysql/bin/mysqld --defaults-file=/mdata/3307/my.cnf
LimitNOFILE = 5000
EOF

cat >/etc/systemd/system/mysqld3308.service<<EOF
[Unit]
Description=MySQL Server
Documentation=man:mysqld(8)
Documentation=http://dev.mysql.com/doc/refman/en/using-systemd.html
After=network.target
After=syslog.target
[Install]
WantedBy=multi-user.target
[Service]
User=mysql
Group=mysql
ExecStart=/usr/local/mysql/bin/mysqld --defaults-file=/mdata/3308/my.cnf
LimitNOFILE = 5000
EOF

cat >/etc/systemd/system/mysqld3309.service<<EOF
[Unit]
Description=MySQL Server
Documentation=man:mysqld(8)
Documentation=http://dev.mysql.com/doc/refman/en/using-systemd.html
After=network.target
After=syslog.target
[Install]
WantedBy=multi-user.target
[Service]
User=mysql
Group=mysql
ExecStart=/usr/local/mysql/bin/mysqld --defaults-file=/mdata/3309/my.cnf
LimitNOFILE = 5000
EOF
cat >/etc/systemd/system/mysqld3310.service<<EOF
[Unit]
Description=MySQL Server
Documentation=man:mysqld(8)
Documentation=http://dev.mysql.com/doc/refman/en/using-systemd.html
After=network.target
After=syslog.target
[Install]
WantedBy=multi-user.target
[Service]
User=mysql
Group=mysql
ExecStart=/usr/local/mysql/bin/mysqld --defaults-file=/mdata/3310/my.cnf
LimitNOFILE = 5000
EOF



1.5  修改权限，启动多实例
chown -R mysql.mysql /mdata/*
systemctl start mysqld3307
systemctl start mysqld3308
systemctl start mysqld3309
systemctl start mysqld3310

mysql -S /mdata/3307/mysql.sock -e "show variables like 'server_id'"
mysql -S /mdata/3308/mysql.sock -e "show variables like 'server_id'"
mysql -S /mdata/3309/mysql.sock -e "show variables like 'server_id'"
mysql -S /mdata/3310/mysql.sock -e "show variables like 'server_id'"


1.6 节点主从规划
箭头指向谁是主库
    10.0.0.51:3307    <----->  10.0.0.52:3307
    10.0.0.51:3309    ------>  10.0.0.51:3307
    10.0.0.52:3309    ------>  10.0.0.52:3307
	
	

    10.0.0.52:3308  <----->    10.0.0.51:3308
    10.0.0.52:3310  ----->     10.0.0.52:3308
    10.0.0.51:3310  ----->     10.0.0.51:3308
	
1.7 分片规划
shard1：
    Master：10.0.0.51:3307
    slave1：10.0.0.51:3309
    Standby Master：10.0.0.52:3307
    slave2：10.0.0.52:3309
shard2：
    Master：10.0.0.52:3308
    slave1：10.0.0.52:3310
    Standby Master：10.0.0.51:3308
    slave2：10.0.0.51:3310
	
1.8 开始配置


#第一组四节点结构

# 10.0.0.51:3307 <-----> 10.0.0.52:3307

## db02:
mysql  -S /mdata/3307/mysql.sock -e "grant replication slave on *.* to repl@'10.0.0.%' identified by '123';"
mysql  -S /mdata/3307/mysql.sock -e "grant all  on *.* to root@'10.0.0.%' identified by '123'  with grant option;"

## db01:
mysql  -S /mdata/3307/mysql.sock -e "CHANGE MASTER TO MASTER_HOST='10.0.0.52', MASTER_PORT=3307, MASTER_AUTO_POSITION=1, MASTER_USER='repl', MASTER_PASSWORD='123';"
mysql  -S /mdata/3307/mysql.sock -e "start slave;"
mysql  -S /mdata/3307/mysql.sock -e "show slave status\G"

## db02:
mysql  -S /mdata/3307/mysql.sock -e "CHANGE MASTER TO MASTER_HOST='10.0.0.51', MASTER_PORT=3307, MASTER_AUTO_POSITION=1, MASTER_USER='repl', MASTER_PASSWORD='123';"
mysql  -S /mdata/3307/mysql.sock -e "start slave;"
mysql  -S /mdata/3307/mysql.sock -e "show slave status\G"

=======================

# 10.0.0.51:3309 ------> 10.0.0.51:3307
## db01:
mysql  -S /mdata/3309/mysql.sock  -e "CHANGE MASTER TO MASTER_HOST='10.0.0.51', MASTER_PORT=3307, MASTER_AUTO_POSITION=1, MASTER_USER='repl', MASTER_PASSWORD='123';"
mysql  -S /mdata/3309/mysql.sock  -e "start slave;"
mysql  -S /mdata/3309/mysql.sock  -e "show slave status\G"

# 10.0.0.52:3309 ------> 10.0.0.52:3307
## db02:
mysql  -S /mdata/3309/mysql.sock -e "CHANGE MASTER TO MASTER_HOST='10.0.0.52', MASTER_PORT=3307, MASTER_AUTO_POSITION=1, MASTER_USER='repl', MASTER_PASSWORD='123';"
mysql  -S /mdata/3309/mysql.sock -e "start slave;"
mysql  -S /mdata/3309/mysql.sock -e "show slave status\G"


#第二组四节点
#10.0.0.52:3308 <-----> 10.0.0.51:3308
## db01:
mysql  -S /mdata/3308/mysql.sock -e "grant replication slave on *.* to repl@'10.0.0.%' identified by '123';"
mysql  -S /mdata/3308/mysql.sock -e "grant all  on *.* to root@'10.0.0.%' identified by '123'  with grant option;"

## db02:
mysql  -S /mdata/3308/mysql.sock -e "CHANGE MASTER TO MASTER_HOST='10.0.0.51', MASTER_PORT=3308, MASTER_AUTO_POSITION=1, MASTER_USER='repl', MASTER_PASSWORD='123';"
mysql  -S /mdata/3308/mysql.sock -e "start slave;"
mysql  -S /mdata/3308/mysql.sock -e "show slave status\G"

## db01:
mysql  -S /mdata/3308/mysql.sock -e "CHANGE MASTER TO MASTER_HOST='10.0.0.52', MASTER_PORT=3308, MASTER_AUTO_POSITION=1, MASTER_USER='repl', MASTER_PASSWORD='123';"
mysql  -S /mdata/3308/mysql.sock -e "start slave;"
mysql  -S /mdata/3308/mysql.sock -e "show slave status\G"


# 10.0.0.52:3310 -----> 10.0.0.52:3308

## db02:
mysql  -S /mdata/3310/mysql.sock -e "CHANGE MASTER TO MASTER_HOST='10.0.0.52', MASTER_PORT=3308, MASTER_AUTO_POSITION=1, MASTER_USER='repl', MASTER_PASSWORD='123';"
mysql  -S /mdata/3310/mysql.sock -e "start slave;"
mysql  -S /mdata/3310/mysql.sock -e "show slave status\G"

# 10.0.0.51:3310 -----> 10.0.0.51:3308
## db01:
mysql  -S /mdata/3310/mysql.sock -e "CHANGE MASTER TO MASTER_HOST='10.0.0.51', MASTER_PORT=3308, MASTER_AUTO_POSITION=1, MASTER_USER='repl', MASTER_PASSWORD='123';"
mysql  -S /mdata/3310/mysql.sock -e "start slave;"
mysql  -S /mdata/3310/mysql.sock -e "show slave status\G"


1.9  检测主从状态
mysql -S /mdata/3307/mysql.sock -e "show slave status\G"|grep Yes
mysql -S /mdata/3308/mysql.sock -e "show slave status\G"|grep Yes
mysql -S /mdata/3309/mysql.sock -e "show slave status\G"|grep Yes
mysql -S /mdata/3310/mysql.sock -e "show slave status\G"|grep Yes

==================================================================
注：如果中间出现错误，在每个节点进行执行以下命令,从第1.9步重新开始即可
mysql -S /mdata/3307/mysql.sock -e "stop slave; reset slave all;"
mysql -S /mdata/3308/mysql.sock -e "stop slave; reset slave all;"
mysql -S /mdata/3309/mysql.sock -e "stop slave; reset slave all;"
mysql -S /mdata/3310/mysql.sock -e "stop slave; reset slave all;"
==================================================================



2. MyCAT安装
2.1 预先安装Java运行环境
yum install -y java
2.2下载
Mycat-server-xxxxx.linux.tar.gz
http://dl.mycat.io/
2.3 解压文件
[root@db01 application]# tar xf Mycat-server-1.6.7.1-release-20190627191042-linux.tar.gz 
2.4 软件目录结构
ls
bin  catlet  conf  lib  logs  version.txt
2.5 启动和连接
配置环境变量
vim /etc/profile
export PATH=/application/mycat/bin:$PATH
source /etc/profile
启动
mycat start
连接mycat：
mysql -uroot -p123456 -h 127.0.0.1 -P8066


3. 数据库分布式架构方式
3.1 垂直拆分
3.2 水平拆分
	range
	取模
	枚举
	hash
	时间
	等等

4. Mycat基础应用
4.1 主要配置文件介绍
rule.xml	*****,分片策略定义
schema.xml  *****,主配置文件
server.xml	***  ,mycat服务有关
log4j2.xml  ***  ,记录日志有关
*.txt			 ,分片策略使用的规则  


4.2  用户创建及数据库导入
db01:
mysql -S /data/3307/mysql.sock 
grant all on *.* to root@'10.0.0.%' identified by '123';
source /root/world.sql

mysql -S /data/3308/mysql.sock 
grant all on *.* to root@'10.0.0.%' identified by '123';
source /root/world.sql


4.3 配置文件结构介绍
cd /application/mycat/conf
mv schema.xml schema.xml.bak
vim schema.xml 

<?xml version="1.0"?>
<!DOCTYPE mycat:schema SYSTEM "schema.dtd">  
<mycat:schema xmlns:mycat="http://io.mycat/">

mycat 逻辑库定义:
<schema name="TESTDB" checkSQLschema="false" sqlMaxLimit="100" dataNode="sh1">  
</schema> 
==================================================
数据节点定义:
	<dataNode name="sh1" dataHost="oldguo1" database= "world" />   
==================================================	
后端主机定义:
        <dataHost name="oldguo1" maxCon="1000" minCon="10" balance="1"  writeType="0" dbType="mysql"  dbDriver="native" switchType="1">    
                <heartbeat>select user()</heartbeat>  
        <writeHost host="db1" url="10.0.0.51:3307" user="root" password="123">
                        <readHost host="db2" url="10.0.0.51:3309" user="root" password="123" /> 
        </writeHost> 
        </dataHost>  
===================================================	
			
</mycat:schema>
                   
4.4 mycat实现1主1从读写分离
vim schema.xml 
<!DOCTYPE mycat:schema SYSTEM "schema.dtd">  
<mycat:schema xmlns:mycat="http://io.mycat/">
<schema name="TESTDB" checkSQLschema="false" sqlMaxLimit="100" dataNode="sh1"> 
</schema>  
        <dataNode name="sh1" dataHost="oldguo1" database= "world" />         
        <dataHost name="oldguo1" maxCon="1000" minCon="10" balance="1"  writeType="0" dbType="mysql"  dbDriver="native" switchType="1">    
                <heartbeat>select user()</heartbeat>  
        <writeHost host="db1" url="10.0.0.51:3307" user="root" password="123">
                        <readHost host="db2" url="10.0.0.51:3309" user="root" password="123" /> 
        </writeHost> 
        </dataHost>  
</mycat:schema>
                          
4.5 Mycat高可用+读写分离
mv schema.xml schema.xml.1
vim schema.xml 
<!DOCTYPE mycat:schema SYSTEM "schema.dtd">  
<mycat:schema xmlns:mycat="http://io.mycat/">
<schema name="TESTDB" checkSQLschema="false" sqlMaxLimit="100" dataNode="sh1"> 
</schema>  
        <dataNode name="sh1" dataHost="oldguo1" database= "world" />         
        <dataHost name="oldguo1" maxCon="1000" minCon="10" balance="1"  writeType="0" dbType="mysql"  dbDriver="native" switchType="1">    
                <heartbeat>select user()</heartbeat>  
        <writeHost host="db1" url="10.0.0.51:3307" user="root" password="123">
                        <readHost host="db2" url="10.0.0.51:3309" user="root" password="123" /> 
        </writeHost> 
		 <writeHost host="db3" url="10.0.0.52:3307" user="root" password="123">
                        <readHost host="db4" url="10.0.0.52:3309" user="root" password="123" /> 
        </writeHost> 
        </dataHost>  
</mycat:schema>

说明:    
 <writeHost host="db1" url="10.0.0.51:3307" user="root" password="123">
            <readHost host="db2" url="10.0.0.51:3309" user="root" password="123" /> 
</writeHost> 
<writeHost host="db3" url="10.0.0.52:3307" user="root" password="123">
            <readHost host="db4" url="10.0.0.52:3309" user="root" password="123" /> 
 </writeHost> 

第一个 whost: 10.0.0.51:3307   真正的写节点,负责写操作
第二个 whost: 10.0.0.52:3307   准备写节点,负责读,当 10.0.0.51:3307宕掉,会切换为真正的写节点

测试:
[root@db01 conf]# mysql -uroot -p123456 -h 10.0.0.51 -P 8066

读:
mysql> select @@server_id;
写:
mysql> begin ;select @@server_id; commit;

4.6 配置中的属性介绍:

balance属性
负载均衡类型，目前的取值有3种： 
1. balance="0", 不开启读写分离机制，所有读操作都发送到当前可用的writeHost上。 
2. balance="1"，全部的readHost与standby writeHost参与select语句的负载均衡，简单的说，
  当双主双从模式(M1->S1，M2->S2，并且M1与 M2互为主备)，正常情况下，M2,S1,S2都参与select语句的负载均衡。 
3. balance="2"，所有读操作都随机的在writeHost、readhost上分发。

writeType属性
负载均衡类型，目前的取值有2种： 
1. writeType="0", 所有写操作发送到配置的第一个writeHost，
第一个挂了切到还生存的第二个writeHost，重新启动后已切换后的为主，切换记录在配置文件中:dnindex.properties . 
2. writeType=“1”，所有写操作都随机的发送到配置的writeHost，但不推荐使用


switchType属性
-1 表示不自动切换 
1 默认值，自动切换 
2 基于MySQL主从同步的状态决定是否切换 ，心跳语句为 show slave status 
datahost其他配置

<dataHost name="localhost1" maxCon="1000" minCon="10" balance="1"  writeType="0" dbType="mysql"  dbDriver="native" switchType="1"> 

maxCon="1000"：最大的并发连接数
minCon="10" ：mycat在启动之后，会在后端节点上自动开启的连接线程

tempReadHostAvailable="1"
这个一主一从时（1个writehost，1个readhost时），可以开启这个参数，如果2个writehost，2个readhost时
<heartbeat>select user()</heartbeat>  监测心跳

5. Mycat高级应用-分布式解决方案
5.1 垂直分表
mv  schema.xml  schema.xml.ha 
vim schema.xml
<?xml version="1.0"?>
<!DOCTYPE mycat:schema SYSTEM "schema.dtd">
<mycat:schema xmlns:mycat="http://io.mycat/">
<schema name="TESTDB" checkSQLschema="false" sqlMaxLimit="100" dataNode="sh1">
        <table name="user" dataNode="sh1"/>
        <table name="order_t" dataNode="sh2"/>
</schema>
    <dataNode name="sh1" dataHost="oldguo1" database= "taobao" />
    <dataNode name="sh2" dataHost="oldguo2" database= "taobao" />
    <dataHost name="oldguo1" maxCon="1000" minCon="10" balance="1"  writeType="0" dbType="mysql"  dbDriver="native" switchType="1">
        <heartbeat>select user()</heartbeat>
    <writeHost host="db1" url="10.0.0.51:3307" user="root" password="123">
            <readHost host="db2" url="10.0.0.51:3309" user="root" password="123" />
    </writeHost>
    <writeHost host="db3" url="10.0.0.52:3307" user="root" password="123">
            <readHost host="db4" url="10.0.0.52:3309" user="root" password="123" />
    </writeHost>
    </dataHost>
	
    <dataHost name="oldguo2" maxCon="1000" minCon="10" balance="1"  writeType="0" dbType="mysql"  dbDriver="native" switchType="1">
        <heartbeat>select user()</heartbeat>
    <writeHost host="db1" url="10.0.0.51:3308" user="root" password="123">
            <readHost host="db2" url="10.0.0.51:3310" user="root" password="123" />
    </writeHost>
    <writeHost host="db3" url="10.0.0.52:3308" user="root" password="123">
            <readHost host="db4" url="10.0.0.52:3310" user="root" password="123" />
    </writeHost>
    </dataHost>	
</mycat:schema>

创建测试库和表:
[root@db01 conf]# mysql -S /data/3307/mysql.sock -e "create database taobao charset utf8;"
[root@db01 conf]# mysql -S /data/3308/mysql.sock -e "create database taobao charset utf8;"
[root@db01 conf]# mysql -S /data/3307/mysql.sock -e "use taobao;create table user(id int,name varchar(20))";
[root@db01 conf]# mysql -S /data/3308/mysql.sock -e "use taobao;create table order_t(id int,name varchar(20))"


重启mycat :
mycat restart 

测试功能:
[root@db01 conf]# mysql -uroot -p123456 -h 10.0.0.51 -P 8066
mysql> use TESTDB
mysql> insert into user(id ,name ) values(1,'a'),(2,'b');
mysql> commit;

mysql> insert into order_t(id ,name ) values(1,'a'),(2,'b');
mysql> commit;

[root@db01 ~]# mysql -S /data/3307/mysql.sock -e "show tables from taobao;"
+------------------+
| Tables_in_taobao |
+------------------+
| user             |
+------------------+
[root@db01 ~]# mysql -S /data/3308/mysql.sock -e "show tables from taobao;"
+------------------+
| Tables_in_taobao |
+------------------+
| order_t          |
+------------------+
[root@db01 ~]# 

5.2 Mycat分布式-水平拆分(分片)介绍
分片：对一个"bigtable"，比如说t3表
(1)行数非常多，800w
(2)访问非常频繁

分片的目的：
（1）将大数据量进行分布存储
（2）提供均衡的访问路由

分片策略：
范围 range  800w  1-400w 400w01-800w
取模 mod    取余数
枚举 
哈希 hash 
时间 流水

优化关联查询
全局表
ER分片

5.3 Mycat分布式-范围分片
比如说t3表
(1)行数非常多，2000w（1-1000w:sh1   1000w01-2000w:sh2）
(2)访问非常频繁，用户访问较离散
cp  schema.xml schema.xml.11  
vim schema.xml
<schema name="TESTDB" checkSQLschema="false" sqlMaxLimit="100" dataNode="sh1"> 
        <table name="t3" dataNode="sh1,sh2" rule="auto-sharding-long" />
</schema>  
    <dataNode name="sh1" dataHost="oldguo1" database= "taobao" /> 
    <dataNode name="sh2" dataHost="oldguo2" database= "taobao" />  

vim rule.xml
<tableRule name="auto-sharding-long">
                <rule>
                        <columns>id</columns>
                        <algorithm>rang-long</algorithm>
                </rule>             
<function name="rang-long"
    class="io.mycat.route.function.AutoPartitionByLong">
    <property name="mapFile">autopartition-long.txt</property>
</function>
===================================         
vim autopartition-long.txt
1-10=0   -----> >=1 , <=10
10-20=1  -----> >10 ,<=20

创建测试表：
mysql -S /data/3307/mysql.sock -e "use taobao;create table t3 (id int not null primary key auto_increment,name varchar(20) not null);"

mysql -S /data/3308/mysql.sock  -e "use taobao;create table t3 (id int not null primary key auto_increment,name varchar(20) not null);"

测试：
重启mycat
mycat restart

mysql -uroot -p123456 -h 127.0.0.1 -P 8066
insert into t3(id,name) values(1,'a');
insert into t3(id,name) values(2,'b');
insert into t3(id,name) values(3,'c');
insert into t3(id,name) values(10,'d');
insert into t3(id,name) values(11,'aa');
insert into t3(id,name) values(12,'bb');
insert into t3(id,name) values(13,'cc');
insert into t3(id,name) values(14,'dd');
insert into t3(id,name) values(20,'dd');


5.4 取模分片（mod-long）：
取余分片方式：分片键（一个列）与节点数量进行取余，得到余数，将数据写入对应节点
vim schema.xml

<table name="t4" dataNode="sh1,sh2" rule="mod-long" />


vim rule.xml
<property name="count">2</property>

准备测试环境
创建测试表：
mysql -S /data/3307/mysql.sock -e "use taobao;create table t4 (id int not null primary key auto_increment,name varchar(20) not null);"
mysql -S /data/3308/mysql.sock -e "use taobao;create table t4 (id int not null primary key auto_increment,name varchar(20) not null);"

重启mycat 
mycat restart 

测试： 
mysql -uroot -p123456 -h10.0.0.51 -P8066

use TESTDB
insert into t4(id,name) values(1,'a');
insert into t4(id,name) values(2,'b');
insert into t4(id,name) values(3,'c');
insert into t4(id,name) values(4,'d');

分别登录后端节点查询数据
mysql -S /data/3307/mysql.sock -e "select * from taobao.t4;"
mysql -S /data/3308/mysql.sock -e "select * from taobao.t4;"

14. 枚举分片
t5 表
id name telnum
1   bj   1212
2   sh   22222
3   bj   3333
4   sh   44444
5   bj   5555

sharding-by-intfile

vim schema.xml
<table name="t5" dataNode="sh1,sh2" rule="sharding-by-intfile" />

vim rule.xml
<tableRule name="sharding-by-intfile"> 
<rule> <columns>name</columns> 
<algorithm>hash-int</algorithm> 
</rule> 
</tableRule> 

<function name="hash-int" class="org.opencloudb.route.function.PartitionByFileMap"> 
<property name="mapFile">partition-hash-int.txt</property> 
  <property name="type">1</property>
                <property name="defaultNode">0</property>
</function> 

partition-hash-int.txt 配置： 
bj=0 
sh=1
DEFAULT_NODE=1 

columns 标识将要分片的表字段，algorithm 分片函数， 其中分片函数配置中，mapFile标识配置文件名称

准备测试环境

mysql -S /data/3307/mysql.sock -e "use taobao;create table t5 (id int not null primary key auto_increment,name varchar(20) not null);"

mysql -S /data/3308/mysql.sock -e "use taobao;create table t5 (id int not null primary key auto_increment,name varchar(20) not null);"
重启mycat 
mycat restart 
mysql -uroot -p123456 -h10.0.0.51 -P8066
use TESTDB
insert into t5(id,name) values(1,'bj');
insert into t5(id,name) values(2,'sh');
insert into t5(id,name) values(3,'bj');
insert into t5(id,name) values(4,'sh');
insert into t5(id,name) values(5,'tj');
分别登录后端节点查询数据
mysql -S /data/3307/mysql.sock -e "select * from taobao.t5;"
mysql -S /data/3308/mysql.sock -e "select * from taobao.t5;"


======================================
<tableRule name="crc32slot">
<tableRule name="sharding-by-month">
DBLE自己研究
======================================
```
