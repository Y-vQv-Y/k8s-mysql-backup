#!/bin/bash
# xtra_backup_remote.sh - 在 master 节点上执行备份，输出到本地文件
# 参数: $1=MySQL主机 $2=MySQL端口 $3=备份文件路径
# 不依赖 --defaults-file（TCP 备份无需本地 datadir），
# 不依赖节点间 SSH（由控制节点负责 scp 传输）

MYSQL_HOST=$1
MYSQL_PORT=$2
BACKUP_FILE=$3

if [[ -z "$MYSQL_HOST" || -z "$MYSQL_PORT" || -z "$BACKUP_FILE" ]]; then
    echo "用法: $0 <mysql_host> <mysql_port> <backup_file>"
    echo "示例: $0 100.233.112.154 3306 /opt/app/xtra_full_2026-05-01.xbstream"
    exit 1
fi

echo "******开始备份******"
echo "MySQL: $MYSQL_HOST:$MYSQL_PORT"
echo "输出:  $BACKUP_FILE"

# xtrabackup 8.0 即使做 TCP 远程备份也会查询 MySQL 服务端 @@datadir 并 cd 进去
# 容器内 datadir 为 /bitnami/mysql/data/，宿主机需创建该目录
mkdir -p /bitnami/mysql/data /tmp/xtrabackup_tmp

/xtrabackup/cmd/bin/xtrabackup \
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
  --target-dir=/tmp/xtrabackup_tmp \
  > $BACKUP_FILE

if [[ $? -eq 0 && -f "$BACKUP_FILE" ]]; then
    echo "BACKUP_FILE=$BACKUP_FILE"
    ls -lh $BACKUP_FILE
    echo "===========备份完成==========="
else
    echo "错误：备份失败"
    exit 1
fi
