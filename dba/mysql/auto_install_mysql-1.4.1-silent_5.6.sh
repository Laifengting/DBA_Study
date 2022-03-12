#!/bin/bash
############################
# File Name: auto_install_mysql-1.4.1-silent.sh
# Author: Laifengting
# mail: Laifengting@foxmail.com
# Created Time: 2022-03-02 07:49:09
# Version: 1.4.1
############################


##### 定义安装软件源目录变量【需要自己修改】
#echo -n 'Input The Directory Of The Installation Package(Default: /opt/mysql): '
#read src_binary_dir
#$src_binary_dir > /dev/null && src_binary_dir=/opt/mysql
src_binary_dir=/opt/mysql
echo The Directory Of The Installation Package: $src_binary_dir

##### 定义安装目录变量【需要自己修改】
#echo -n 'Input The Directory Of Installing (Default: /usr/local): '
#read install_dir
#$install_dir > /dev/null && install_dir=/usr/local
install_dir=/usr/local
echo The Directory Of Installing: $install_dir

##### 定义数据目录变量【需要自己修改】
#echo -n 'Input The Directory Of Stored Data (Default: /mdata/mysql): '
#read my_data_dir
#$my_data_dir > /dev/null && my_data_dir=/mdata/mysql
my_data_dir=/mdata/mysql
echo The Directory Of Data: $my_data_dir

# 命令行提示输入安装的版本
#echo -n 'Choose The Version Of MySQL(eg: 5.6 / 5.7 / 8.0 , Default: 5.7 ): '
## 读取输入的安装版本变量
#read version
#$version > /dev/null && version=5.7
version=5.6
echo The Version Of MySQL: $version

## 命令行提示输入要修改的密码
#echo -n 'Please input your Password(Not less than 8 numeric, lowercase/uppercase, and special characters): '
## 读取输入的自定义密码
#read password
password=Lft123456~
## 备份密码
#echo ${password} >/tmp/my_diy_pass.txt
## 提示备份路径
#echo '=============================>  You can find your password from /tmp/my_diy_pass.txt <============================='
echo The Default Password: $password

# 校验是否安装 libaio 依赖库
rpm -q libaio >/dev/null || yum install libaio -y >/dev/null 2>&1
# 校验 mysql 组是否存在
if id -g mysql >/dev/null 2>&1; then
    # 如果存在，提示已经存在 mysql 组
    echo 'Group "mysql" Already Exists'
else
    # 否则新建 mysql 组，并提示 mysql 组创建成功
    groupadd mysql >/dev/null 2>&1 && echo 'Group "mysql" Created Successfully'
fi

# 校验 mysql 用户是否存在
if id -u mysql >/dev/null 2>&1; then
    # 如果存在，提示已经存在用户 myssql
    echo 'User "mysql" Already Exists'
else
    # 否则新建 mysql 用户，并提示 mysql 用户创建成功
    useradd -r -g mysql -s /sbin/nologin mysql >/dev/null 2>&1 && echo 'User "mysql" Created Successfully'
fi


# 判断是否存在该目录，如果不存在就创建。
[ -d src_binary_dir ] || mkdir -p $src_binary_dir
[ -d my_data_dir ] || mkdir -p $my_data_dir
cd ${my_data_dir}
mkdir -p $my_data_dir/data $my_data_dir/logs/binlog $my_data_dir/logs/relay
# 将数据目录授权为 mysql 用户组
chown -R mysql:mysql .

# 进入到源文件目录
cd ${src_binary_dir}

# 下载对应版本
case $version in
# 如果安装的是 8.0 版本
8.0)
    if [ ! -f mysql-${version}*.tar* ]; then
        echo "Downloading The Installation Package..."
        # 下载 8.0
        curl -s -O https://mirrors.huaweicloud.com/mysql/Downloads/MySQL-8.0/mysql-8.0.28-linux-glibc2.12-x86_64.tar.xz
    else
        echo "The Installation Package Already Exists!"
    fi
    ;;
# 如果安装的是 5.7 版本
5.7)
    if [ ! -f mysql-${version}*.tar* ]; then
        echo "Downloading The Installation Package..."
        # 下载 5.7
        curl -s -O https://mirrors.huaweicloud.com/mysql/Downloads/MySQL-5.7/mysql-5.7.37-linux-glibc2.12-x86_64.tar.gz
    else
        echo "The Installation Package Already Exists!"
    fi
    ;;
# 如果安装的是 5.6 版本
5.6)
    if [ ! -f mysql-${version}*.tar* ]; then
        echo "Downloading The Installation Package..."
        # 下载 5.6
        curl -s -O https://mirrors.huaweicloud.com/mysql/Downloads/MySQL-5.6/mysql-5.6.51-linux-glibc2.12-x86_64.tar.gz
    else
        echo "The Installation Package Already Exists!"
    fi
    ;;
esac

# 显示正在解压
echo 'Extracting The Installation Package...'

# 获取安装版本的全文件名
str1=$(ls -t mysql-${version}*.tar* | head -n 1)

# 解压软件到安装目录
tar xf ${str1} -C ${install_dir}
echo 'Unzip The Installation Package Completed!'
echo 'Installing'

# 安装，先 cd 到安装目录
cd ${install_dir}

# 获取安装版本的目录名
str2=$(ls -dt mysql-${version}* | head -n 1)

# 删除原先的软链接(如果有)
unlink mysql

# 创建软链接
ln -s ${str2} mysql

# 将命令目录放到环境变量中
echo 'export PATH=/usr/local/mysql/bin:$PATH' >/etc/profile.d/mysql.sh

# 刷新一下环境变量
source /etc/profile.d/mysql.sh

# 创建配置文件
cat >/etc/my.cnf <<EOF
# 导入其他配置文件
#!include /home/mydir/myopt.cnf


[client]
#### ============================ client 配置区 ============================= ####
# 用于其他命令使用例如：mysqldump mysqlpump xtrabackup mysqlsalp 等等
user=root
password=Lft123456~
host=localhost
port=3306
socket=/tmp/mysql.sock


[mysql]
#### ============================= mysql 配置区 ============================= ####
## 以下六个必须放在第一个参数位置。
# 打印程序参数列表并退出。
# print-defaults

# 不要从任何选项文件中读取默认选项，登录文件除外。
# no-defaults

# 只从给定的文件 # 中读取默认选项。
# defaults-file=#

# 读取全局文件后读取此文件。
# defaults-extra-file=#

# 还可以使用 concat(group, suffix) 读取组
# defaults-group-suffix=#

# 从登录文件中读取此路径。
# login-path=
# 以上六个必须放在第一个参数位置。


# 预读库表信息,自动填写库，表，字段，默认 TRUE
auto_rehash
# auto_rehash=TRUE

# 相当于在命令行中使用 -A
# no_auto_rehash
# auto_rehash=FALSE
# skip_auto_rehas
# disable_auto_rehash


