## Setting up streaming replication
PSR (Physical Streaming Replication)  has two main way to set up streaming replication:
*  with an additional archive
*  without an additional archive

### Creating user

```bash
[root@node1 vagrant]# su - postgres 
-bash-4.2$    psql 
psql (11.5)
Type "help" for help.

postgres=# \list
                                  List of databases
   Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges
-----------+----------+----------+-------------+-------------+-----------------------
 postgres  | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |
 template0 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
(3 rows)

postgres=# \du
                                   List of roles
 Role name |                         Attributes                         | Member
 of
-----------+------------------------------------------------------------+-------
----
 postgres  | Superuser, Create role, Create DB, Replication, Bypass RLS | {}
postgres=# CREATE USER repuser
             REPLICATION
             LOGIN
             CONNECTION LIMIT 2
             ENCRYPTED PASSWORD 'changeme';
CREATE ROLE
postgres=# \du+
                                          List of roles
 Role name |                         Attributes                         | Member of | Description
-----------+------------------------------------------------------------+-----------+-------------
 postgres  | Superuser, Create role, Create DB, Replication, Bypass RLS | {}        |
 repuser   | Replication                                               +| {}        |
           | 2 connections                                              |           |

postgres=# exit
```

### Authenriztion about replication
/var/lib/pgsql/11/data/pg_hba.conf

```conf
local  replication   all                trust 
host   replication   all  127.0.0.1/32  trust  
host   replication   all  ::1/128       trust  
host   replication   all  0.0.0.0/0     trust  

```

