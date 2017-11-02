[![build](https://img.shields.io/travis/utPLSQL/utPLSQL-v2-v3-migration/master.svg?label=master%20branch)](https://travis-ci.org/utPLSQL/utPLSQL-v2-v3-migration)
[![sonar](https://sonarcloud.io/api/badges/gate?key=utPLSQL%3AutPLSQL-v2-v3-migration)](https://sonarcloud.io/dashboard?id=utPLSQL%3AutPLSQL-v2-v3-migration)

# utPLSQL v2 to v3 migration utility

This project provides a migration utility to enrich utPLSQL v2 package specification with [utPLSQL v3](https://github.com/utPLSQL/utPLSQL) [annotations](https://utplsql.github.io/utPLSQL/v3.0.0/userguide/annotations.html)

## Download

Download latest release from this location:

https://github.com/utPLSQL/utPLSQL-v2-v3-migration/releases/latest


## Requirements

- [latest version of utPLSQL v2](https://github.com/utPLSQL/utPLSQL/releases/tag/utplsql-2-3-1) needs to be installed
- [utPLSQL v3](https://github.com/utPLSQL/utPLSQL/releases/latest) needs to be installed
- Installation needs to be done from a `SYS` account or as `SYSDBA` as utPLSQL v3 user needs to be granted execute privilege on `UTL_FILE`.
This is required for installing utPLSQL v2 compatibility within utPLSQL v3.


## Content

Migration utility contains the following components:

- Package `ut_v2_migration`
- Modified version of `utassert` package from utPLSQL version 2.3.1
- Modified version of `utassert2` package from utPLSQL version 2.3.1

All of above components are installed into utPLSQL v3 schema, have public synonyms created and are granted to public. 

## Installation
Navigate to `source` directory and execute `install.sql` script using `SQLPlus` or `sqlcl` as in the example below.
 
```bash
cd source
sqlplus sys/oracle@xe as sysdba @install utp ut3
```

The install script does the following:

- Checks if utPLSQL v2 is installed
- Checks if utPLSQL v3 is installed
- Drops public synonyms for `utassert` and `utassert2`  
- Installs packages: `ut_v2_migration`, `utassert`, `utassert2` into utPLSQL v3 schema
- Creates public synonyms for `utassert` and `utassert2` in utPLSQL v3 schema  
- Grants execute on packages: `ut_v2_migration`, `utassert`, `utassert2` to PUBLIC


# Migration process

## Requirements

The migration process scans utPLSQL v2 meta-data tables: 
- ut_package
- ut_suite
- ut_config

In order to be considered by migration process, Unit Test package needs to:
- be registered in `ut_package` table - this can be done either by manually registering a package or by executing test package using utPLSQL v2 framework
- be existing in the database
- be valid

User executing the migration needs to:
- be the owner of migrated packages
- have `create any procedure` system privilege 

The migration process is designed, so that after migration, you can invoke the unit tests using both:
- utPLSQL v2.x framework
- utPLSQL v3.x framework

Once migration packages were installed, you can either test or execute migration of utPLSQL v2 packages.

## Testing migration

You may want to execute a dry-run of migration prior to running actual process on your database.
The dry-run will output results of migration to dbms_output.

There are several ways to invoke the dry-run:

- for all utPLSQL v2 packages registered in the database

```sql
set serveroutput on
begin
  ut_v2_migration.dry_run_all;
end;
/
```

- for utPLSQL v2 packages registered in a schema

```sql
set serveroutput on
begin
  ut_v2_migration.dry_run(a_owner => 'XYZ');
end;
/
```

- for utPLSQL v2 suite

```sql
set serveroutput on
begin
  ut_v2_migration.dry_run_for_suite(a_suite_name => 'XYZ');
end;
/
```

- for a single utPLSQL v2 package

```sql
set serveroutput on
begin
  ut_v2_migration.dry_run(a_owner => 'XYZ', a_package => 'ABC');
end;
/
```

## Executing migration

- for all utPLSQL v2 packages registered in the database

```sql
set serveroutput on
begin
  ut_v2_migration.run_all;
end;
/
```

- for utPLSQL v2 packages registered in a schema

```sql
set serveroutput on
begin
  ut_v2_migration.run(a_owner => 'XYZ');
end;
/
```

- for utPLSQL v2 suite

```sql
set serveroutput on
begin
  ut_v2_migration.run_for_suite(a_suite_name => 'XYZ');
end;
/
```

- for a single utPLSQL v2 package

```sql
set serveroutput on
begin
  ut_v2_migration.run(a_owner => 'XYZ', a_package => 'ABC');
end;
/
```