# 当输出长度很长时，自动垂直输出，默认 FALSE
# auto-vertical-output

# 不要使用历史文件。 禁用交互行为。（启用 --silent。）相当于命令行中使用 -B
# batch

# 绑定 IP 地址，无默认
# bind_address=127.0.0.1 192.168.0.112 47.100.192.243

# 将二进制数据打印为十六进制。 默认情况下为交互式终端启用。默认 FALSE
# binary-as-hex

# 字符集目录，无默认
# character-sets-dir=$install_dir/mysql/

# 显示字段类型信息，默认 FALSE
# column-type-info

# 发送注释到服务器，默认 FALSE。相当于命令行中使用 -c
# comments
# skip-comments

# 压缩客户端服务器协议，默认 FALSE。相当于命令行中使用 -C
# compress

# 这是一个非调试版本。 抓住这个并退出。
# debug[=#]

# 在退出时检查内存和打开文件的使用情况。
# debug-check

# 在退出时打印一些调试信息。相当于命令行中使用 -T
# debug-info

# 默认使用的数据库，无默认。相当于命令行中使用 mysql [-D] db_naem
database=mysql

#### 字符集相关参数
# SHOW VARIABLES WHERE variable_name LIKE 'char%' OR variable_name LIKE 'collation%';
# character_set_client       客户端来源数据使用的字符集，也就是客户端发过来的查询语句使用的字符集
# character_set_connection   MySQL 接收到用户查询后，按照 character_set_client 将其转换为 character_set_connection 设定的字符集
# character_set_database     当前数据库的默认字符集
# character_set_filesystem   文件系统使用的字符集(默认二进制)
# character_set_results      查询结果以什么编码的字符集返回给用户
# character_set_server       默认的内部操作字符集
# character_set_system       系统元数据（表名，字段名，密码，用户名，注释等）使用的字符集
# character_sets_dir         字符集文件的目录
# collation_connection       执行字符比较时连接采用的编码规则
# collation_database         执行字符比较时数据库采用的编码规则
# collation_server           执行字符比较时服务器采用的编码规则
# SET NAMES 'utf8mb4' 相当于
# SET character_set_client = utf8mb4;
# SET character_set_results = utf8mb4;
# SET character_set_connection = utf8mb4;
# SET CHARACTER SET 'utf8mb4' 相当于
# SET character_set_client = utf8mb4;
# SET character_set_results = utf8mb4;
# SET collation_connection = @@collation_database;
# 如果在[mysql]和[client]节中都设置了默认字符集，那么以[client]为准

# 在该区域设置默认字符集（default-character-set=utf8mb4），
# 那么这个三个character_set_client,character_set_connection,character_set_results，全部生效
# 默认 auto
default_character_set=utf8mb4

# 使用的分隔符，默认";"
# delimiter=;

# 允许使用清除文本验证的插件，默认 FALSE
# enable-cleartext-plugin

# 执行命令并退出。相当于命令行中使用 -e
# execute="ALTER USER 'root'@'localhost' IDENTIFIED BY 'Lft123456~';"

# 垂直打印查询输出的行，默认 FALSE。相当于命令行中使用 -E
# vertical

# 即使有 SQL 错误也继续执行，默认 FALSE。相当于命令行中使用 -f
# force

# 以冒号分隔的模式列表，以防止语句被记录到 syslog 和 mysql 历史记录中，无默认
# histignore=INSERT:DELETE:UPDATE

# 启用后，命名命令可以在查询的任何行中使用，否则只能在输入之前的第一行中使用。默认 FALSE。相当于命令行中使用 -G
# named-commands
# disable-named-commands

# 忽略函数名后的空格。默认 FALSE。相当于命令行中使用 -i
# ignore-spaces

# 连接到 MySQL 服务器时要执行的 SQL 命令。 重新连接时会自动重新执行。无默认
# init-command="SHOW DATABASES;"

# 启用/禁用加载数据本地文件。默认 FALSE
# local-infile

# 关闭错误提示音。默认 FALSE。相当于命令行中使用 -b
# no-beep

# 连接到主机。无默认。即在命令行的 mysql -u root -h 192.168.247.180 -P 3306 -p
# host=192.168.247.180

# 生成 HTML 输出。默认 FALSE。相当于命令行中使用 -H
# html

# 生成 XML 输出。默认 FALSE。相当于命令行中使用 -X
# xml

# 写下错误的行号。默认 TRUE
line-numbers

# 不写下错误的行号。相当于命令行中使用 -L
# skip-line-numbers

# 每次查询后刷新缓冲区。默认 FALSE。相当于命令行中使用 -n
# unbuffered

# 在结果中写入列名。默认 TRUE
# column-names
# 不显示行号。相当于在命令行中使用 -N
# skip-column-names

# 忽略信号 (CTRL-C)。默认 FALSE
# sigint-ignore

# 忽略除默认数据库是在命令行中命名的数据库时出现的语句之外的语句。相当于在命令行中使用 -o
# one-database

# 用于显示结果的寻呼机。有效的寻呼机是 less、more、cat [> filename] 等。另请参阅交互式帮助 (\h)。
# pager= less

# 连接到服务器时使用的密码。 如果没有给出密码，它会从 tty 中询问。相当于命令行中使用 -p
password=Lft123456~

# 用于连接的端口号或 0 默认为，按优先顺序，my.cnf, $MYSQL_TCP_PORT。默认 0。相当于命令行中使用 -P
port=3306

# 将 mysql 提示设置为此值。默认 mysql>
# prompt = (\\u@\\h) [\\d]>\\_
# prompt = [\\Y/\\o \\R:\\m:\\s \\w] [\\u@\\h] [\\d]>\\_
prompt = [\\D | \\h:\\p.\\u] [\\d]>\\_

# 用于连接的协议（tcp、socket、pipe、memory）。
# protocol=tcp

# 不要缓存结果，逐行打印。 如果输出被挂起，这可能会减慢服务器的速度。 不使用历史文件。默认 FALSE。相当于命令行中使用 -q
# quick

# 无需转换即可写入字段。 与 --batch 一起使用。默认 FALSE。相当于命令行中使用 -r
# raw

# 如果连接丢失，重新连接。默认 TRUE
# reconnect
# disable-reconnect
# skip-reconnect

# 更沉默。 使用制表符作为分隔符打印结果，每行在新行上。相当于命令行中使用 -s
# silent

# 用于连接的套接字文件。无默认。相当于命令行中使用 -S ,mysql -S /tmp/mysql.sock -u root -p
socket=/tmp/mysql.sock

# PEM 格式的服务器公共 RSA 密钥的文件路径。无默认
# server-public-key-path=name

# SSL 连接方式。
# ssl-mode=name

# PEM 格式的 CA 文件（检查 OpenSSL 文档，暗示 --ssl）。
# ssl-ca=name

# CA 目录（检查 OpenSSL 文档，暗示 --ssl）。
# ssl-capath=name

