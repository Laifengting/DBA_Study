#!/bin/bash
############################
# File Name: test_xa.sh
# Author: Laifengting
# mail: 396096473@qq.com
# Created Time: Fri 24 Dec 2021 02:38:07 PM CST
############################

mysqlslap --query=lock00.sql --number-of-queries=1000000000 -uroot -pLft123456~ &
mysqlslap --query=lock01.sql --number-of-queries=1000000000 -uroot -pLft123456~ &
mysqlslap --query=lock02.sql --number-of-queries=1000000000 -uroot -pLft123456~ &
mysqlslap --query=lock03.sql --number-of-queries=1000000000 -uroot -pLft123456~ &
mysqlslap --query=lock04.sql --number-of-queries=1000000000 -uroot -pLft123456~ &
mysqlslap --query=lock05.sql --number-of-queries=1000000000 -uroot -pLft123456~ &
mysqlslap --query=lock06.sql --number-of-queries=1000000000 -uroot -pLft123456~ &
mysqlslap --query=lock07.sql --number-of-queries=1000000000 -uroot -pLft123456~ &
