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

4. You may wish to create the **users.txt** file by directly copying the details from the server. This can be done by using the following **psql** script:

```bash
-bash-4.2$ psql
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

```bash
```