# PEM 格式的 X509 证书（暗示 --ssl）。
# ssl-cert=name

# 要使用的 SSL 密码（暗示 --ssl）。
# ssl-cipher=name

# PEM 格式的 X509 密钥（暗示 --ssl）。
# ssl-key=name

# 证书吊销列表（暗示 --ssl）。
# ssl-crl=name

# 证书吊销列表路径（暗示 --ssl）。
# ssl-crlpath=name

# 以表格格式输出。相当于命令行中使用 -t
# table

# 将所有内容附加到 outfile 中。 另请参阅交互式帮助 (\h)。 在批处理模式下不起作用。 使用 --disable-tee 禁用。 默认情况下禁用此选项。
# tee=name
# disable-tee

# 如果不是当前用户，则用于登录的用户。相当于命令行中使用 -u
user=root

# 选项 --safe-updates, -U 的同义词。相当于命令行中使用 -U
# i-am-a-dummy

# 多写点。 （-v -v -v 给出表格输出格式）。相当于命令行中使用 -v
# verbose

# 输出版本信息并退出。相当于命令行中使用 -V
# version

# 如果连接断开，请等待并重试。相当于命令行中使用 -w
# wait

# 连接超时前的秒数。
connect-timeout=10

# 发送到服务器或从服务器接收的最大数据包长度。
max-allowed-packet=16M

# TCP/IP 和套接字通信的缓冲区大小。
# net-buffer-length=#

# 只允许使用键的 UPDATE 和 DELETE。相当于命令行中使用 -U
# safe-updates

# 使用 --safe-updates 时自动限制 SELECT。
# select-limit=#

# 使用 --safe-updates 时自动限制连接中的行。
# max-join-size=#

# 在每条语句后显示警告。
show-warnings

# 客户端插件的目录。
# plugin-dir=name

# 要使用的默认身份验证客户端插件。
# default-auth=name

# 默认情况下，不允许使用 ASCII '\0' 并且 '\r\n' 被转换为 '\n'。 此开关关闭这两个功能，并在非交互模式下关闭对除 \C 和 DELIMITER 之外的所有客户端命令的解析（对于通过管道传输到 mysql 或使用“源”命令加载的输入）。 在处理可能包含 blob 的 mysqlbinlog 输出时，这是必要的。
# binary-mode

# 通知服务器此客户端已准备好处理过期密码沙箱模式。
# connect-expired-password



[mysql5.6]
# 为连接启用 SSL（使用其他标志自动启用）。
# ssl
# skip-ssl

# 根据连接时使用的主机名验证其证书中服务器的“通用名称”。默认情况下禁用此选项。
# ssl-verify-server-cert

# 如果客户端使用旧的（4.1.1 之前的）协议，则拒绝客户端连接到服务器。（默认为开启；使用 --skip-secure-auth 禁用。）
# secure-auth
# skip-secure-auth

# 将此作为参数发送嵌入式服务器。
# server-arg=name


[mysql5.7]
# 为连接启用 SSL（使用其他标志自动启用）。已弃用。 改用 --ssl-mode.
# ssl
# skip-ssl

# 获取服务器公钥。默认 FALSE
# get-server-public-key

# 根据连接时使用的主机名验证其证书中服务器的“通用名称”。 默认情况下禁用此选项。已弃用。 改用 --ssl-mode=VERIFY_IDENTITY 。
# ssl-verify-server-cert

# 要使用的 TLS 版本，允许的值为：TLSv1、TLSv1.1、TLSv1.2
# tls-version=name

# 如果客户端使用旧的（4.1.1 之前的）协议，则拒绝客户端连接到服务器。（默认为开启；使用 --skip-secure-auth 禁用）。已弃用。 永远为 TRUE
# secure-auth
# skip-secure-auth

# 将此作为参数发送嵌入式服务器。
# server-arg=name

# 将过滤后的交互式命令记录到 syslog。 除了默认模式之外，命令的过滤取决于通过 histignore 选项提供的模式。相当于命令行中使用 -j
# syslog


[mysql8.0]
# 连接到 DNS SRV 资源。无默认
# dns-srv-name

# 获取服务器公钥。默认 FALSE
# get-server-public-key

# SSL FIPS 模式（仅适用于 OpenSSL）； 允许的值为：OFF、ON、STRICT
# ssl-fips-mode=name

# 要使用的 TLS 版本，允许的值为：TLSv1、TLSv1.1、TLSv1.2、TLSv1.3
# tls-version=name

# 要使用的 TLS v1.3 密码。
# tls-ciphersuites=name

# 将过滤后的交互式命令记录到 syslog。 除了默认模式之外，命令的过滤取决于通过 histignore 选项提供的模式。相当于命令行中使用 -j
# syslog

# 在服务器/客户端协议中使用压缩算法。有效值是“zstd”、“zlib”、“uncompressed”的任意组合。
# compression-algorithms=name

# 在客户端/服务器协议中使用此压缩级别，以防 --compression-algorithms=zstd。 有效范围在 1 到 22 之间，包括 1 和 22。 默认值为 3。
# zstd-compression-level=#

# LOAD DATA LOCAL INFILE 可安全读取的目录路径。
# load-data-local-dir=name



[mysqld_safe]
# 当 open_files_limit 没有被配置时，比较 max_connections*5 和 ulimit -n 的值，取最大值
# 当 open_file_limit 被配置时，比较 open_files_limit 和 max_connections*5 的值，取最大值
# open_files_limit=8192


#### ============================= mysqld 配置区 ============================= ####
[mysqld]
port=3306
user=mysql
# 数据目录
datadir=$my_data_dir/data

# 跳过客户端和数据库的编码字符集握手，可以全客户端和数据库的编码保持一致。
character_set_client_handshake=FALSE

# 设置服务器和数据库默认字符集
# 在该区域设置默认字符集（character_set_server=utf8mb4），
# 那么character_set_server，character_set_database两个全部生效，并且这俩个参数只有在该节中可以设置，其他地方设置会报错
character_set_server=utf8mb4

# 用于修改密码
# skip_grant_tables

# 绑定 IP 地址
# bind_address=127.0.0.1 192.168.0.112 47.100.192.243

# 设置默认时区
default_time_zone='+8:00'


####=========================== 连接配置 ===========================####

# 线程处理技术，是每个链接使用一个线程(one-thread-per-connection) 或者使用线程池(pool-of-threads) one-thread-per-connection, no-threads, loaded-dynamically
# thread_handling=pool-of-threads
# thread_handling=one-thread-per-connection


# MySQL 客户端和服务器之间的本地通信指定的允许最大套接字文件的大小，防止服务器发送过大的数据包。
max_allowed_packet=512M

# 最大连接数，当前服务器允许多少并发连接。默认为 100，一般设置为小于 1000 即可。太高会导致内存占用过多，MySQL 服务器会卡死。作为参考，小型站设置 100 - 300
max_connections=1024

