
#!/bin/bash
# centos 7.6
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

# install postgresql server
sudo rpm -Uvh https://yum.postgresql.org/11/redhat/rhel-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
sudo yum install  -y  postgresql11-server

# install pglogical
sudo yum install -y  postgresql11-server postgresql11-contrib
sudo curl https://access.2ndquadrant.com/api/repository/dl/default/release/11/rpm | bash
sudo yum install -y postgresql11-pglogical

# initializes database
sudo  /usr/pgsql-11/bin/postgresql-11-setup initdb


sudo sh -c 'echo local      replication     all                             trust  >>  /var/lib/pgsql/11/data/pg_hba.conf'
sudo sh -c 'echo host       replication     all     127.0.0.1/32            trust  >>  /var/lib/pgsql/11/data/pg_hba.conf'
sudo sh -c 'echo host       replication     all     ::1/128                 trust  >>  /var/lib/pgsql/11/data/pg_hba.conf'
sudo sh -c 'echo host       replication     all     100.100.110.101/32      trust  >>  /var/lib/pgsql/11/data/pg_hba.conf'
sudo sh -c 'echo host       replication     all     100.100.110.102/32      trust  >>  /var/lib/pgsql/11/data/pg_hba.conf'


# sudo sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/g' /var/lib/pgsql/11/data/pg_hba.conf
sudo sh -c "echo listen_addresses = \'*\'   >>  /var/lib/pgsql/11/data/postgresql.conf"
sudo sh -c "echo wal_level = \'logical\'   >>  /var/lib/pgsql/11/data/postgresql.conf"
sudo sh -c "echo max_worker_processes = 10   >>  /var/lib/pgsql/11/data/postgresql.conf"
sudo sh -c "echo max_replication_slots = 10   >>  /var/lib/pgsql/11/data/postgresql.conf"
sudo sh -c "echo max_wal_senders = 10    >>  /var/lib/pgsql/11/data/postgresql.conf"
sudo sh -c "echo shared_preload_libraries  = \'pglogical\'     >>  /var/lib/pgsql/11/data/postgresql.conf"

sudo sh -c "echo max_wal_size = 20GB   >>  /var/lib/pgsql/11/data/postgresql.conf"
sudo sh -c "echo checkpoint_timeout = 3600   >>  /var/lib/pgsql/11/data/postgresql.conf"
sudo sh -c "echo log_connections = on   >>  /var/lib/pgsql/11/data/postgresql.conf"
sudo sh -c "echo archive_mode = on    >>  /var/lib/pgsql/11/data/postgresql.conf"
sudo sh -c "echo archive_command = \'cp %p /archive/%f\'    >>  /var/lib/pgsql/11/data/postgresql.conf"


sudo systemctl enable postgresql-11.service
sudo systemctl start postgresql-11.service

sudo mkdir /archive
sudo chown postgres.postgres /archive
