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
100.100.110.101  node1
100.100.110.102  node2 
######################################################
" > /etc/hosts

fi

# setting ssh configuration
su - postgres -c 'ssh-keygen  -f ~/.ssh/id_rsa  -q   '
su - postgres -c 'cat ~/.ssh/id_rsa.pub'
su - postgres -c   "printf 'NoHostAuthenticationForLocalhost yes
 Host *  
    StrictHostKeyChecking no' > ~/.ssh/config"
sudo echo "postgres:123" |chpasswd


# install ldapsearch 
yum install -y openldap openldap-clients


# install postgresql server
sudo rpm -Uvh https://yum.postgresql.org/11/redhat/rhel-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
sudo yum install  -y  postgresql11-server

# install pglogical
sudo yum install -y  postgresql11-server postgresql11-contrib
sudo curl https://access.2ndquadrant.com/api/repository/dl/default/release/11/rpm | bash
sudo yum install -y postgresql11-pglogical

# initializes database
sudo  /usr/pgsql-11/bin/postgresql-11-setup initdb

sudo echo "
# Database administrative login by Unix domain socket
local   all             postgres                                peer

# TYPE  DATABASE        USER            ADDRESS                 METHOD

# \"local\" is for Unix domain socket connections only
local   all             all                                     peer
# IPv4 local connections:
host    all             all             127.0.0.1/32            md5
# IPv6 local connections:
host    all             all             ::1/128                 md5
# Allow replication connections from localhost, by a user with the
# replication privilege.
local   replication     all                                     trust
host    replication     all             127.0.0.1/32            trust
host    replication     all             ::1/128                 trust
# host    all             all             all                     md5
host    all             all             all                      ldap ldapserver=192.168.2.12 ldapsearchattribute=\"sAMAccountName=\"  ldapbasedn=\"dc=iead,dc=local\"  ldapport=389
" > /var/lib/pgsql/11/data/pg_hba.conf
# echo "local   all           omnidb                            trust" >> "$PG_HBA"
# echo "host    all           omnidb       127.0.0.1/32         trust" >> "$PG_HBA"
# echo "host    all           omnidb       ::1/128              trust" >> "$PG_HBA"
# echo "local   replication   omnidb                            trust" >> "$PG_HBA"
# echo "host    replication   omnidb       127.0.0.1/32         trust" >> "$PG_HBA"
# echo "host    replication   omnidb       ::1/128              trust" >> "$PG_HBA"
# echo "host    all           omnidb       10.33.3.114/32       trust" >> "$PG_HBA"
# echo "host    replication   omnidb       10.33.3.114/32       trust" >> "$PG_HBA"
# echo "host    all           omnidb       10.33.3.115/32       trust" >> "$PG_HBA"
# echo "host    replication   omnidb       10.33.3.115/32       trust" >> "$PG_HBA"




# sudo sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/g' /var/lib/pgsql/11/data/pg_hba.conf
sudo sh -c "echo listen_addresses = \'*\'   >>  /var/lib/pgsql/11/data/postgresql.conf"
sudo sh -c "echo wal_level = \'logical\'   >>  /var/lib/pgsql/11/data/postgresql.conf"
sudo sh -c "echo max_worker_processes = 10   >>  /var/lib/pgsql/11/data/postgresql.conf"
sudo sh -c "echo max_replication_slots = 10   >>  /var/lib/pgsql/11/data/postgresql.conf"
sudo sh -c "echo max_wal_senders = 10    >>  /var/lib/pgsql/11/data/postgresql.conf"
sudo sh -c "echo shared_preload_libraries  = \'pglogical\'     >>  /var/lib/pgsql/11/data/postgresql.conf"
sudo sh -c "echo client_encoding = utf8     >>  /var/lib/pgsql/11/data/postgresql.conf"

sudo sh -c "echo max_wal_size = 20GB   >>  /var/lib/pgsql/11/data/postgresql.conf"
sudo sh -c "echo checkpoint_timeout = 3600   >>  /var/lib/pgsql/11/data/postgresql.conf"
sudo sh -c "echo log_connections = on   >>  /var/lib/pgsql/11/data/postgresql.conf"
sudo sh -c "echo archive_mode = on    >>  /var/lib/pgsql/11/data/postgresql.conf"
sudo sh -c "echo archive_command = \'cp %p /archive/%f\'    >>  /var/lib/pgsql/11/data/postgresql.conf"


sudo systemctl enable postgresql-11.service
sudo systemctl start postgresql-11.service

sudo mkdir /archive
sudo chown postgres.postgres /archive

cat << EOF | su - postgres -c psql
-- Create the database user:
CREATE USER $APP_DB_USER WITH PASSWORD '$APP_DB_PASS' SUPERUSER;

-- Create the database:
CREATE DATABASE $APP_DB_NAME WITH OWNER=$APP_DB_USER
                                  LC_COLLATE='en_US.utf8'
                                  LC_CTYPE='en_US.utf8'
                                  ENCODING='UTF8'
                                  TEMPLATE=template0;
EOF


###########################################################
# Changes below this line are probably not necessary
###########################################################
print_db_usage () {
  echo "Your PostgreSQL database has been setup and can be accessed on your local machine on the forwarded port (default: $PG_LOCAL_PORT)"
  echo "  Host: localhost"
  echo "  Port: $PG_LOCAL_PORT"
  echo "  Database: $APP_DB_NAME"
  echo "  Username: $APP_DB_USER"
  echo "  Password: $APP_DB_PASS"
  echo ""
  echo "Admin access to postgres user via VM:"
  echo "  vagrant ssh"
  echo "  sudo su - postgres"
  echo ""
  echo "psql access to app database user via VM:"
  echo "  vagrant ssh"
  echo "  sudo su - postgres"
  echo "  PGUSER=$APP_DB_USER PGPASSWORD=$APP_DB_PASS psql -h localhost $APP_DB_NAME"
  echo ""
  echo "Env variable for application development:"
  echo "  DATABASE_URL=postgresql://$APP_DB_USER:$APP_DB_PASS@localhost:$PG_LOCAL_PORT/$APP_DB_NAME"
  echo ""
  echo "Local command to access the database via psql:"
  echo "  PGUSER=$APP_DB_USER PGPASSWORD=$APP_DB_PASS psql -h localhost -p $PG_LOCAL_PORT $APP_DB_NAME"
}

echo "Successfully created PostgreSQL dev virtual machine."
echo ""
print_db_usage