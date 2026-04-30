#!/bin/bash
# xtra_restor.sh - 在节点上执行 XtraBackup 数据还原
# 参数: $1=namespace $2=statefulset $3=datadir $4=backup_file [$5=--yes]

NAMESPACE=$1
STS_NAME=$2
DATA_DIR=$3
BACKUP_FILE=$4

if [[ -z "$NAMESPACE" || -z "$STS_NAME" || -z "$DATA_DIR" || -z "$BACKUP_FILE" ]]; then
    echo "用法: $0 <namespace> <statefulset> <datadir> <backup_file> [--yes]"
    echo "示例: $0 test test-mysql-slave /opt/app/test-mysql/slave-0/data /opt/app/xtra_full_2026-04-30.xbstream --yes"
    exit 1
fi

if [[ "$5" == "--yes" ]]; then
    confirm="yes"
    echo "自动确认模式：跳过交互式确认"
else
    echo "请确认需要还原的数据库 $STS_NAME (namespace: $NAMESPACE) 是否处于停止运行状态？（yes or no）"
    echo "执行：kubectl scale sts $STS_NAME -n$NAMESPACE --replicas=0 停止数据库应用"
    echo "执行: watch -n 1 'kubectl get pod -A|grep mysql' 监听数据库状态"
    read confirm
fi

if [[ $confirm == "yes" ]];then
    echo "开始还原数据......"
    rm -rf /opt/app/databack
    rm -rf ${DATA_DIR}/*
    mkdir /opt/app/databack
    /xtrabackup/cmd/bin/xbstream -xv -C /opt/app/databack < $BACKUP_FILE &&
    /xtrabackup/cmd/bin/xtrabackup --decompress --parallel=16 --remove-original --target-dir=/opt/app/databack &&
    /xtrabackup/cmd/bin/xtrabackup --prepare --use-memory=8G --target-dir=/opt/app/databack &&
    /xtrabackup/cmd/bin/xtrabackup --copy-back --parallel=16 --target-dir=/opt/app/databack --datadir=${DATA_DIR} &&
    cp /opt/app/databack/xtrabackup_binlog_info /root/master_binlog_info &&
    rm -rf /opt/app/databack
    echo "=========当前数据恢复主机名为：$HOSTNAME=============="
    echo "*****************************"
    echo "**********数据还原完成*******"
    echo "*****************************"
    echo "执行：kubectl scale sts $STS_NAME -n$NAMESPACE --replicas=3 恢复应用"
    echo ""
    echo "========== Binlog 位置信息 (用于配置主从复制) =========="
    cat /root/master_binlog_info
else
    echo "请先停止mysql应用!"
    exit
fi
