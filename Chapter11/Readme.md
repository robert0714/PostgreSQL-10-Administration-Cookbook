# Backup and Recovery
## WebConsole

```bash
docker pull dpage/pgadmin4
docker run -p 80:80 \
        -e "PGADMIN_DEFAULT_EMAIL=user@domain.com" \
        -e "PGADMIN_DEFAULT_PASSWORD=SuperSecret" \
        -d dpage/pgadmin4
```

## Node1

```bash

[root@node1 vagrant]# su - postgres -c "psql"
psql (11.5)
Type "help" for help.

postgres=# create database db1;

postgres=# \list
                                  List of databases
   Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges   
-----------+----------+----------+-------------+-------------+-----------------------
 db1       | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 postgres  | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 template0 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
(4 rows)

postgres=# \connect db1
You are now connected to database "db1" as user "postgres".
db1=# 
db1=# show wal_level;
wal_level
-----------
logical
db1# create ROLE replicator REPLICATION LOGIN PASSWORD 'linux';
CREATE ROLE
db1=# create table mynames (id int not null primary key, name text);
CREATE TABLE
db1=# grant ALL ON mynames to replicator;
GRANT
db1=# create publication mynames_pub for table mynames;
CREATE PUBLICATION
db1=# select slot_name,plugin,slot_type ,datoid,database,temporary,active,catalog_xmin,restart_lsn,confirmed_flush_lsn from pg_replication_slots;
  slot_name  |  plugin  | slot_type | datoid | database | temporary | active | catalog_xmin | restart_lsn | confirmed_flush_lsn 
-------------+----------+-----------+--------+----------+-----------+--------+--------------+-------------+---------------------
 mynames_sub | pgoutput | logical   |  16384 | db1      | f         | t      |          580 | 0/16D08D0   | 0/16D0908
 slot1       |          | physical  |        |          | f         | f      |              |             | 
(2 rows)
```

## Understanding and controlling crash recovery

modify /var/lib/pgsql/11/data/postgresql.conf

```conf
(ommit...)
max_wal_size = 20GB 
checkpoint_timeout = 3600
(ommit...)
```

## Hot physical backup and continuous archiving
The rest of this recipe assumes the following answers to the key questions:

*  The archive is a directory, such as /backups/archive , on a remote server for disaster recovery named $DRNODE
*  We send WAL files to the archive using rsync ; however, WAL streaming can also be used by changing the recipe in a way similar to the previous one 
*  Base backups are also stored on $DRNODE , in the /backups/base directory
*  Base backups are made using rsync

The following steps assume that a number of environment variables have been set, which are as follows:

*  $PGDATA is the path to the PostgreSQL data directory, ending with /
*  $DRNODE is the name of the remote server
*  $BACKUP_NAME is an identifier for the backup
*  All the required PostgreSQL connection parameters have been set

We also assume that the PostgreSQL user can connect via SSH to the backup server from the server where PostgreSQL is running, without having to type a passphrase. This standard procedure is described in detail in several places, including Barman's documentation at http:/​/ docs.pgbarman.org/.

The procedure is as follows:

1.  Create the archive and backup directories on a backup server.
1.  Set archive_command . In postgresql.conf , you will need to add the
following lines and restart the server or just confirm that they are present:

```bash
archive_mode = on
archive_command = 'test ! -f ../standalone/archiving_active || cp -i  %p  ../standalone/archive/%f'
```

3. Define the name of the backup, as follows:

```
BACKUP_NAME=$(date '+%Y%m%d%H%M')
```
4. Start the backup, as follows:

```
psql -c "select pg_start_backup('$BACKUP_NAME')"
[root@node1 11]# su - postgres -c 'psql'
psql (11.5)
Type "help" for help.
postgres-# \list
                                  List of databases
   Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges   
-----------+----------+----------+-------------+-------------+-----------------------
 postgres  | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 template0 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
(3 rows)

postgres-# \connect postgres
You are now connected to database "postgres" as user "postgres".
postgres=# select pg_start_backup('$BACKUP_NAME');
 pg_start_backup 
-----------------
 0/2000060
(1 row)

postgres=# select pg_stop_backup(), current_timestamp;
NOTICE:  pg_stop_backup complete, all required WAL segments have been archived
 pg_stop_backup |       current_timestamp
----------------+-------------------------------
 0/2000168      | 2019-10-09 06:45:00.821636+00
(1 row)
```

5. Copy the data files (excluding the content of the pg_wal directory), like this:

```bash
rsync -cva --inplace -exclude='pg_wal/*' \
${PGDATA}/   $DRNODE:/backups/base/$BACKUP_NAME/
```

6. Stop the backup, as follows:

```bash
psql -c "select pg_stop_backup(), current_timestamp" ;
```

It's also good practice to put a README.backup file in the data directory prior to the backup so that it forms part of the set of files that make up the base backup. This should say something intelligent about the location of the archive, including any identification numbers, names, and so on.

Notice that we didn't put recovery.conf in the backup this time. That's because we're assuming we want flexibility at the time of recovery, rather than a gift-wrapped solution. The reason for that is that we don't know when, where, or how we will be recovering, nor do we need to make that decision yet.