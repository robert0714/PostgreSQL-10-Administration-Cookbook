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

## Planning backups

