## Setting up streaming replication
PSR (Physical Streaming Replication)  has two main way to set up streaming replication:
*  with an additional archive
*  without an additional archive
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

postgres=# exit
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
