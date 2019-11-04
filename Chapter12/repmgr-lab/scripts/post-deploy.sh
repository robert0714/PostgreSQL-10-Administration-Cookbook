
#!/bin/bash
# centos 7.6
value=$( grep -ic "entry" /etc/hosts )
if [ $value -eq 0 ]
then
echo "
################ hadoop-cookbook host entry ############
19.16.56.101  base-centos-1  #primary master
19.16.56.102  base-centos-2  #replica
19.16.56.103  base-centos-3  #replica
19.16.56.104  base-centos-4  #witness
######################################################
" > /etc/hosts
fi
sudo rpm -Uvh https://yum.postgresql.org/11/redhat/rhel-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
sudo yum install  -y  postgresql11-server
sudo  /usr/pgsql-11/bin/postgresql-11-setup initdb

# install REPMGR
curl https://dl.2ndquadrant.com/default/release/get/11/rpm | sudo bash
sudo yum repolist
sudo yum install repmgr11

# process SSH

# 1) [ON ALL SERVERS] Become the Postgres user, create the ssh key, then cat out the public key:
su - postgres -c 'mkdir -p ~/.ssh'
su - postgres -c 'ssh-keygen  -b 2048 -t rsa   -q -N \"\"  '
su - postgres -c 'cat ~/.ssh/id_rsa.pub'

# 2) [ON ALL SERVERS] Create an authorized keys file and set the permissions:

su - postgres -c 'touch ~/.ssh/authorized_keys'
su - postgres -c 'chmod 600 ~/.ssh/authorized_keys'
su - postgres -c 'vi ~/.ssh/authorized_keys'

# 3) [ON ALL SERVERS] Place all of the public keys from Step 1 into the authorized_keys files created in Step 2.  The authorized_keys file contents looked like the following on all of my servers, with each key as a new line:

# ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDTXxjFY8dLs2GVRpDY7asAK5SvwITPVSJN9ItnwsVtzCpZgX/Mbnkc/jHgwuIGb0srh/KthByyYJi14QViI+x7xVQm8eyuqMBtORt9rl6rLF73H/gYPO9jONIbD/yihxJMWmJK1Ro6Armhfj5OyTXyW6vjbXqvl7fuSi4n13ubW+G7Pnk8jDK+5rOFYve6Czmde7cQPeueo7sY4oZCbhO+Vr+HwK6qUNUsP3/iRj/bjpbNh8gaqQDl5y5XCNV32y3IhgMgsimO4EkSbb03y0lcWI8dJ6asnXUZumvUwasrFcQ2SFRqb/F3kK4L2Ofy9qYo0yV+FyCuJlsoEur1IRKF postgres@base-centos-1
# ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDYHmDFOtYc/VDxccNRQEnDYBTE8QDiUTMX46PX1p5tvs6qvP3VPMEccs4um0YVFXZTmbnvyeN3bBPe23NS5Pal6ySfAxIdAAOt5YzKoJ0BJAoHksfTchXsCvSs1zIBLXLSRTYdmjb2s+EWxB9elle4Z2KbZrXbzVkSQuUOdMtbjTPUfIqcVh8kokCznpVjKSEXtHg9Vx1Whg20brw99EzhcBeS5q+jJtQbaSa6VG3VUmsznxtoWiA9EgMZ9C7hcmxTrtKNEJrQvd1LpBObTYbueV7+MVlgShTct88alun12iheT6x6ien445X1lYjLmkjGT8CHNqdos+VQR9sgT5R7 postgres@base-centos-2
# ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCgQNra4/rDOVWr5uV5nSa49yPLlgAJ6crsYKpvhfRr3L5J/T48QE468Am5t3lA318Nst2FbObq7dduqBNhOQDurPlTiPd9cWQsj0mVySnZ2gD7sc8epyRcNbR5cNBum2JKkez4X8FxArMZwYkvPd28dAPFd30NwLYgIFhQ/jzScweyfX1RYp4s+AOI0XpBAiuQZ6r5Gxz+h61jmsbCwM4ZmT4J8OFIF/x/GFExF126PB2PqEg41OK2AGZ2eneTtaoDxMoVDPuy1vhdUw/aODf1dPZYRTn2rwbdXDW7E6Y8/dxT3Lo1n8v/syboy/MsF50NdYzwOb0/Q4dtYsVPpemV postgres@base-centos-3
# ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC5UAsmEkw9INHwXL6cpHqOy5O8VIpvLsfklzoHYfmGxBhGqi6nZzV/+TAzpotrmAf7PIUEdzWOm1lTfii1iRU821ks1bSPN2FeBXzK5Mhtl6KHpIXeDOS64WEJRcen2cQIw9f5f6Ji6PBlc3AQBvspxuNtth6Y0vOTq2N+kFTGOM95kuuIzRs7QvU0XrCoMKOn/BBE+e8ad72gwjCP1q9aNheDJBCsB9WhJerN+LOLr2gJiA0Ha6xxSGQ5WoAB17nYSQunsSvvAU079wfVt/e6OMozyNC6X/+I7IRcRg8IHS+aMKvKrasfi5PTawqoideB4QngM6lHmUR9/MFf9Ikt postgres@base-centos-4