### Without  an additional archive (method-1)
step 8 Take a base  backup (with an additional archive)
```bash
-bash-4.2$ pg_basebackup  -d 'dbname=postgres'  -D /tmp/test
-bash-4.2$ ls /tmp/test
backup_label  current_logfiles  log           pg_dynshmem  pg_ident.conf  pg_multixact  pg_replslot  pg_snapshots  pg_stat_tmp  pg_tblspc    PG_VERSION  pg_xact               postgresql.conf
base          global            pg_commit_ts  pg_hba.conf  pg_logical     pg_notify     pg_serial    pg_stat       pg_subtrans  pg_twophase  pg_wal      postgresql.auto.conf
-bash-4.2$ 
-bash-4.2$ pg_basebackup  -d 'dbname=postgres' --wal-method=stream -D /tmp/test1
-bash-4.2$ ls /tmp/test1
backup_label  current_logfiles  log           pg_dynshmem  pg_ident.conf  pg_multixact  pg_replslot  pg_snapshots  pg_stat_tmp  pg_tblspc    PG_VERSION  pg_xact               postgresql.conf
base          global            pg_commit_ts  pg_hba.conf  pg_logical     pg_notify     pg_serial    pg_stat       pg_subtrans  pg_twophase  pg_wal      postgresql.auto.conf
-bash-4.2$ 
-bash-4.2$ pg_basebackup  -d 'dbname=postgres' --wal-method=stream   --max-rate=RATE  -D /tmp/test2
pg_basebackup: transfer rate "RATE" is not a valid value
-bash-4.2$ pg_basebackup  -d 'dbname=postgres' --wal-method=stream   --max-rate=3000  -D /tmp/test2
-bash-4.2$ pg_basebackup  -d 'dbname=postgres' --wal-method=stream   --max-rate=30000  --slot=myslotname --create-slot -D /tmp/test3
-bash-4.2$ 
-bash-4.2$ ls /tmp/test3
backup_label  current_logfiles  log           pg_dynshmem  pg_ident.conf  pg_multixact  pg_replslot  pg_snapshots  pg_stat_tmp  pg_tblspc    PG_VERSION  pg_xact               postgresql.conf
base          global            pg_commit_ts  pg_hba.conf  pg_logical     pg_notify     pg_serial    pg_stat       pg_subtrans  pg_twophase  pg_wal      postgresql.auto.conf
-bash-4.2$ pg_basebackup  -d 'dbname=postgres' --wal-method=stream   --max-rate=30000  --slot=myslotname --create-slot  --write-recovery-conf  -D /tmp/test4
pg_basebackup: could not send replication command "CREATE_REPLICATION_SLOT "myslotname" PHYSICAL RESERVE_WAL": ERROR:  replication slot "myslotname" already exists
pg_basebackup: removing data directory "/tmp/test4"
-bash-4.2$ pg_basebackup  -d 'dbname=postgres' --wal-method=stream   --max-rate=30000   --write-recovery-conf  -D /tmp/test4
-bash-4.2$ ls /tmp/test4
backup_label  current_logfiles  log           pg_dynshmem  pg_ident.conf  pg_multixact  pg_replslot  pg_snapshots  pg_stat_tmp  pg_tblspc    PG_VERSION  pg_xact               postgresql.conf
base          global            pg_commit_ts  pg_hba.conf  pg_logical     pg_notify     pg_serial    pg_stat       pg_subtrans  pg_twophase  pg_wal      postgresql.auto.conf  recovery.conf
-bash-4.2$ cat /tmp/test4/recovery.conf
standby_mode = 'on'
primary_conninfo = 'user=postgres passfile=''/var/lib/pgsql/.pgpass'' port=5432 sslmode=prefer sslcompression=0 krbsrvname=postgres target_session_attrs=any'
-bash-4.2$
-bash-4.2$ pg_basebackup  -D test02 -h localhost --checkpoint=fast  --wal-method=stream -U repuser --write-recovery-conf
-bash-4.2$ ls test02
backup_label  current_logfiles  log           pg_dynshmem  pg_ident.conf  pg_multixact  pg_replslot  pg_snapshots  pg_stat_tmp  pg_tblspc    PG_VERSION  pg_xact               postgresql.conf
base          global            pg_commit_ts  pg_hba.conf  pg_logical     pg_notify     pg_serial    pg_stat       pg_subtrans  pg_twophase  pg_wal      postgresql.auto.conf  recovery.conf
-bash-4.2$ cat test02/recovery.conf 
standby_mode = 'on'
primary_conninfo = 'user=repuser passfile=''/var/lib/pgsql/.pgpass'' host=localhost port=5432 sslmode=prefer sslcompression=0 krbsrvname=postgres target_session_attrs=any'
-bash-4.2$ whoami
postgres
-bash-4.2$ pg_basebackup  -D test03 -h localhost --checkpoint=fast  --wal-method=stream -U repuser --write-recovery-conf -F=t
pg_basebackup: invalid output format "=t", must be "plain" or "tar"
-bash-4.2$ pg_basebackup  -D test03 -h localhost --checkpoint=fast  --wal-method=stream -U repuser --write-recovery-conf -F t
-bash-4.2$ ls test03
base.tar  pg_wal.tar
-bash-4.2$ pg_basebackup  -D test04 -h localhost --checkpoint=fast  --wal-method=stream -U repuser --write-recovery-conf -F p
-bash-4.2$ ls test04
backup_label  current_logfiles  log           pg_dynshmem  pg_ident.conf  pg_multixact  pg_replslot  pg_snapshots  pg_stat_tmp  pg_tblspc    PG_VERSION  pg_xact               postgresql.conf
base          global            pg_commit_ts  pg_hba.conf  pg_logical     pg_notify     pg_serial    pg_stat       pg_subtrans  pg_twophase  pg_wal      postgresql.auto.conf  recovery.conf
-bash-4.2$ 

```
#### Replaying the transaction log
Here is a sample ***recovery.conf*** file about modification:

```bash
[root@node1 data]# cat recovery.conf 
standby_mode = 'on'
primary_conninfo = 'user=repuser passfile=''/var/lib/pgsql/.pgpass'' host=localhost port=5432 sslmode=prefer sslcompression=0 krbsrvname=postgres target_session_attrs=any'
restore_command = 'cp /archive/%f %p'
recovery_target_time = '2019-10-28 14:16:16'
```

And then we modify th permission

