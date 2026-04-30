#!/bin/bash
echo "开始安装......"
kubectl get node --show-labels -owide|grep mysql|awk '{print "scp resource/xtrainstall.sh resource/my.cnf resource/percona-xtrabackup-8.0.35-30-Linux-x86_64.glibc2.17-minimal.tar.gz  root@"  $6 ":/tmp" }'|sh
kubectl get node --show-labels -owide|grep mysql|awk '{print "scp resource/xtra_backup_remote.sh root@"  $6 ":/root" }'|sh
kubectl get node --show-labels -owide|grep mysql|awk '{print "scp resource/xtra_restor.sh   root@"  $6 ":/root" }'|sh
kubectl get pods -A -owide|grep test-mysql|awk '{print "kubectl get node -owide|grep   " $8}'|sh|awk '{print $6}' > resource/mysql_ip.txt
kubectl get node --show-labels -owide|grep mysql|awk '{print "ssh  "  $6 "   \"/tmp/xtrainstall.sh\"" }'> install.sh && sh install.sh && rm -f install.sh
echo "*****************************"
echo "**********安装完成***********"
echo "*****************************"
