#!/bin/bash
# xtrabackup 8.0 TCP 远程备份时会查询 MySQL 服务端 @@datadir 并 cd 进去
# 容器内 datadir 为 /bitnami/mysql/data/，在宿主机创建该目录以避免备份时 my_setwd 报错
mkdir -p /bitnami/mysql/data

rm -rf /xtrabackup
mkdir  /xtrabackup
cd /xtrabackup
mv /tmp/my.cnf    /xtrabackup
mv /tmp/percona-xtrabackup-8.0.35-30-Linux-x86_64.glibc2.17-minimal.tar.gz   /xtrabackup
tar -zxvf /xtrabackup/percona-xtrabackup-8.0.35-30-Linux-x86_64.glibc2.17-minimal.tar.gz
mv /xtrabackup/percona-xtrabackup-8.0.35-30-Linux-x86_64.glibc2.17-minimal /xtrabackup/cmd