#!/bin/bash
# slave-2_restore.sh - 触发 test-mysql-slave-2 的数据还原

NAMESPACE="test"
SLAVE_POD="test-mysql-slave-2"
STS_NAME="test-mysql-slave"
DATA_DIR="/opt/app/test-mysql/slave-2/data"
BACKUP_FILE="/opt/app/xtra_full_$(date +%Y-%m-%d).xbstream"

SLAVE_NODE=$(kubectl get pod $SLAVE_POD -n$NAMESPACE -o jsonpath='{.status.hostIP}')
if [[ -z "$SLAVE_NODE" ]]; then
    echo "错误：无法获取 $SLAVE_POD 的节点 IP"
    exit 1
fi

echo "=========================================="
echo "  MySQL 数据还原 - $SLAVE_POD"
echo "=========================================="
echo "  Namespace   : $NAMESPACE"
echo "  StatefulSet : $STS_NAME"
echo "  Slave Pod   : $SLAVE_POD"
echo "  Slave 节点  : $SLAVE_NODE"
echo "  数据目录    : $DATA_DIR"
echo "  备份文件    : $BACKUP_FILE"
echo "=========================================="
echo ""
echo "前置条件检查清单："
echo "  1. 已从 master-2 执行最新备份 (bash mysql_data_backup/master-2_backup.sh)"
echo "  2. 已停止目标 StatefulSet: kubectl scale sts $STS_NAME -n$NAMESPACE --replicas=0"
echo "  3. pod 已完全消失: watch -n 1 'kubectl get pod -A|grep mysql'"
echo ""
echo "请确认以上条件已满足？（yes or no）"
read confirm
if [[ $confirm != "yes" ]]; then
    echo "已取消。请先完成前置条件。"
    exit
fi

echo "开始远程还原..."
ssh root@$SLAVE_NODE "/root/xtra_restor.sh $NAMESPACE $STS_NAME $DATA_DIR $BACKUP_FILE --yes"

echo ""
echo "还原完成。下一步："
echo "  1. 启动 StatefulSet: kubectl scale sts $STS_NAME -n$NAMESPACE --replicas=3"
echo "  2. 等待 pod Ready: watch -n 1 'kubectl get pod -A|grep mysql'"
echo "  3. 配置主从复制 (参考上方 Binlog 位置信息)"