max_connect_errors = 1000

# 禁止域名解析，所有的主机名是 ip 或者 localhost
skip-name-resolve


####=========================== 自增配置 ===========================####
# 自增初始值
# auto_increment_offset = 1

# 自增间隔
# auto_increment_increment = 2

####=========================== 表配置 ===========================####
lower_case_table_names=1


####=========================== 插件配置 ===========================####
# 密码校验插件
# plugin_load_add=validate_password.so # 配置在不同版本配置区


####=========================== 日志配置 ===========================####
#### 错误日志
# 日志名称（位置于数据目录中）
log_error=$my_data_dir/logs/mysql-error.log
# log_warnings 为0， 表示不记录告警信息。
# log_warnings 为1， 表示告警信息写入错误日志。
# log_warnings 大于1， 表示各类告警信息，例如有关网络故障的信息和重新连接信息写入错误日志。
# log_warnings=2

#### 慢查询日志
# 开启慢查询日志
slow_query_log=1
# 慢查询日志文件名
slow_query_log_file=$my_data_dir/logs/mysql-slow.log
# 慢查询阈值 5 秒,大于5秒的记录到慢查询日志。
long_query_time=5
# 扫描少于 100 行的 SQL 不记录到慢查询日志。
min_examined_row_limit=100
# 无论是否超时，将没有使用索引的 SQL 记录到慢查询日志。
log_queries_not_using_indexes
# 限制每分钟记录没有使用索引 SQL 语句的次数。
log_throttle_queries_not_using_indexes=10
# 记录管理操作，如 ALTER/ANALYZE TABLE
log_slow_admin_statements
# 记录从服务器上的慢查询
# log_slow_slave_statements # 配置在不同版本配置区

#### 通用日志（全局日志）
# 开启通用日志
general_log=1
# 通用日志保存文件名
general_log_file=$my_data_dir/logs/mysql-general.log

#### relay 中继日志
relay_log = $my_data_dir/logs/relay/mysql-relay-bin.log
relay_log_info_file = $my_data_dir/logs/relay/mysql-relay-log.info
#关闭自动清理relay日志，默认为开启，mha环境中需要配置此参数
relay_log_purge=OFF

#### 二进制日志
# 开启二进制日志,如果没有指定日志名称，默认使用 主机名-bin。
# log_bin
log_bin=$my_data_dir/logs/binlog/mysql-bin

# binlog 格式
# binlog_format = row # 配置在主从复制中

# 不强制限制存储函数创建,这个变量也适用于触发器创建
log_bin_trust_function_creators=1

# 控制二进制日志缓存大小，增加其值可改善处理大事务的系统的性能。在具有大量数据库连接的环境中应限制该值。
binlog_cache_size=2M

# 如果二进制日志处于活动状态，则此变量确定在每次事务中保存二进制日志更改记录的缓存的每个连接的字节大小。单独的变量binlog_stmt_cache_size设置了语句缓存的上限。
# 该binlog_cache_disk_use 和 binlog_cache_use 服务器状态变量将显示这个变量是否需要增加。
# binlog_stmt_cache_size=1M

# 如果二进制日志在写入后超出此大小，则服务器会通过关闭它并打开新的二进制日志来旋转它。
# 单个事务将始终存储在同一二进制日志中，因此服务器将等待未完成的事务在轮换之前完成。
# 如果将 max_relay_log_size 设置为 0，此项也适用于中继日志的大小。
# max_binlog_size=128M

# 控制 binlog 写磁盘频率 5.7.7 开始默认就是1
# 0 表示不同步到磁盘，1 表示每个事务提交之前同步到磁盘。N 表示在收集到N个二进制日志的提交组之后同步到磁盘。
# sync_binlog=1 # 【重要】配置在主从复制配置中

# 自动二进制日志文件删除的天数。默认值为 0，table 表示“不自动删除”。在启动时和清除二进制日志时，可能会删除它们。
expire_logs_days=7

# 此变量设置二进制日志记录格式，并且可以是 STATEMENT，ROW 或 MIXED 三选一
# binlog_format=ROW # 【重要】配置在主从复制配置中

# 对于 MySQL 基于行的复制，此变量确定如何将行图像写入二进制日志。
# binlog_row_image=MINIMAL

# binlog 日志记录执行的 SQL 语句
binlog_rows_query_log_events=ON



####=========================== 经典主从复制(异步复制)配置 ===========================####
#### 主库配置
# binlog 日志的记录格式
binlog_format=ROW # 【重要】在日志配置中有详细说明
# 事务隔离级别
# transaction_isolation=READ-COMMITTED # 配置在事务中
# 每台服务器的唯一ID
server_id=103306

## 必须设置为1，5.7.7之前默认为0
# 【重要】 同步 binlog 日志
sync_binlog=1 # 【重要】在日志配置中有详细说明

# 刷新日志到磁盘的频率 默认 1
# innodb_flush_log_at_trx_commit=1 # Innodb 配置块中有详细描述
# 支持 XA 两段提交 默认开启
# innodb_support_xa=1

# 主从复制的时候，IO 线程是接收一个一个的 EVENT
# 将接收到的 EVENT 写在表中还是文件中。默认为 FILE，设置为 TABLE 能提高一些性能。
# 【重要】
master_info_repository=TABLE # 配置在不同版本配置区


#### 从库配置
# skip_slave_start=0

# 如果设置为 0 （默认值），则复制期间从主服务器接收到的从服务器上的更新不会记录在从服务器的二进制日志中。
# 如果设置为 1 ，则为。需要启用从库的二进制日志才能生效。这样从库上同步的数据会记录到二进制日志中。
# 【重要】
# log_slave_updates=1 # 配置在不同版本配置区
# server_id=103308

## 中继日志
# relay_log=mysql-relay-bin # 开启中继日志 在上面日志配置中有

## IO 线程 crash safe
# 【重要】
relay_log_recovery=1

# 是否自动清除中继日志。
# relay_log_purge=OFF # MHA 中，从库必须关斗

## SQL 线程 crash safe
# 【重要】主从复制的时候，将接收到的 EVENT 应用成一个一个的事务。存放在表中，可以解决 CRASH SAFE 防止主从不一致。
# relay_log_info_repository=TABLE # 配置在不同版本配置区

## 从库设置为只读
# read_only=1
## 从库 root 用户也只读(5.7新增)从库设置为只读可以避免数据不一致。
# 【重要】
# super_read_only=1

####=========================== 并行复制配置 ===========================####
## 从库的并行复制
# 默认是按数据库，一个数据库一个线程来并行复制。5.7之前只有database,5.7加入了逻辑时钟 logical_clock。
# 因为是基于组提交的复制，一个组提交中，不会存在竞争锁。不会有冲突。是一组的就提交到一个线程中执行，提高了并行度。
# slave_parallel_type=logical_clock # 配置在不同版本配置区

