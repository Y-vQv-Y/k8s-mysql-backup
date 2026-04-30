#!/bin/bash
# xtra_backup_remote.sh - 在 master 节点上执行远程流式备份
# 参数: $1=MySQL主机地址(Service ClusterIP) $2=MySQL端口 $3=备份目标节点IP

MYSQL_HOST=$1
MYSQL_PORT=$2
TARGET_IP=$3

if [[ -z "$MYSQL_HOST" || -z "$MYSQL_PORT" || -z "$TARGET_IP" ]]; then
    echo "用法: $0 <mysql_host> <mysql_port> <target_ip>"
    echo "示例: $0 100.233.112.154 3306 10.203.15.83"
    exit 1
fi

echo "******开始备份******"
/xtrabackup/cmd/bin/xtrabackup \
  --defaults-file=/xtrabackup/my.cnf \
  --host=$MYSQL_HOST \
  --user=root \
  --password=Qrcode@2022 \
  --port=$MYSQL_PORT \
  --no-version-check \
  --parallel=16 \
  --compress-threads=16 \
  --backup \
  --compress \
  --stream=xbstream \
  --target-dir=/opt/app/databack \
  | ssh -o "StrictHostKeyChecking no" root@$TARGET_IP "cat - > /opt/app/xtra_full_$(date +%Y-%m-%d).xbstream"

echo "===========当前数据备份主机名为：$HOSTNAME=============="
echo "===========备份数据源地址：$MYSQL_HOST================="
echo "===========备份数据源端口：$MYSQL_PORT================="
echo "===========备份数据存储地址：$TARGET_IP=============="
echo "*****************************"
echo "**********备份完成***********"
echo "*****************************"
