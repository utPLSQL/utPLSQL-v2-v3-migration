#!/bin/bash

set -ev

"$SQLCLI" sys/$ORACLE_PWD@//$CONNECTION_STR AS SYSDBA  <<SQL
create user ${DB_USER} identified by ${DB_PASS} quota unlimited on USERS default tablespace USERS;

grant create session, create procedure, create type, create table, create sequence, create view to ${DB_USER};
grant select any dictionary to ${DB_USER};
--needed to execute coverage report
grant create any procedure to ${DB_USER};
--needed for running coverage report in a self-test mode
grant execute on ut3.ut_coverage to ${DB_USER};

exit
SQL
