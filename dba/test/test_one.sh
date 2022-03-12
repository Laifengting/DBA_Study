############################
# File Name: test_xa.sh
# Author: Laifengting
# mail: 396096473@qq.com
# Created Time: Fri 24 Dec 2021 02:38:07 PM CST
############################
#!/bin/bash

mysqlslap --query=local_lock.sql --number-of-queries=10000000000 -uroot -pLft123456~ &
