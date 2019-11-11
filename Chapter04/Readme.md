## Enable passwordless access to each database user that will debug functions

Every database user that uses the debugger needs local passwordless access to
the target database. This is because the database will create an additional
local connection to perform debugging operations.

We need to add a rule to *pg_hba.conf* of type `host`, matching the PostgreSQL
user and database OmniDB is connected to. The method can be either `trust`,
which is insecure and not recommended, or `md5`.

#### trust

- Add a rule similar to:

```bash
# TYPE  DATABASE        USER            ADDRESS                 METHOD
host    <database>      <user>          127.0.0.1/32            trust
host    <database>      <user>          ::1/128                 trust
```

#### md5

- Add rules similar to:

```bash
# TYPE  DATABASE        USER            ADDRESS                 METHOD
host    <database>      <user>          127.0.0.1/32            md5
host    <database>      <user>          ::1/128                 md5
```

- Create a `.pgpass` file with a similar content:

```bash
localhost:<port>:<database>:<username>:<password>
```

More information about how `.pgpass` works can be found here: https://www.postgresql.org/docs/11/static/libpq-pgpass.html

## Stopping the server in an emergency

1. The basic command to perform an emergency stop on the server is the following:

```bash
pg_ctl -D datadir stop -m immediate
[root@node1 bin]# su - postgres -c "/usr/pgsql-11/bin/pg_ctl -D /var/lib/pgsql/11/data/ stop -m immediate"
waiting for server to shut down.... done
server stopped
[root@node1 bin]# 
```

2. On Debian/Ubuntu, you can also use the following:

```bash
pg_ctlcluster 11 main stop -m immediate
```

3. Start Up

```bash
[root@node1 bin]# su - postgres -c "/usr/pgsql-11/bin/pg_ctl -D /var/lib/pgsql/11/data/ reload"
pg_ctl: PID file "/var/lib/pgsql/11/data/postmaster.pid" does not exist
Is server running?
[root@node1 bin]# su - postgres -c "/usr/pgsql-11/bin/pg_ctl -D /var/lib/pgsql/11/data/ start -m immediate"
waiting for server to start....2019-11-07 07:30:58.315 UTC [14124] LOG:  listening on IPv4 address "0.0.0.0", port 5432
2019-11-07 07:30:58.315 UTC [14124] LOG:  listening on IPv6 address "::", port 5432
2019-11-07 07:30:58.316 UTC [14124] LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
2019-11-07 07:30:58.319 UTC [14124] LOG:  listening on Unix socket "/tmp/.s.PGSQL.5432"
2019-11-07 07:30:58.332 UTC [14124] LOG:  redirecting log output to logging collector process
2019-11-07 07:30:58.332 UTC [14124] HINT:  Future log output will appear in directory "log".
 done
server started
```

## Reloading the server configuration files

With **systemd** , configuration files can be reloaded with the following syntax:

```bash
sudo systemctl reload SERVICEUNIT
```

Here, **SERVICEUNIT** must be replaced with the exact name of the systemd service unit for the server(s) that you want to reload.

```bash
[root@node1 bin]# su - postgres -c "/usr/pgsql-11/bin/pg_ctl -D /var/lib/pgsql/11/data/ reload"
server signaled
[root@node1 bin]# 
```

On all platforms, you can also reload the configuration files while still connected to PostgreSQL. If you are a superuser, this can be done from the following command line:

```bash
[root@node1 bin]# su - postgres -c "psql"
psql (11.5)
Type "help" for help.

postgres=# select  pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)

postgres=# 
```

This function is also often executed from an admin tool, such as **OmniDB**.

```bash
postgres=# SELECT name, setting, unit ,(source = 'default') as is_default FROM pg_settings WHERE context = 'sighup' AND (name like '%delay' or name like '%timeout') AND setting != '0';
             name             | setting | unit | is_default 
------------------------------+---------+------+------------
 authentication_timeout       | 60      | s    | t
 autovacuum_vacuum_cost_delay | 20      | ms   | t
 bgwriter_delay               | 200     | ms   | t
 checkpoint_timeout           | 3600    | s    | f
 max_standby_archive_delay    | 30000   | ms   | t
 max_standby_streaming_delay  | 30000   | ms   | t
 wal_receiver_timeout         | 60000   | ms   | t
 wal_sender_timeout           | 60000   | ms   | t
 wal_writer_delay             | 200     | ms   | t
(9 rows)

postgres=# 
```

## Running multiple servers on one system
Core PostgreSQL easily allows multiple servers to run on the same system, but there are a few wrinkles to be aware of.

Some installer versions create a PostgreSQL data directory named data. It then gets a little difficult to have more than one data directory without using different directory structures and names.

### For Debian/Ubuntu Linux

