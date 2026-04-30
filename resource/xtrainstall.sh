#!/bin/bash
rm -rf /xtrabackup
mkdir  /xtrabackup
cd /xtrabackup
mv /tmp/my.cnf    /xtrabackup
mv /tmp/percona-xtrabackup-8.0.35-30-Linux-x86_64.glibc2.17-minimal.tar.gz   /xtrabackup
tar -zxvf /xtrabackup/percona-xtrabackup-8.0.35-30-Linux-x86_64.glibc2.17-minimal.tar.gz
mv /xtrabackup/percona-xtrabackup-8.0.35-30-Linux-x86_64.glibc2.17-minimal /xtrabackup/cmd