# 并行复制的工作线程默认0
# slave_parallel_workers=16 # 配置在不同版本配置区

####=========================== 延迟复制配置 ===========================####
## 延迟3600秒(1小时)复制
# CHANGE MASTER TO MASTER_DELAY = 3600;

####=========================== 半同步复制配置 ===========================####
#### 半同步复制配置
### 半同步插件安装
## mysql
# plugin_dir=/usr/local/mysql/lib/plugin

## percona
# plugin_dir=/usr/local/mysql/lib/mysql/plugin/

# plugin_load="rpl_semi_sync_master:semisync_master.so;rpl_semi_sync_slave:semisync_slave.so"
# plugin_load_add="semisync_master.so;semisync_slave.so" # 配置在不同版本配置区

### 半同步插件配置
# rpl_semi_sync_master_enabled=ON # 配置在不同版本配置区
# rpl_semi_sync_slave_enabled=ON # 配置在不同版本配置区
# 从机无法接收日志时，半同步转成异步的超时时间。
# rpl_semi_sync_master_timeout=5000 # 配置在不同版本配置区

# 半同步复制时的等待点，一个是在写日志之后（AFTER_SYNC）。一个是在提交日志之后(AFTER_COMMIT)。
# rpl_semi_sync_master_wait_point=AFTER_SYNC # MySQL 5.7 # 配置在不同版本配置区

# 当有多少从机接收到日志之后才提交日志数据。
# rpl_semi_sync_master_wait_for_slave_count=1 # MySQL 5.7 # 配置在不同版本配置区


## Non-GTID 经典复制  配置
# relay_log_recovery=1
# sync_relay_log=1
# relay_log_info_repository=TABLE
# master_info_repository=TALBE

####=========================== 过滤复制配置 ===========================####
## 白名单
# 主库配置
# binlog-do-db=test
# binlog-do-table=test.t1
# binlog-wild-do-table=test.t*

# 从库配置
# replicate-do-db=test1  # "库级别"
# replicate-do-db=test2  # "库级别"
# replicate-do-db=test1,test2  # "库级别"
# replicate-do-table=test.t1  # "表级别"
# replicate-wild-do-table=test.t*   # "匹配方式的表级别"

## 黑名单
# 主库配置
# binlog-ignore-db=test     # 配置库
# binlog-ignore-table=test.t1       # 配置表
# binlog-wild-ignore-table=test.t*   # 配置表（支持正则）

# 从库配置
# replicate-ignore-db=test   # 配置库
# replicate-ignore-table=test.t1    # 配置表
# replicate-wild-ignore-table=test.t*   # 配置表（支持正则）


####=========================== 基于 GTID 的主从复制配置 ===========================####
## GTID 复制 配置
# 1. 主库开启二进制日志,如果没有指定日志名称，默认使用 主机名-bin。
# log_bin
# log_bin=/mdata/mysql/logs/binlog/mysql-bin
# 2. 开启 GTID
gtid_mode=ON
# log_slave_updates=ON # 上面有配置
enforce_gtid_consistency=ON
# 可以关闭中继日志。
# relay_log_recovery=0
## CHANGE MASTER TO MASTER_HOST=host,MASTER_PORT=port,MASTER_USER=user,MASTER_PASSWORD=password,MASTER_AUTO_POSITION=1; START SLAVE;
# MASTER_AUTO_POSITION=ON


####=========================== 存储引擎开关 ===========================####
#### 开启/关闭 存储引擎
# federated
skip_federated
skip_archive
skip_blackhole

#### 默认存储引擎
default_storage_engine=InnoDB


####=========================== 缓存配置 ===========================####
# 线程缓存，用于缓存空闲的线程。这个数表示可重新使用保存在缓存中的线程数，当对方断开连接时，如果缓存还有空间，那么客户端的线程就会被放到缓存中，以便提高系统性能。
# 我们可根据物理内存来对这个值进行设置，对应规则 1G 为 8；2G 为 16；3G 为 32；4G 为 64 等。
# thread_cache_size=64

# 查询缓存类型
# 设置为 0 时，则禁用查询缓存（尽管仍分配query_cache_size个字节的缓冲区）。
# 设置为 1 时，除非指定SQL_NO_CACHE，否则所有SELECT查询都将被缓存。
# 设置为 2 时，则仅缓存带有SQL CACHE子句的查询。
# 请注意，如果在禁用查询缓存的情况下启动服务器，则无法在运行时启用服务器。
# query_cache_type=1

# 缓存select语句和结果集大小的参数。
# 查询缓存会存储一个select查询的文本与被传送到客户端的相应结果。
# 如果之后接收到一个相同的查询，服务器会从查询缓存中检索结果，而不是再次分析和执行这个同样的查询。
# 如果你的环境中写操作很少，读操作频繁，那么打开query_cache_type=1，会对性能有明显提升。如果写操作频繁，则应该关闭它（query_cache_type=0）。
# query_cache_size=64M

# 修改每个会话默认排序缓冲区的大小,MySQL 执行排序时，使用的缓存大小。增大这个缓存，提高 group by，order by 的执行速度。
sort_buffer_size=32M

# 修改每个会话默认临时表的大小,HEAP 临时数据表的最大长度，超过这个长度的临时数据表 MySQL 可根据需求自动将基于内存的 HEAP 临时表改为基于硬盘的 MyISAM 表。我们可通过调整 tmp_table_size 的参数达到提高连接查询速度的效果。
tmp_table_size=64M

# MySQL 读入缓存的大小。如果对表对顺序请求比较频繁对话，可通过增加该变量值以提高性能。
read_buffer_size=512K

# 用于表的随机读取，读取时每个线程分配的缓存区大小。默认为 256k ，一般在 128 - 256k之间。在做 order by 排序操作时，会用到 read_rnd_buffer_size 空间来暂做缓冲空间。
# read_rnd_buffer_size=256K

# 程序中经常会出现一些两表或多表 Join （联表查询）的操作。为了减少参与 Join 连表的读取次数以提高性能，需要用到 Join Buffer 来协助 Join 完成操作。当 Join Buffer 太小时，MySQL 不会将它写入磁盘文件。和 sort_buffer_size 一样，此参数的内存分配也是每个连接独享。
join_buffer_size=512K

# 限制不使用文件描述符存储在缓存中的表定义的数量。
table_definition_cache=2048

# 限制为所有线程在内存中打开的表数量。
table_open_cache=1000

# 事件（定时任务）
event_scheduler=1

####=========================== 事务配置 ===========================####
# 设置事务隔离级别
# 读未提交-有脏读，不可重复读，幻读问题。
# transaction_isolation=READ-UNCOMMITTED
# 读已提交-有不可重复读，幻读问题。
transaction_isolation=READ-COMMITTED
# 可重复读-基本解决了脏读，不可重复读，幻读问题。
# transaction_isolation=REPEATABLE-READ
# 串行化-完全解决了脏读，不可重复读，幻读问题。
# transaction_isolation=SERIALIZABLE


