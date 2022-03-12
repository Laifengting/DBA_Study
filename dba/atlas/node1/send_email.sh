#!/bin/bash
#smtp服务器地址
email_smtphost=smtp.qq.com
#发送者邮箱
email_sender=laifengting@foxmail.com
#接收者邮箱
email_reciver="396096473@qq.com 1060199462@qq.com"
#邮箱用户名
email_username=laifengting@foxmail.com
#邮箱密码
#使用qq邮箱进行发送需要注意：首先需要开启：POP3/SMTP服务，其次发送邮件的密码需要使用在开启POP3/SMTP服务时候腾讯提供的第三方客户端登陆码。
email_password=rybihxolkeuxbhjd

email_title="Atlas出现故障停止服务"
email_content="Atlas出现故障停止服,详情见附件"

file1_path="/usr/local/mysql-proxy/log/address.log"
file2_path="/usr/local/mysql-proxy/log/test.log"
file3_path="/var/log/messages"

# yum install -y sendemail
sendEmail -f ${email_sender} -t ${email_reciver} -s ${email_smtphost} -u ${email_title} -xu ${email_username} -xp ${email_password} -m ${email_content} -a ${file1_path} ${file2_path} ${file3_path} -o message-charset=utf-8
