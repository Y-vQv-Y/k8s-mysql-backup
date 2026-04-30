#!/bin/bash
# master-0_backup.sh - 触发 test-mysql-master-0 的全量备份到 slave-0 节点
# 架构：控制节点 SSH 到 master 节点执行备份 → 控制节点 scp 传输到 slave 节点
# 不依赖节点间 SSH 互信，所有远程操作从控制节点发起

NAMESPACE="test"
MASTER_POD="test-mysql-master-0"
SLAVE_POD="test-mysql-slave-0"
SVC_NAME="test-mysql-master-0-nodeport"
MYSQL_PORT=3306
BACKUP_DATE=$(date +%Y-%m-%d)
BACKUP_FILE="/opt/app/xtra_full_${BACKUP_DATE}.xbstream"

MASTER_NODE=$(kubectl get pod $MASTER_POD -n$NAMESPACE -o jsonpath='{.status.hostIP}')
if [[ -z "$MASTER_NODE" ]]; then
    echo "错误：无法获取 $MASTER_POD 的节点 IP"
    exit 1
fi

SLAVE_NODE=$(kubectl get pod $SLAVE_POD -n$NAMESPACE -o jsonpath='{.status.hostIP}')
if [[ -z "$SLAVE_NODE" ]]; then
    echo "错误：无法获取 $SLAVE_POD 的节点 IP"
    exit 1
fi

SVC_IP=$(kubectl get svc $SVC_NAME -n$NAMESPACE -o jsonpath='{.spec.clusterIP}')
if [[ -z "$SVC_IP" ]]; then
    echo "错误：无法获取 $SVC_NAME 的 ClusterIP"
    exit 1
fi

echo "=========================================="
echo "  MySQL 全量备份 - $MASTER_POD"
echo "=========================================="
echo "  Master Pod  : $MASTER_POD"
echo "  Master 节点 : $MASTER_NODE"
echo "  MySQL 地址  : $SVC_IP:$MYSQL_PORT"
echo "  Slave 节点  : $SLAVE_NODE"
echo "  备份文件    : $BACKUP_FILE"
echo "=========================================="

echo "[1/2] 在 master 节点执行备份（输出到节点本地文件）..."
ssh root@$MASTER_NODE "/root/xtra_backup_remote.sh $SVC_IP $MYSQL_PORT $BACKUP_FILE"
if [[ $? -ne 0 ]]; then
    echo "错误：备份执行失败"
    exit 1
fi

echo "[2/2] 从控制节点传输备份文件 $MASTER_NODE → $SLAVE_NODE ..."
scp root@$MASTER_NODE:$BACKUP_FILE root@$SLAVE_NODE:$BACKUP_FILE
if [[ $? -ne 0 ]]; then
    echo "错误：备份文件传输失败"
    exit 1
fi

echo ""
echo "备份完成: $SLAVE_NODE:$BACKUP_FILE"
echo "可在 slave 节点验证: ssh root@$SLAVE_NODE 'ls -lh $BACKUP_FILE'"