####=========================== InnoDB 存储引擎配置 ===========================####
# 设置 Innodb 在线修改表时日志最大大小。
innodb_online_alter_log_max_size=128G

# 此为独立表空间模式，每个数据库的每个表都会生成一个数据空间。
# 当删除或截断一个数据库表时，你也可以回收未使用的空间。
# 这样配置的另一个好处是你可以将某些数据库表放在一个单独的存储设备。这可以大大提升你磁盘的I/O负载。
# 独立表空间优点：每个表都有自已独立的表空间。每个表的数据和索引都会存在自已的表空间中。
# 可以实现单表在不同的数据库中移动。 空间可以回收（除drop table操作处，表空不能自已回收）
# 缺点：单表增加过大，如超过100G
# 结论：共享表空间在Insert操作上少有优势。其它都没独立表空间表现好。
# 当启用独立表空间时，请合理调整：innodb_open_files
innodb_file_per_table=1


#### InnoDB Buffer Pool 相关
# InnoDB 存储引擎缓冲池大小,控制缓存表和索引数据,越大越好，建议是内存的60%~70%，官方文档推荐是60%~80%，但是太大了的话，容易出现OOM.
innodb_buffer_pool_size=128M

# Innodb使用后台线程处理数据页上的读写 I/O(输入输出)请求,根据你的 CPU 核数来更改,默认是4，上面设置的缓冲池的大小，将会平均分成这个参数的个数。
# 注:这两个参数不支持动态改变,需要把该参数加入到my.cnf里，修改完后重启MySQL服务,允许值的范围从1-64
innodb_buffer_pool_instances=4

#### InnoDB 线程相关
# IO能力 写的线程数量
innodb_write_io_threads=32

# IO能力 读的线程数量
innodb_read_io_threads=32

# 设置 innodb_io_capacity时，InnoDB根据设置的值估计可用于后台任务的 I/O 带宽。
# 您可以将innodb_io_capacity设置为 100 或更大的值。默认值为200。
# 通常，通常设置为系统IO性能的一半，大约 100 的值适用于 Consumer 级别的存储设备，例如最高 7200 RPM 的硬盘驱动器。
innodb_io_capacity=500

# 数据不经过系统缓存直接存储到硬盘上。
innodb_flush_method=O_DIRECT

# InnoDB用来控制buffer pool刷脏页时是否把脏页邻近的其他脏页一起刷到磁盘，在传统的机械硬盘时代，打开这个参数能够减少磁盘寻道的开销，显著提升性能。
# 设置为0时，表示刷脏页时不刷其附近的脏页。
# 设置为1时，表示刷脏页时连带其附近毗连的脏页一起刷掉。
# 设置为2时，表示刷脏页时连带其附近区域的脏页一起刷掉。1与2的区别是2刷的区域更大一些。
# 5.7版本为1， 8.0版本为0
# 由于SSD设备的普及，MySQL 8.0 将该参数的默认值由1调整为0。
innodb_flush_neighbors=0

# 这个选项决定着什么时候把日志信息写入日志文件以及什么时候把这些文件物理地写(术语称为”同步”)到硬盘上。
# 当设为 0 ,log buffer每秒就会被刷写日志文件到磁盘，提交事务的时候不做任何操作（执行是由mysql的master thread线程来执行的。
# 当设为 1 时，每次提交事务的时候，都会将log buffer刷写到日志。
# 当设为 2 ,每次提交事务都会写日志，但并不会执行刷的操作。每秒定时会刷到日志文件。
# 要注意的是，并不能保证100%每秒一定都会刷到磁盘，这要取决于进程的调度。
# innodb_flush_log_at_trx_commit=1

# 此参数确定些日志文件所用的内存大小，以M为单位。缓冲区更大能提高性能，但意外的故障将会丢失数据。
# 事务日志所使用的缓存区。InnoDB在写事务日志的时候为了提高性能，
# 先将信息写入Innodb Log Buffer中，当满足innodb_flush_log_trx_commit参数所设置的相应条件（或者日志缓冲区写满）时，
# 再将日志写到文件（或者同步到磁盘）中。
# 可以通过innodb_log_buffer_size参数设置其可以使用的最大内存空间。默认是16MB，一般为16～64MB即可。
innodb_log_buffer_size=64M

# 事务日志文件写操作缓存区的最大长度。
# 更大的设置可以提高性能，但也会增加恢复故障数据库所需的时间 Galera specific MySQL parameter default_storage_engine = InnoDB
# 服务器启动时必须启用默认存储引擎，否则服务器将无法启动。
# 默认设置是 MyISAM。 这项设置还可以通过–default-table-type选项来设置。
innodb_log_file_size=1G

# 内存非一致存储访问，默认只访问本地节点内存，可以设置为 interleave 表示在所有人节点上交织分配内存。
innodb_numa_interleave=ON


####=================== lock 相关参数 ====================####
# 为InnoDB表生成 AUTO_INCREMENT 值时使用的锁定模式。 有效值为:
# 0 是传统锁定模式。 1 是连续锁定模式。 2 是交错锁定模式。
innodb_autoinc_lock_mode=2

# 一个InnoDB 事务在回滚之前等待锁超时时间，单位秒。数值大于 100000000 表示禁用超时
innodb_lock_wait_timeout=5

## innodb 引擎状态信息输出
# 允许输出 InnoDB 引擎状态信息到错误日志。
innodb_status_output=ON

# 允许输出更详细的锁信息到错误日志。
innodb_status_output_locks=ON

# 默认在 SHOW ENGINE innodb STATUS 只会显示最近的一次死锁。打开下面的开关，就可以显示所有死锁。
innodb_print_all_deadlocks=ON



####=========================== MyISAM 存储引擎配置 ===========================####
# MyISAM table 的索引块被缓冲并由所有线程共享。
# key_buffer_size 是用于索引块的缓冲区的大小。密钥缓冲区也称为密钥缓存。
key_buffer_size=64M

# 设置MyISAM存储引擎恢复模式。变量值是 OFF，DEFAULT，BACKUP，FORCE或QUICK的值的任意组合。
# 如果指定多个值，请用逗号分隔。在服务器启动时指定没有值的变量与指定DEFAULT相同，指定显式值""会禁用恢复(与OFF的值相同)。
# 如果启用了恢复，则每次 mysqld 打开 MyISAMtable 时，它都会检查该 table 是否标记为已崩溃或未正确关闭。
# (只有在禁用外部锁定的情况下运行，最后一个选项才起作用.)在这种情况下，mysqld在 table 上运行检查。如果 table 已损坏，mysqld尝试修复它。
# myisam_recover  = BACKUP,FORCE


