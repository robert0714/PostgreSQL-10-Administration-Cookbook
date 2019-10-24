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
-bash-4.2$ pg_basebackup  -d 'dbname=postgres'  -D /tmp/test
-bash-4.2$ ls /tmp/test
backup_label  current_logfiles  log           pg_dynshmem  pg_ident.conf  pg_multixact  pg_replslot  pg_snapshots  pg_stat_tmp  pg_tblspc    PG_VERSION  pg_xact               postgresql.conf
base          global            pg_commit_ts  pg_hba.conf  pg_logical     pg_notify     pg_serial    pg_stat       pg_subtrans  pg_twophase  pg_wal      postgresql.auto.conf
-bash-4.2$ pg_basebackup  -d 'dbname=postgres' --wal-method=stream -D /tmp/test1
-bash-4.2$ ls /tmp/test1
backup_label  current_logfiles  log           pg_dynshmem  pg_ident.conf  pg_multixact  pg_replslot  pg_snapshots  pg_stat_tmp  pg_tblspc    PG_VERSION  pg_xact               postgresql.conf
base          global            pg_commit_ts  pg_hba.conf  pg_logical     pg_notify     pg_serial    pg_stat       pg_subtrans  pg_twophase  pg_wal      postgresql.auto.conf
-bash-4.2$ pg_basebackup  -d 'dbname=postgres' --wal-method=stream   --max-rate=RATE  -D /tmp/test2
pg_basebackup: transfer rate "RATE" is not a valid value
-bash-4.2$ pg_basebackup  -d 'dbname=postgres' --wal-method=stream   --max-rate=3000  -D /tmp/test2
-bash-4.2$ pg_basebackup  -d 'dbname=postgres' --wal-method=stream   --max-rate=30000  --slot=myslotname --create-slot -D /tmp/test3
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