**Debian/Ubuntu packagers** chose a layout specifically designed to allow multiple servers potentially running with different software release levels. You might remember this from the Locating the database server files recipe in **Chapter 2, Exploring the Database**.


Thus, not all files will be found in the **data** directory. As an example, let's create an additional data directory:

1. We start by running this command:

```bash
vagrant@node1:~$ sudo -s
root@node1:~# sudo -u postgres pg_createcluster 11 main2
Creating new PostgreSQL cluster 11/main2 ...
/usr/lib/postgresql/11/bin/initdb -D /var/lib/postgresql/11/main2 --auth-local peer --auth-host md5
The files belonging to this database system will be owned by user "postgres".
This user must also own the server process.

The database cluster will be initialized with locale "en_US.UTF-8".
The default database encoding has accordingly been set to "UTF8".
The default text search configuration will be set to "english".

Data page checksums are disabled.

fixing permissions on existing directory /var/lib/postgresql/11/main2 ... ok
creating subdirectories ... ok
selecting default max_connections ... 100
selecting default shared_buffers ... 128MB
selecting default timezone ... Asia/Taipei
selecting dynamic shared memory implementation ... posix
creating configuration files ... ok
running bootstrap script ... ok
performing post-bootstrap initialization ... ok
syncing data to disk ... ok

Success. You can now start the database server using:

    pg_ctlcluster 11 main2 start

Warning: systemd does not know about the new cluster yet. Operations like "service postgresql start" will not handle it. To fix, run:
  sudo systemctl daemon-reload
Ver Cluster Port Status Owner    Data directory               Log file
11  main2   5433 down   postgres /var/lib/postgresql/11/main2 /var/log/postgresql/postgresql-11-main2.log
root@node1:~# sudo systemctl daemon-reload
```

2. The new database server can then be started using the following command:

```bash
root@node1:~# sudo -u postgres pg_ctlcluster 11 main2 start
Warning: the cluster will not be running as a systemd service. Consider using systemctl:
  sudo systemctl start postgresql@11-main2
root@node1:~# 
```

This is sufficient to create and start an additional database cluster in version **11**, named **main2**. The data and configuration files are stored inside the **/var/lib/postgresql/11/main2/** and **/etc/postgresql/11/main2/** directories, respectively, giving the new database the next unused port number, for example, **5433** if this is the second PostgreSQL server on that machine.

Local access to multiple PostgreSQL servers has been simplified as well. PostgreSQL client programs, such as **psql**, are wrapped by a special script that takes the cluster name as an additional parameter and automatically uses the corresponding port number. Hence, you don't really need the following command:

```bash
root@node1:~# su -  postgres
postgres@node1:~$  psql --port 5433 -h /var/run/postgresql
psql (11.5 (Ubuntu 11.5-3.pgdg18.04+1))
Type "help" for help.
postgres=# 
```

Instead, you can refer to the database server by name, as shown here:

```bash
postgres@node1:~$ psql  --cluster 11/main2
psql (11.5 (Ubuntu 11.5-3.pgdg18.04+1))
Type "help" for help.

postgres=#
```

This has its advantages, especially if you wish (or need) to change the port in the future. I find this extremely convenient, and it works with other utilities such as **pg_dump, pg_restore**, and so on.

### For Red Hat/Centos Linux

With Red Hat systems, you will need to run **initdb** directly, selecting your directories carefully:

1. First, initialize your ***data*** directory with something such as the following:

```bash
[root@node1 vagrant]# sudo -u postgres  /usr/pgsql-11/bin/initdb -D /var/lib/pgsql/11/datadir2
could not change directory to "/home/vagrant": Permission denied
Data page checksums are disabled.

creating directory /var/lib/pgsql/11/datadir2 ... ok
creating subdirectories ... ok
selecting default max_connections ... 100
selecting default shared_buffers ... 128MB
selecting default timezone ... UTC
selecting dynamic shared memory implementation ... posix
creating configuration files ... ok
running bootstrap script ... ok
performing post-bootstrap initialization ... ok
syncing data to disk ... ok

WARNING: enabling "trust" authentication for local connections
You can change this by editing pg_hba.conf or using the option -A, or
--auth-local and --auth-host, the next time you run initdb.

Success. You can now start the database server using:

    /usr/pgsql-11/bin/pg_ctl -D /var/lib/pgsql/11/datadir2 -l logfile start

[root@node1 vagrant]#
```

2. Then, modify the **port** parameter in the postgresql.conf file and start using the following command:

```bash
[root@node1 vagrant]# cd /var/lib/pgsql
[root@node1 pgsql]# sudo -u postgres /usr/pgsql-11/bin/pg_ctl -D /var/lib/pgsql/11/datadir2 -l logfile start
waiting for server to start.... done
server started
[root@node1 pgsql]#
```

This will create an additional database server at the default server version, with files stored in **/var/lib/pgsql/11/datadir2**.