```bash
[root@node1 data]# ls -la
total 64
drwx------. 20 postgres postgres  4096 Oct 28 06:17 .
drwx------.  4 postgres postgres    51 Oct 28 05:53 ..
(ommit ...)
-rw-------.  1 postgres postgres 24061 Oct 28 05:53 postgresql.conf
-rw-------.  1 postgres postgres    58 Oct 28 06:16 postmaster.opts
-rw-------.  1 root     root       275 Oct 28 06:13 recovery.conf
[root@node1 data]# chown -R postgres.postgres recovery.conf 
[root@node1 data]# ls -la
total 64
drwx------. 20 postgres postgres  4096 Oct 28 06:17 .
drwx------.  4 postgres postgres    51 Oct 28 05:53 ..
(ommit ...)
-rw-------.  1 postgres postgres 24061 Oct 28 05:53 postgresql.conf
-rw-------.  1 postgres postgres    58 Oct 28 06:16 postmaster.opts
-rw-------.  1 postgres postgres   275 Oct 28 06:13 recovery.conf
[root@node1 data]# systemctl restart  postgresql-11
[root@node1 data]# tail -n 60 -f /var/lib/pgsql/11/data/log/postgresql-Mon.log 
2019-10-28 06:26:47.813 UTC [19593] LOG:  database system was shut down in recovery at 2019-10-28 06:26:32 UTC
2019-10-28 06:26:47.813 UTC [19593] LOG:  entering standby mode
cp: cannot stat ‘/archive/000000010000000000000005’: No such file or directory
2019-10-28 06:26:47.819 UTC [19593] LOG:  consistent recovery state reached at 0/5000098
2019-10-28 06:26:47.819 UTC [19593] LOG:  invalid record length at 0/5000098: wanted 24, got 0
2019-10-28 06:26:47.819 UTC [19590] LOG:  database system is ready to accept read only connections
2019-10-28 06:26:47.835 UTC [19599] LOG:  connection received: host=127.0.0.1 port=54116
2019-10-28 06:26:47.836 UTC [19599] LOG:  replication connection authorized: user=repuser
2019-10-28 06:26:47.837 UTC [19598] LOG:  started streaming WAL from primary at 0/5000000 on timeline 1

```

If  the  setting parameters of configuration file (recovery.conf) modified.

```bash
[root@node1 data]# cat recovery.conf 
restore_command = 'cp /archive/%f %p'
recovery_target_time = '2019-10-28 14:16:16'
[root@node1 data]# tail -n 60 -f /var/lib/pgsql/11/data/log/postgresql-Mon.log 
tail: cannot open ‘/var/lib/pgsql/11/data/log/postgresql-Mon.log’ for reading: No such file or directory
tail: no files remaining
[root@node1 data]# systemctl restart  postgresql-11
[root@node1 data]# tail -n 60 -f /var/lib/pgsql/11/data/log/postgresql-Mon.log 
2019-10-28 06:29:24.895 UTC [19628] LOG:  database system was shut down in recovery at 2019-10-28 06:28:58 UTC
2019-10-28 06:29:24.895 UTC [19628] LOG:  starting point-in-time recovery to 2019-10-28 14:16:16+00
cp: cannot stat ‘/archive/000000010000000000000005’: No such file or directory
2019-10-28 06:29:24.901 UTC [19628] LOG:  consistent recovery state reached at 0/5000098
2019-10-28 06:29:24.901 UTC [19628] LOG:  invalid record length at 0/5000098: wanted 24, got 0
2019-10-28 06:29:24.901 UTC [19628] LOG:  redo is not required
2019-10-28 06:29:24.902 UTC [19625] LOG:  database system is ready to accept read only connections
cp: cannot stat ‘/archive/000000010000000000000005’: No such file or directory
cp: cannot stat ‘/archive/00000002.history’: No such file or directory
2019-10-28 06:29:24.917 UTC [19628] LOG:  selected new timeline ID: 2
2019-10-28 06:29:25.087 UTC [19628] LOG:  archive recovery complete
cp: cannot stat ‘/archive/00000001.history’: No such file or directory
2019-10-28 06:29:25.206 UTC [19625] LOG:  database system is ready to accept connections
```
After the recovery has finished, the ***recovery.conf*** file will be renamed ***recovery.done***
so that we can see what we have done during recovery. All of the processes of our database
server will be up and running and we will have a ready-to-use database instance.


#### Finding the right timestamp
The First , Adapt the recovery.conf file before starting the replay process:

```conf
recovery_target_action = 'pause'
```

There is a second way to pause transaction log replay. Basically, it can also be used when performing PITR. However, in most cases, it is used with streaming replication. Here is what can be done during ***WAL*** replay:

```bash
-bash-4.2$ psql
psql (11.5)
Type "help" for help.

postgres=# \x
Expanded display is on.
postgres=# \df *pause*
List of functions
-[ RECORD 1 ]-------+------------------------
Schema              | pg_catalog
Name                | pg_is_wal_replay_paused
Result data type    | boolean
Argument data types | 
Type                | func
-[ RECORD 2 ]-------+------------------------
Schema              | pg_catalog
Name                | pg_wal_replay_pause
Result data type    | void
Argument data types | 
Type                | func

postgres=# \df *resume*
List of functions
-[ RECORD 1 ]-------+---------------------
Schema              | pg_catalog
Name                | pg_wal_replay_resume
Result data type    | void
Argument data types | 
Type                | func

postgres=#
```


