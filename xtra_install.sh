#!/bin/bash
echo "开始安装......"

# 从 test-mysql pod 获取所在节点名并解析为节点 IP
kubectl get pods -ntest -o wide 2>/dev/null | grep -E "test-mysql-(master|slave)" | awk '{print $7}' | sort -u > /tmp/mysql_node_names.txt

if [[ ! -s /tmp/mysql_node_names.txt ]]; then
    echo "错误：未在 namespace=test 中找到 test-mysql-master 或 test-mysql-slave pod"
    echo "请确认 pod 已启动: kubectl get pods -ntest | grep test-mysql"
    exit 1
fi

echo "发现以下 MySQL 节点:"
> /tmp/mysql_nodes.txt
while read node_name; do
    node_ip=$(kubectl get node $node_name -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null)
    if [[ -n "$node_ip" ]]; then
        echo "  $node_name ($node_ip)"
        echo "$node_ip" >> /tmp/mysql_nodes.txt
    else
        echo "  $node_name (无法获取 IP，跳过)"
    fi
done < /tmp/mysql_node_names.txt
echo ""

if [[ ! -s /tmp/mysql_nodes.txt ]]; then
    echo "错误：未能解析任何节点 IP"
    exit 1
fi

# 复制安装包和配置到所有 MySQL 节点
while read node_ip; do
    echo "复制安装文件到 $node_ip ..."
    scp -o StrictHostKeyChecking=no resource/xtrainstall.sh resource/my.cnf resource/percona-xtrabackup-8.0.35-30-Linux-x86_64.glibc2.17-minimal.tar.gz root@$node_ip:/tmp/
done < /tmp/mysql_nodes.txt

# 复制备份/还原脚本到所有 MySQL 节点
while read node_ip; do
    echo "复制备份还原脚本到 $node_ip ..."
    scp -o StrictHostKeyChecking=no resource/xtra_backup_remote.sh root@$node_ip:/root/
    scp -o StrictHostKeyChecking=no resource/xtra_restor.sh root@$node_ip:/root/
done < /tmp/mysql_nodes.txt

# 保存节点 IP 列表
cp /tmp/mysql_nodes.txt resource/mysql_ip.txt
echo "节点 IP 列表已保存到 resource/mysql_ip.txt"

# 在所有 MySQL 节点上执行安装
while read node_ip; do
    echo "在 $node_ip 上执行安装 ..."
    ssh -o StrictHostKeyChecking=no root@$node_ip "bash /tmp/xtrainstall.sh"
done < /tmp/mysql_nodes.txt

rm -f /tmp/mysql_nodes.txt /tmp/mysql_node_names.txt
echo "*****************************"
echo "**********安装完成***********"
echo "*****************************"