####=========================== Memory 存储引擎配置 ===========================####
# 此变量设置允许用户创建的 MEMORY table 增长的最大大小。
# 变量的值用于计算MEMORYtableMAX_ROWS的值。除非使用诸如CREATE TABLE之类的语句重新创建该 table
# 或使用ALTER TABLE或TRUNCATE  TABLE对其进行更改，否则设置此变量对任何现有的MEMORYtable 均无效。
# 服务器重新启动还会将现有 MEMORY table 的最大大小设置为全局max_heap_table_size值。
max_heap_table_size=64M


####=========================== 安全配置 ===========================####
# 此变量控制LOAD DATA语句的服务器端LOCAL功能。根据local_infile设置，服务器会拒绝或允许 Client 端启用LOCAL的 Client 端加载本地数据。
#local_infile=0
#secure_auth  = 1
# 检查 Client 连接时是否解析主机名。如果此变量是 0 ，则 mysqld 在检查 Client 端连接时解析主机名。
# 如果是 1 ，则 mysqld 仅使用 IPNumbers；在这种情况下，授权 table 中的所有Host列值都必须是 IP 地址
#skip_name_resolve = 0

# 设置 MySQL 文件的导入和导出的路径。NULL：限制 mysqld 不允许导入导出；/path/：限制 mysqld 的导入导出只能发生在默认的 /path/目录中；''：不对 mysqld 的导入导出做限制。
secure_file_priv=''


####=========================== 不同版本的差异化配置 ===========================####
# 以下参数只有在 MySQL5.6 版本才会生效
[mysqld-5.6]
# 临时目录
# tmpdir=/mdata/tmp
# 设置所有版本 MySQL 的 SQL_MODE 为 5.7 版本 8.0版本不需要设置
sql_mode='STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION'

# 记录从服务器上的慢查询
log_slow_slave_statements # 日志配置

# 主从复制的时候，IO 线程是接收一个一个的 EVENT
# 将接收到的 EVENT 写在表中还是文件中。默认为 FILE，设置为 TABLE 能提高一些性能。
# 【重要】
master_info_repository=TABLE # 主从复制配置

#### 从库配置
# 如果设置为 0 （默认值），则复制期间从主服务器接收到的从服务器上的更新不会记录在从服务器的二进制日志中。
# 如果设置为 1 ，则为。需要启用从库的二进制日志才能生效。这样从库上同步的数据会记录到二进制日志中。
# 【重要】
log_slave_updates=1 # 配置在不同版本配置区

## SQL 线程 crash safe
# 主从复制的时候，将接收到的 EVENT 应用成一个一个的事务。存放在表中，可以解决 CRASH SAFE 防止主从不一致。
# 【重要】
relay_log_info_repository=TABLE # 主从复制配置


[mysqld-5.7]
# 写入时区信息包含年月日时分秒
log_timestamps=system
# 默认密码过期时间，0为永不过期
default_password_lifetime=0
# 密码校验插件
plugin_load_add=validate_password.so
# 设置所有版本 MySQL 的 SQL_MODE 为 5.7 版本 8.0版本不需要设置
sql_mode='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION'

# 记录从服务器上的慢查询
log_slow_slave_statements # 日志配置

# 刷新脏页使用的线程数量,默认跟 IO 写线程数量一致
innodb_page_cleaners=4

# 每次重启MySQL服务器的时候，下载热点数据的space pageno 记录的比例用于预热。
innodb_buffer_pool_dump_pct=40

# 主从复制的时候，IO 线程是接收一个一个的 EVENT
# 将接收到的 EVENT 写在表中还是文件中。默认为 FILE，设置为 TABLE 能提高一些性能。
# 【重要】
master_info_repository=TABLE # 主从复制配置

#### 从库配置
# 如果设置为 0 （默认值），则复制期间从主服务器接收到的从服务器上的更新不会记录在从服务器的二进制日志中。
# 如果设置为 1 ，则为。需要启用从库的二进制日志才能生效。这样从库上同步的数据会记录到二进制日志中。
# 【重要】
log_slave_updates=1 # 配置在不同版本配置区

## SQL 线程 crash safe
# 主从复制的时候，将接收到的 EVENT 应用成一个一个的事务。存放在表中，可以解决 CRASH SAFE 防止主从不一致。
# 【重要】
relay_log_info_repository=TABLE # 主从复制配置

## 从库的并行复制
# 默认是按数据库，一个数据库一个线程来并行复制。5.7之前只有database,5.7加入了逻辑时钟 logical_clock。
# 因为是基于组提交的复制，一个组提交中，不会存在竞争锁。不会有冲突。是一组的就提交到一个线程中执行，提高了并行度。
slave_parallel_type=logical_clock # 主从复制配置

# 并行复制的工作线程默认0
slave_parallel_workers=16 # 主从复制配置

plugin_load="semisync_master.so;semisync_slave.so" # 主从复制配置

### 半同步插件配置
rpl_semi_sync_master_enabled=ON # 主从复制配置
rpl_semi_sync_slave_enabled=ON # 主从复制配置
# 从机无法接收日志时，半同步转成异步的超时时间。
rpl_semi_sync_master_timeout=5000 # 主从复制配置

# 半同步复制时的等待点，一个是在写日志之后（AFTER_SYNC）。一个是在提交日志之后(AFTER_COMMIT)。
rpl_semi_sync_master_wait_point=AFTER_SYNC # MySQL 5.7 # 主从复制配置

# 当有多少从机接收到日志之后才提交日志数据。
rpl_semi_sync_master_wait_for_slave_count=1 # MySQL 5.7 # 主从复制配置


[mysqld-8.0]
# 默认密码过期时间，0为永不过期
default_password_lifetime=0
# 密码校验插件
plugin_load_add=validate_password.so

# 记录从服务器上的慢查询
log_slow_replica_statements # 日志配置

# 刷新脏页使用的线程数量,默认跟 IO 写线程数量一致
innodb_page_cleaners=4

# 每次重启MySQL服务器的时候，下载热点数据的space pageno 记录的比例用于预热。
innodb_buffer_pool_dump_pct=40

# SQL-MODE MySQL 8.0 不需要设置
sql_mode='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'

#### 从库配置
# 如果设置为 0 （默认值），则复制期间从主服务器接收到的从服务器上的更新不会记录在从服务器的二进制日志中。
# 如果设置为 1 ，则为。需要启用从库的二进制日志才能生效。这样从库上同步的数据会记录到二进制日志中。
# 【重要】
log_replica_updates=1 # 配置在不同版本配置区

## 从库的并行复制
# 默认是按数据库，一个数据库一个线程来并行复制。5.7之前只有database,5.7加入了逻辑时钟 logical_clock。
# 因为是基于组提交的复制，一个组提交中，不会存在竞争锁。不会有冲突。是一组的就提交到一个线程中执行，提高了并行度。
replica_parallel_type=logical_clock # 主从复制配置

# 并行复制的工作线程默认0
replica_parallel_workers=16 # 主从复制配置

