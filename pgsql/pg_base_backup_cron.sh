#!/bin/bash

set -o xtrace

## 备份用户
basebackup_user="${REPLICATION_USER}"
## 备份日期
basebackup_date=`date +%Y-%m-%d-%H-%M-%S`
## 备份根目录
pg_backup_dir="/data/backup"
## 基础备份目录
pg_basebackup_dir="${pg_backup_dir}/base"
## 服务器地址
pg_host="${PGSQL_SERVICE_HOST}"
## 数据库端口
pg_port=5432
## 有效备份保留时间
pg_backup_reservation=30
## 本次备份目录
basebackup_dir=${pg_basebackup_dir}/${basebackup_date}

source ~/.profile

[ -z "${REPLICATION_USER}" ] && exit 1 || [ -z "${REPLICATION_PASS}" ] && exit 1
echo "${pg_host}:5432:replication:${REPLICATION_USER}:${REPLICATION_PASS}" > ~/.pgpass
chmod 0600 ~/.pgpass

mkdir -p -m 0750 ${basebackup_dir}
echo "backup to directory: ${basebackup_dir}" >> ${pg_backup_dir}/basebackup.log

if [ $? -eq 0 ];then
        pg_basebackup -D ${basebackup_dir} -Ft -z -Pv -Xs -l ${basebackup_date} -U ${basebackup_user} -h ${pg_host} -p ${pg_port} >> ${pg_backup_dir}/basebackup.log 2>&1
else
        echo "backup directory is not right!!" >> ${pg_backup_dir}/basebackup.log
        exit 1
fi

if [ $? -eq 0 ];then
        echo "backup of ${basebackup_date} succeed" >> ${pg_backup_dir}/basebackup.log
else
        echo "backup of ${basebackup_date} failed" >> ${pg_backup_dir}/basebackup.log
        exit 1
fi


if [ $? -eq 0 ];then
        echo "compress of ${basebackup_date} succeed" >> ${pg_backup_dir}/basebackup.log
        md5sum ${basebackup_dir}.tar.gz >> ${pg_backup_dir}/basebackup.md5
else
        echo "compress of  ${basebackup_date} failed" >> ${pg_backup_dir}/basebackup.log
        exit 1
fi

find ${pg_basebackup_dir} -maxdepth 1 -type f -mtime +${pg_backup_reservation} >> ${pg_backup_dir}/basebackup_purge.log &&
find ${pg_basebackup_dir} -maxdepth 1 -type d -mtime +${pg_backup_reservation} >> ${pg_backup_dir}/basebackup_purge.log && 
find ${pg_basebackup_dir} -maxdepth 1 -type f -mtime +${pg_backup_reservation} -exec rm -rf {} \;
find ${pg_basebackup_dir} -maxdepth 1 -type d -mtime +${pg_backup_reservation} -exec rm -rf {} \;
