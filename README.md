[![build](https://img.shields.io/travis/utPLSQL/utPLSQL-v2-v3-bridge/master.svg?label=master%20branch)](https://travis-ci.org/utPLSQL/utPLSQL-v2-v3-bridge)
[![sonar](https://sonarqube.com/api/badges/gate?key=utPLSQL%3AutPLSQL%3master)](https://sonarqube.com/dashboard/index?id=utPLSQL%3AutPLSQL%3Adevelop)

# utPLSQL v2 to v3 migration utility

This project provides a migration utility to enrich utPLSQL v2 package specification with [utPLSQL v3 annotations](https://utplsql.github.io/utPLSQL/v3.0.0/userguide/annotations.html).

## Content

This utility contains the following components:

- Package `ut_v2_migration`
- Modified version of `utassert` package from utPLSQL version 2.3.1
- Modified version of `utassert2` package from utPLSQL version 2.3.1

## Download

Download latest release from (TODO) 

## Requirements

- utPLSQL v2 needs to be installed
- utPLSQL v3 needs to be installed
- user executing the installation needs to have following privileges:
   - `create any procedure`
   - `create public synonym`
   - `grant any object privilege`


## Installation

Execute `install.sql` script using `SQLPlus` or `sqlcl` as in the example below.
 
```bash
sqlplus sys/oracle@xe as sysdba @install utp ut3
```

The install script does the following:

- Checks if utPLSQL v2 is installed
- Checks if utPLSQL v3 is installed
- Drops public synonyms for `utassert` and `utassert2`  
- Installs packages: `ut_v2_migration`, `utassert`, `utassert2` into utPLSQL v3 schema
- Creates public synonyms for `utassert` and `utassert2` in utPLSQL v3 schema  
- Grants execute on packages: `ut_v2_migration`, `utassert`, `utassert2` to PUBLIC

## Executing migration