You can also set up the server with the **chkconfig** utility to ensure it starts on boot, if your distribution supports it.

## Setting up a connection pool

```bash
root@node1 bin]# yum -y  install pgbouncer
[root@node1 /]# find -name pgbouncer.ini
./etc/pgbouncer/pgbouncer.ini
./usr/share/doc/pgbouncer/pgbouncer.ini
```

we modify the file in /etc/pgbouncer/pgbouncer.ini .

```ini
;
; pgbouncer configuration example
;
[databases]
postgres = port=5432 dbname=postgres
[pgbouncer]
listen_addr = 127.0.0.1
listen_port = 6432
admin_users = postgres
;stats_users = monitoring userid
auth_type = any
; put these files somewhere sensible:
auth_file = users.txt
logfile = pgbouncer.log
pidfile = pgbouncer.pid
server_reset_query = DISCARD ALL;
; default values
pool_mode = session
default_pool_size = 20
log_pooler_errors = 0
```

2. Create a **users.txt** file. This must contain the minimum users mentioned in **admin_users** and **stats_users**. Its format is very simple: a collection of lines with a username and a password. Consider the following as an example:

```bash
[root@node1 pgsql]# cd /etc/pgbouncer/
[root@node1 pgbouncer]# echo "\"postgres\"    \"\" " > users.txt
``` 

4. You may wish to create the **users.txt** file by directly copying the details from the server. This can be done by using the following **psql** script:

```bash
[root@node1 pgbouncer]# chown postgres:postgres users.txt 
[root@node1 pgbouncer]# sudo -u postgres  psql 
psql (11.5)
Type "help" for help.

postgres=# \o users.txt
postgres=# \t
Tuples only is on.
postgres=# SELECT '"'||rolname||'" "'||rolpassword||'"'
postgres-# FROM pg_authid;
postgres=# \q
```

5. Launch pgbouncer :

```bash
[root@node1 /]# su - postgres
Last login: Thu Nov  7 07:40:17 UTC 2019 on pts/0 
-bash-4.2$ pgbouncer -d pgbouncer.ini
2019-11-07 07:52:07.444 UTC [14772] FATAL cannot load config file
-bash-4.2$ pgbouncer -d /etc/pgbouncer/pgbouncer.ini
```
6. Test the connection; it should respond to reload :

```bash
-bash-4.2$ psql -p 6432 -h 127.0.0.1 -U postgres pgbouncer -c "reload"
RELOAD
-bash-4.2$ 
```

7. Finally, verify that PgBouncer's **max_client_conn** parameter does not exceed the **max_connections** parameter on PostgreSQL.



#### PgBouncer's other command

```bash
-bash-4.2$ psql -p 6432 -h 127.0.0.1 -U postgres pgbouncer -c "show users"
   name    | pool_mode
-----------+-----------
 pgbouncer |
(1 row)

-bash-4.2$
-bash-4.2$ psql -p 6432 -h 127.0.0.1 -U postgres pgbouncer -c "show version"
     version
------------------
 PgBouncer 1.12.0
(1 row)

-bash-4.2$ psql -p 6432 -h 127.0.0.1 -U postgres pgbouncer -c "show servers"
 type | user | database | state | addr | port | local_addr | local_port | connect_time | request_time | wait | wait_us | close_needed | ptr | link | remote_pid | tls
------+------+----------+-------+------+------+------------+------------+--------------+--------------+------+---------+--------------+-----+------+------------+-----
(0 rows)

-bash-4.2$
```

# Accessing multiple servers using the same host and port

Here, we will demonstrate another way to use PgBouncer—one instance can connect to databases hosted by different database servers at the same time. These databases can be on separate hosts, and can even have different major versions of PostgreSQL!

1. All you need to do is to set up PgBouncer like you did in the previous recipe, by replacing the **databases** section of **pgbouncer.ini** with the following:

```ini
[databases]
myfirstdb = port=5432 host=localhost
anotherdb = port=5437 host=localhost
sparedb = port=5435 host=localhost
```

The below is a detail script :