# 4) I am now able to become the Postgres user and SSH to any of the other servers and log in without a password prompt. This is an example on base-centos-1:

# [root@base-centos-1 vagrant]# su - postgres
# Last login: Mon Jul 22 18:27:34 UTC 2019 on pts/0
# -bash-4.2$ ssh base-centos-2
# Last login: Mon Jul 22 18:22:31 2019
# -bash-4.2$ hostname
# base-centos-2

# Configre the REPMGR

#  [ON ALL SERVERS] Next, I configured repmgr on each server with the servers specific details. Make sure to update each according to the server and paths. As an example for each server, I updated the node_id, node_name, and conninfo to match the servers I was configuring. If you are using a different version of PostgreSQL you will want to make sure you update the paths for the version you are using. Do NOT assume the paths in my example will be the same on your system. In my setup, the configuration file was located at /etc/repmgr/11/repmgr.conf.
#  node_id=101
#  node_name='base-centos-1'
#  conninfo='host=base-centos-1 dbname=repmgr user=repmgr'
#  data_directory='/var/lib/pgsql/11/data/'
#  config_directory='/var/lib/pgsql/11/data'
#  log_file='/var/log/repmgr.log'
#  repmgrd_service_start_command = '/usr/pgsql-11/bin/repmgrd -d'
#  repmgrd_service_stop_command = 'kill `cat $(/usr/pgsql-11/bin/repmgrd --show-pid-file)`'
#  promote_command='repmgr standby promote -f /etc/repmgr/11/repmgr.conf --siblings-follow --log-to-file'
#  follow_command='repmgr standby follow -f /etc/repmgr/11/repmgr.conf --log-to-file'
#  failover=automatic
#  reconnect_attempts=3
#  reconnect_interval=5
#  ssh_options='-q -o StrictHostKeyChecking=no -o ConnectTimeout=10'

#3) [ON ALL SERVERS] I created the log file that I configured in Step 2 so I would not get an error when starting the service:

su - postgres -c 'touch /var/log/repmgr.log'


sudo sh -c 'echo local      replication     all                       trust  >>  /var/lib/pgsql/11/data/pg_hba.conf'
sudo sh -c 'echo host       replication     all  127.0.0.1/32         trust  >>  /var/lib/pgsql/11/data/pg_hba.conf'
sudo sh -c 'echo host       replication     all  ::1/128              trust  >>  /var/lib/pgsql/11/data/pg_hba.conf'
sudo sh -c 'echo host       replication     all  19.16.56.101/32      trust  >>  /var/lib/pgsql/11/data/pg_hba.conf'
sudo sh -c 'echo host       replication     all  19.16.56.102/32      trust  >>  /var/lib/pgsql/11/data/pg_hba.conf'
sudo sh -c 'echo host       replication     all  19.16.56.103/32      trust  >>  /var/lib/pgsql/11/data/pg_hba.conf'
sudo sh -c 'echo host       replication     all  19.16.56.104/32      trust  >>  /var/lib/pgsql/11/data/pg_hba.conf'
sudo sh -c 'echo host       repmgr          all  19.16.56.101/32      trust  >>  /var/lib/pgsql/11/data/pg_hba.conf'
sudo sh -c 'echo host       repmgr          all  19.16.56.102/32      trust  >>  /var/lib/pgsql/11/data/pg_hba.conf'
sudo sh -c 'echo host       repmgr          all  19.16.56.103/32      trust  >>  /var/lib/pgsql/11/data/pg_hba.conf'
sudo sh -c 'echo host       repmgr          all  19.16.56.104/32      trust  >>  /var/lib/pgsql/11/data/pg_hba.conf'
# sudo sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/g' /var/lib/pgsql/11/data/pg_hba.conf
sudo sh -c "echo listen_addresses = \'*\'   >>  /var/lib/pgsql/11/data/postgresql.conf"
sudo sh -c "echo shared_preload_libraries = \'repmgr\'   >>  /var/lib/pgsql/11/data/postgresql.conf"
sudo sh -c "echo wal_level = \'replica\'   >>  /var/lib/pgsql/11/data/postgresql.conf"
sudo sh -c "echo archive_mode = on    >>  /var/lib/pgsql/11/data/postgresql.conf"
sudo sh -c "echo max_wal_senders = 10    >>  /var/lib/pgsql/11/data/postgresql.conf"
sudo sh -c "echo hot_standby = on   >>  /var/lib/pgsql/11/data/postgresql.conf"
sudo sh -c "echo archive_command = \'cp %p /archive/%f\'    >>  /var/lib/pgsql/11/data/postgresql.conf"
 
su - postgres -c 'mkdir /var/lib/pgsql/10/data/archive'
sudo mkdir /archive
sudo chown postgres.postgres /archive

sudo systemctl enable postgresql-11.service
sudo systemctl restart postgresql-11.service
sudo systemctl status postgresql-11.service


