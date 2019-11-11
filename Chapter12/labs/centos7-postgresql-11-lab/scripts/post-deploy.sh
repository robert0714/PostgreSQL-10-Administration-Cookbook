
#!/bin/bash
# centos 7.6
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
sudo rpm -Uvh https://yum.postgresql.org/11/redhat/rhel-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
sudo yum install  -y  postgresql11-server
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
host    replication     all             0.0.0.0/0               trust
host    all             all             all                     md5
" > /var/lib/pgsql/11/data/pg_hba.conf

# sudo sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/g' /var/lib/pgsql/11/data/pg_hba.conf
sudo sh -c "echo listen_addresses = \'*\'   >>  /var/lib/pgsql/11/data/postgresql.conf"
sudo sh -c "echo max_wal_size = 20GB   >>  /var/lib/pgsql/11/data/postgresql.conf"
sudo sh -c "echo checkpoint_timeout = 3600   >>  /var/lib/pgsql/11/data/postgresql.conf"
sudo sh -c "echo log_connections = on   >>  /var/lib/pgsql/11/data/postgresql.conf"
sudo sh -c "echo max_wal_senders = 10    >>  /var/lib/pgsql/11/data/postgresql.conf"
sudo sh -c "echo wal_level = \'archive\'   >>  /var/lib/pgsql/11/data/postgresql.conf"
sudo sh -c "echo archive_mode = on    >>  /var/lib/pgsql/11/data/postgresql.conf"
sudo sh -c "echo archive_command = \'cp %p /archive/%f\'    >>  /var/lib/pgsql/11/data/postgresql.conf"
 
sudo systemctl enable postgresql-11.service
sudo systemctl start postgresql-11.service

sudo mkdir /archive
sudo chown postgres.postgres /archive