If recovery.conf is 

```conf
standy_mode = 'on'
```

You would find the below errors.

```bash
postgres=# SELECT pg_wal_replay_pause();
-[ RECORD 1 ]-------+-
pg_wal_replay_pause | 

postgres=# SELECT pg_wal_replay_resume();
-[ RECORD 1 ]--------+-
pg_wal_replay_resume | 

postgres=# SELECT pg_create_restore_point('my_daily_process_ended');
ERROR:  recovery is in progress
HINT:  WAL control functions cannot be executed during recovery.
postgres=# 
```

If you remove the ***"standby_mode=on"*** .

```bash
postgres=# SELECT pg_create_restore_point('my_daily_process_ended');
 pg_create_restore_point 
-------------------------
 0/7000248
(1 row)
```

#### Cleaning up the transaction log archive
So far, data is being written to the archive all of the time and no attention has been paid to cleaning out the archive again to free up space in the filesystem. PostgreSQL cannot do this job for us because it has no idea whether we want to use the archive again. Therefore, we are in charge of cleaning up the transaction log. Of course, we can also use a backup tool—however, it is important to know that PostgreSQL has no chance of doing the cleanup for us.

Suppose we want to clean up an old transaction log that is not needed anymore. Maybe we want to keep several base backups around and clean out all transaction logs that won't be needed anymore to restore one of those backups.

In this case, the ***pg_archivecleanup*** command-line tool is exactly what we need. We can simply pass the archive directory and the name of the backup file to the
***pg_archivecleanup*** command, and it will make sure that files are removed from disk. Using this tool makes life easier for us because we don't have to figure out which transaction log files to keep on our own. Here is how it works:

```bash
[root@node1 /]# cd /usr/pgsql-11/bin
[root@node1 bin]# ./pg_archivecleanup  --help
pg_archivecleanup removes older WAL files from PostgreSQL archives.

Usage:
  pg_archivecleanup [OPTION]... ARCHIVELOCATION OLDESTKEPTWALFILE

Options:
  -d             generate debug output (verbose mode)
  -n             dry run, show the names of the files that would be removed
  -V, --version  output version information, then exit
  -x EXT         clean up files if they have this extension
  -?, --help     show this help, then exit

For use as archive_cleanup_command in recovery.conf when standby_mode = on:
  archive_cleanup_command = 'pg_archivecleanup [OPTION]... ARCHIVELOCATION %r'
e.g.
  archive_cleanup_command = 'pg_archivecleanup /mnt/server/archiverdir %r'

Or for use as a standalone archive cleaner:
e.g.
  pg_archivecleanup /mnt/server/archiverdir 000000010000000000000010.00000020.backup

Report bugs to <pgsql-bugs@postgresql.org>.
[root@node1 bin]# 
```

### Without an additional archive (method-2)
Add parameters in postgresql.con:

```conf
wal_keep_segments = 10000 # 160 GB
```

step.6 Start the backup:

```
psql -c "select pg_start_backup('base backup for streaming rep')"
```

step 7. Copy the data files (excluding the pg_wal directory)

```bash
rsync -cva --inplace --exclude=*pg_wal* \  
${PGDATA}/ $STANDBYNODE:$PGDATA
```

step 8 Stop the backup

```bash
psql -c "select pg_stop_backup(), current_timestamp"
```

Step 9. Set the ***recovery.conf*** parameters on the standby. Note that   ***primary_conninfo*** must not specify a database name, though it can contain any other PostgreSQL connection option. Also, note that all options in  ***recovery.conf*** are enclosed in quotes, whereas the ***postgresql.conf*** parameters need not be:

```bash
standby_mode = 'on' 
primary_conninfo = 'host=alpha user=repuser' 
trigger_file = '/tmp/postgresql.trigger.5432'
```
Step 10. Start the standby server.

Step 11. Carefully monitor the replication delay until the catch-up period is over. During the initial catch-up period, the replication delay will be much higher than we would normally expect it to be.

Eventually, you still find some errors.
refer

*  [Replication in PostgreSQL – Setting up Streaming](https://www.percona.com/blog/2018/09/07/setting-up-streaming-replication-postgresql)

*  [PostgreSQL Streaming Replication - a Deep Dive](https://severalnines.com/database-blog/postgresql-streaming-replication-deep-dive)

*  [Wiki](https://wiki.postgresql.org/wiki/Streaming_Replication)