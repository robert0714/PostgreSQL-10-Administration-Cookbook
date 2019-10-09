
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


sudo sh -c 'echo host all all     0.0.0.0/0  md5    >>  /var/lib/pgsql/11/data/pg_hba.conf'
sudo sh -c 'echo host all replicator 0.0.0.0/0  md5  >>  /var/lib/pgsql/11/data/pg_hba.conf'
sudo sh -c "echo listen_addresses = \'*\'   >>  /var/lib/pgsql/11/data/postgresql.conf"
sudo sh -c "echo max_wal_size = 20GB   >>  /var/lib/pgsql/11/data/postgresql.conf"
sudo sh -c "echo checkpoint_timeout = 3600   >>  /var/lib/pgsql/11/data/postgresql.conf"

sudo systemctl enable postgresql-11.service
sudo systemctl start postgresql-11.service