```bash
[vagrant@node1 ~]$ cd /tmp
[vagrant@node1 tmp]$ sudo -u postgres  /usr/pgsql-11/bin/initdb -D /var/lib/pgsql/11/anotherdb
(ommit...)
Success. You can now start the database server using:

    /usr/pgsql-11/bin/pg_ctl -D /var/lib/pgsql/11/anotherdb -l logfile start

[vagrant@node1 tmp]$ sudo -u postgres  /usr/pgsql-11/bin/initdb -D /var/lib/pgsql/11/sparedb
T(ommit...)
Success. You can now start the database server using:

    /usr/pgsql-11/bin/pg_ctl -D /var/lib/pgsql/11/sparedb -l logfile start

[vagrant@node1 tmp]$ sudo -u postgres  rm -rf  /var/lib/pgsql/11/*
[vagrant@node1 tmp]$ sudo -u postgres  /usr/pgsql-11/bin/initdb -D /var/lib/pgsql/11/myfirstdb
(ommit...)
Success. You can now start the database server using:

    /usr/pgsql-11/bin/pg_ctl -D /var/lib/pgsql/11/myfirstdb -l logfile start

[vagrant@node1 tmp]$ sudo -u postgres  echo "
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
host    all             all             all                     md5
" > /var/lib/pgsql/11/myfirstdb/pg_hba.conf
[vagrant@node1 tmp]$ yes | cp -f /var/lib/pgsql/11/myfirstdb/pg_hba.conf /var/lib/pgsql/11/anotherdb/pg_hba.conf
cp: overwrite ‘/var/lib/pgsql/11/anotherdb/pg_hba.conf’? [root@node1 tmp]#
[root@node1 tmp]# 
cp: overwrite ‘/var/lib/pgsql/11/sparedb/pg_hba.conf’? [root@node1 tmp]# exit
 [root@node1 tmp]# echo "port = 5437" >> /var/lib/pgsql/11/anotherdb/postgresql.conf
 [root@node1 tmp]# echo "port = 5435" >> /var/lib/pgsql/11/sparedb/postgresql.conf
[vagrant@node1 tmp]$ sudo -u  postgres /usr/pgsql-11/bin/pg_ctl -D /var/lib/pgsql/11/myfirstdb -l logfile start
waiting for server to start.... done
server started
[vagrant@node1 tmp]$ sudo -u  postgres /usr/pgsql-11/bin/pg_ctl -D /var/lib/pgsql/11/anotherdb -l logfile start
waiting for server to start.... done
server started
[vagrant@node1 tmp]$ sudo -u  postgres /usr/pgsql-11/bin/pg_ctl -D /var/lib/pgsql/11/sparedb -l logfile start
waiting for server to start.... done
server started
[vagrant@node1 tmp]$ sudo -u postgres   psql --port 5437  -h /var/run/postgresql
psql (11.5)
Type "help" for help.

postgres=# \c anotherdb;
FATAL:  database "anotherdb" does not exist
Previous connection kept
postgres=# CREATE DATABASE anotherdb WITH OWNER=postgres
                                  LC_COLLATE='en_US.utf8'
                                  LC_CTYPE='en_US.utf8'
                                  ENCODING='UTF8'
                                  TEMPLATE=template0;
postgres=# \c anotherdb;
You are now connected to database "anotherdb" as user "postgres".
anotherdb=# \q;
[vagrant@node1 tmp]$ sudo -u postgres   psql --port 5437  -h /var/run/postgresql
psql (11.5)
Type "help" for help.

postgres=# \c anotherdb;
FATAL:  database "anotherdb" does not exist
Previous connection kept
postgres=# CREATE DATABASE sparedb WITH OWNER=postgres
                                  LC_COLLATE='en_US.utf8'
                                  LC_CTYPE='en_US.utf8'
                                  ENCODING='UTF8'
                                  TEMPLATE=template0;
postgres=# \c sparedb;
You are now connected to database "sparedb" as user "postgres".
anotherdb=# \q;
[vagrant@node1 tmp]$  sudo -u postgres   psql 
psql (11.5)
Type "help" for help.

postgres=# show port ;
 port 
------
 5432
(1 row)

postgres=#
psql (11.5)
Type "help" for help.

postgres=# \c anotherdb;
FATAL:  database "anotherdb" does not exist
Previous connection kept
postgres=# CREATE DATABASE myfirstdb WITH OWNER=postgres
                                  LC_COLLATE='en_US.utf8'
                                  LC_CTYPE='en_US.utf8'
                                  ENCODING='UTF8'
                                  TEMPLATE=template0;
postgres=# \c myfirstdb;
You are now connected to database "myfirstdb" as user "postgres".
anotherdb=# \q;

```

2. Once you have started PgBouncer, you can connect to the first database:

```bash
$ psql -p 6432 -h 127.0.0.1 -U postgres myfirstdb
psql (11.1)
Type "help" for help.
myfirstdb=# show port;
port
------
5432
(1 row)
myfirstdb=# show server_version;
server_version
----------------
11.1
(1 row)
```

3. Now, you can connect to the anotherdb database as if it were on the same server:

```bah
myfirstdb=# \c anotherdb
psql (11.1, server 9.5.15)
You are now connected to database "anotherdb" as user "postgres".
```

4. The server's greeting message suggests that we have landed on a different server,so we check the port and the version:

```bash
anotherdb=# show port;
port
------
5437
(1 row)
anotherdb=# show server_version;
server_version
----------------
9.5.15
(1 row)
```
