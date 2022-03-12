#!/bin/bash
# 分区
fdisk  /dev/sdc  <<EOF
n
p
1


wq
EOF

# 格式化
/sbin/mkfs.xfs /dev/sdc
# 创建数字文件夹
/bin/mkdir -p /mdata
# 挂载分区到目录
/bin/mount /dev/sdc /mdata
# 修改挂载信息
echo 'LABEL=data_disk /mdata ext4 defaults 0 2' >> /etc/fstab

