#!/bin/bash
# master-1_backup.sh - 触发 test-mysql-master-1 的全量备份到 slave-1 节点

NAMESPACE="test"
MASTER_POD="test-mysql-master-1"
SLAVE_POD="test-mysql-slave-1"
SVC_NAME="test-mysql-master-1-nodeport"
MYSQL_PORT=3306

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

echo "备份源: $MASTER_POD (节点: $MASTER_NODE, 服务: $SVC_IP:$MYSQL_PORT)"
echo "备份目标: $SLAVE_POD (节点: $SLAVE_NODE)"

ssh root@$MASTER_NODE "/root/xtra_backup_remote.sh $SVC_IP $MYSQL_PORT $SLAVE_NODE"
