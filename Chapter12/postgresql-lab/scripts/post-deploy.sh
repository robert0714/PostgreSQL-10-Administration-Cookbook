
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


sudo sh -c 'echo local  replication   all                trust  >>  /var/lib/pgsql/11/data/pg_hba.conf'
sudo sh -c 'echo host   replication   all  127.0.0.1/32  trust  >>  /var/lib/pgsql/11/data/pg_hba.conf'
sudo sh -c 'echo host   replication   all  ::1/128       trust  >>  /var/lib/pgsql/11/data/pg_hba.conf'
sudo sh -c 'echo host   replication   all  0.0.0.0/0       trust  >>  /var/lib/pgsql/11/data/pg_hba.conf'
# sudo sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/g' /var/lib/pgsql/11/data/pg_hba.conf
sudo sh -c "echo listen_addresses = \'*\'   >>  /var/lib/pgsql/11/data/postgresql.conf"
sudo sh -c "echo max_wal_size = 20GB   >>  /var/lib/pgsql/11/data/postgresql.conf"
sudo sh -c "echo checkpoint_timeout = 3600   >>  /var/lib/pgsql/11/data/postgresql.conf"
sudo sh -c "echo log_connections = on   >>  /var/lib/pgsql/11/data/postgresql.conf"
sudo sh -c "echo max_wal_senders = 2    >>  /var/lib/pgsql/11/data/postgresql.conf"
sudo sh -c "echo wal_level = \'archive\'   >>  /var/lib/pgsql/11/data/postgresql.conf"
sudo sh -c "echo archive_mode = on    >>  /var/lib/pgsql/11/data/postgresql.conf"
sudo sh -c "echo archive_command = \'cd .\'    >>  /var/lib/pgsql/11/data/postgresql.conf"
 
sudo systemctl enable postgresql-11.service
sudo systemctl start postgresql-11.service


