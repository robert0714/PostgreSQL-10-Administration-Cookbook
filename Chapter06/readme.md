## Integrating with Lightweight Directory Access Protocol (LDAP)
see the [reference]
(https://www.postgresql.org/docs/11/auth-ldap.html)


pg_hba.conf

```
(ommit..)
host    replication     all             127.0.0.1/32            trust
host    all             all             all                     ldap ldapserver=192.168.2.12 ldapbasedn="ou=IISI,dc=iead,dc=local" ldapsearchfilter="(sAMAccountName=$username)"

```

double check

```
[root@node1 vagrant]# ldapsearch -x -LLL -h 192.168.2.12 -D 1204003@iead.local -b "dc=iead,dc=local"  -w 'Password'
```