plugin_load="semisync_source.so;semisync_replica.so" # 主从复制配置

### 半同步插件配置
# rpl_semi_sync_source_enabled=ON # 主从复制配置
# rpl_semi_sync_replica_enabled=ON # 主从复制配置
# 从机无法接收日志时，半同步转成异步的超时时间。
# rpl_semi_sync_source_timeout=5000 # 主从复制配置

# 半同步复制时的等待点，一个是在写日志之后（AFTER_SYNC）。一个是在提交日志之后(AFTER_COMMIT)。
# rpl_semi_sync_source_wait_point=AFTER_SYNC # MySQL 8.0 # 主从复制配置

# 当有多少从机接收到日志之后才提交日志数据。
# rpl_semi_sync_source_wait_for_replica_count=1 # MySQL 8.0 # 主从复制配置

####=========================== mysqlbinlog配置 ===========================####
## 输出的信息重新编码
# base64-output=decode-rows

## 跳过 gtid
# skip-gtids

####=========================== mysqldump配置 ===========================####
[mysqldump]
# 通过在一个事务中转储所有的表来创建一个一致的快照。
# 只对存储在支持多版本的存储引擎中的表起作用（目前只有InnoDB支持）；不保证转储对其他存储引擎是一致的。
# 当单事务转储正在进行时，为了确保转储文件的有效性（正确的表内容和二进制日志位置），
# 其他连接不应该使用以下语句。ALTER TABLE, DROP TABLE, RENAME TABLE, TRUNCATE TABLE, 因为一致的快照没有与它们隔离。
# 选项自动关闭了--锁定表。
single_transaction

# 这将导致二进制日志位置和文件名被附加到输出中。
# 如果等于1，将作为CHANGE MASTER命令打印；
# 如果等于2，该命令将以注释符号作为前缀。
# 这个选项将打开--lock-all-tables，除非也指定了--single-transaction
# （在不提供Binlog_snapshot_file和Binlog_snapshot_position状态变量的服务器上，
# 这仍然会在转储开始的短时间内占用一个全局读锁；
# 不要忘记阅读下面的--single-transaction）。
# 在所有情况下，对日志的任何操作都会在转储的确切时刻发生。选项会自动关闭--锁定表。
master-data=2

# 备份触发器
triggers=1

# 备份事件
events=1

# 备份存储过程，函数，视图等
routines=1

# 是否在备份文件中添加 GTID 信息
set-gtid-purged=AUTO

# 最大允许传输的包大小
max_allowed_packet=128M

# 压缩(影响性能变慢)
# compress=ON

####=========================== mysqlpump配置 ===========================####
[mysqlpump]
# 通过在一个事务中转储所有的表来创建一个一致的快照。
# 只对存储在支持多版本的存储引擎中的表起作用（目前只有InnoDB支持）；不保证转储对其他存储引擎是一致的。
# 当单事务转储正在进行时，为了确保转储文件的有效性（正确的表内容和二进制日志位置），
# 其他连接不应该使用以下语句。ALTER TABLE, DROP TABLE, RENAME TABLE, TRUNCATE TABLE, 因为一致的快照没有与它们隔离。
# 选项自动关闭了--锁定表。
single_transaction

# 备份触发器
triggers=1

# 备份事件
events=1

# 备份存储过程，函数，视图等
routines=1


####=========================== 多实例配置 ===========================####
# 多实例配置
[mysqld_multi]
mysqld=$install_dir/mysql/bin/mysqld_safe
mysqladmin=$install_dir/mysql/bin/mysqladmin
log=$install_dir/mysql/mysqld_multi.log
user=root
pass=Lft123456~


# 同版本实例1
[mysqld573307]
server_id=103307
port=3307
datadir=$my_data_dir/data573307
socket=/tmp/mysql.sock573307
# language=$install_dir/mysql/share/japanese

# 同版本实例2
[mysqld573308]
server_id=103308
port=3308
datadir=$my_data_dir/data573308
socket=/tmp/mysql.sock573308
# language=$install_dir/mysql/share/russian

# 不同版本实例1
# MySQL 5.6
[mysqld563309]
server_id=103309
port=3309
basedir=$install_dir/mysql56
datadir=$my_data_dir/data563309
socket=/tmp/mysql.sock563309
# language=$install_dir/mysql/share/french


# 不同版本实例2
# MySQL 8.0
[mysqld803310]
server_id=103310
port=3310
basedir=$install_dir/mysql80
datadir=$my_data_dir/data803310
socket=/tmp/mysql.sock803310
# language=$install_dir/mysql/share/french
EOF

echo 'The MySQL Is Installing...'

# 进入软链接后的 mysql 目录
cd ${install_dir}/mysql
# 将目录授权为 mysql 用户组
chown -R mysql:mysql .

case $version in
# 如果要安装的是 5.7 / 8.0 版本
8.0 | 5.7)
    # 初始化
    bin/mysqld --initialize --user=mysql >/dev/null 2>&1
    # 判断是否安装成功
    [ $? -eq 0 ] && echo 'Installing mysql-server Successfully'
    # 查询出初始密码
    grep 'temporary password' $my_data_dir/logs/mysql-error.log | awk -F'root@localhost: ' '{print $2}' >/tmp/default_pass.txt
    # echo 'Please Remember The Initial Password'
    # cat /tmp/my_pass.txt
    ;;

# 如果要安装的是 5.6 版本
5.6)
    # 删除掉时间戳配置(不适用于 5.5 5.6 版本)
    sed -i '/log_timestamps/d' /etc/my.cnf
    # 初始化
    scripts/mysql_install_db --user=mysql >/dev/null 2>&1
    # 判断是否安装成功l
    [ $? -eq 0 ] && echo 'Installing mysql-server success'
    ;;
esac
# 将 mysql 目录授权给 root 用户组，防止用户删减软件目录
chown -R root .
# 复制服务到启动目录
cp support-files/mysql.server /etc/init.d/mysql.server
chmod 755 /etc/init.d/mysql.server
# 设置为开机自动启动。

systemctl enable mysql.server >/dev/null 2>&1
echo 'The MySQL installation is complete'

# 启动服务
# systemctl start mysql.server
/etc/init.d/mysql.server start
# echo 'The MySQL server is Started'

case $version in
# 如果安装的是 5.7 / 8.0 版本
8.0 | 5.7)
    # 读取密码
    pw=$(cat /tmp/default_pass.txt)
    # 删除密码
    rm -rf /tmp/default_pass.txt
    # 修改密码
    mysql -uroot -p"${pw}" -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${password}'" --connect-expired-password
    # 自动进入 MySQL
    mysql -uroot -p"${password}"
    ;;

# 如果安装的是 5.6 版本
5.6)
    # 修改密码
    mysql -uroot -p -e "set password = 'password(${password})'" --connect-expired-password
    # 自动进入 MySQL
    mysql -uroot -p"${password}"
    ;;
esac
