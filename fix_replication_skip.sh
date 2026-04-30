#!/bin/bash
# fix_replication_skip.sh - 快速跳过 MySQL 复制 SQL 线程错误（如 1062 重复键）
# 用法: bash fix_replication_skip.sh [pod-name] [namespace]
# 默认值: pod=test-mysql-slave-0, namespace=test

POD_NAME=${1:-test-mysql-slave-0}
NAMESPACE=${2:-test}

echo "========== 当前 slave 状态 ($POD_NAME) =========="
kubectl exec $POD_NAME -n$NAMESPACE -- mysql -uroot -p'Qrcode@2022' -e "SHOW SLAVE STATUS\G" 2>/dev/null | grep -E "Slave_IO_Running|Slave_SQL_Running|Last_Errno|Last_Error|Seconds_Behind_Master"

echo ""
echo "跳过当前错误事务..."
kubectl exec $POD_NAME -n$NAMESPACE -- mysql -uroot -p'Qrcode@2022' -e "STOP SLAVE; SET GLOBAL SQL_SLAVE_SKIP_COUNTER = 1; START SLAVE;" 2>/dev/null

sleep 2

echo ""
echo "========== 修复后 slave 状态 =========="
kubectl exec $POD_NAME -n$NAMESPACE -- mysql -uroot -p'Qrcode@2022' -e "SHOW SLAVE STATUS\G" 2>/dev/null | grep -E "Slave_IO_Running|Slave_SQL_Running|Last_Errno|Last_Error|Seconds_Behind_Master"

echo ""
echo "验证: 确认 Slave_IO_Running 和 Slave_SQL_Running 均为 Yes"
