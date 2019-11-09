#!/bin/bash
# centos 7.6

# Edit the following to change the name of the database user that will be created:
APP_DB_USER=omnidb
APP_DB_PASS=omnidb

# Edit the following to change the name of the database that is created (defaults to the user name)
APP_DB_NAME=omnidb_tests

# Edit the following to change the version of PostgreSQL that is installed
PG_VERSION=11

# Edit the following to change the local port PostgreSQL port 5432 will be mapped to
PG_LOCAL_PORT=5432

PG_CONF="/var/lib/pgsql/$PG_VERSION/main/postgresql.conf"
PG_HBA="/var/lib/pgsql/$PG_VERSION/main/pg_hba.conf"
PG_DIR="/usr/pgsql-$PG_VERSION/bin"

value=$( grep -ic "entry" /etc/hosts )
if [ $value -eq 0 ]
then
echo "
################ hadoop-cookbook host entry ############
100.100.100.101  node1
100.100.100.102  node2 
######################################################
" > /etc/hosts
fi

# install the 2ndQuadrant's General Public RPM repository
sudo curl https://dl.2ndquadrant.com/default/release/get/$PG_VERSION/rpm | sudo bash

# sudo yum install  -y  postgresql$PG_VERSION-server
sudo yum install  -y  postgresql$PG_VERSION
