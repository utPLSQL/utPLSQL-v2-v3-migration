#!/bin/bash

set -ev

cd ${UTPLSQL_V2_DIR}/code

sqlplus -L -S / AS SYSDBA <<SQL
create user utp identified by utp default tablespace
  users temporary tablespace temp;

grant create session, create table, create procedure,
  create sequence, create view, create public synonym,
  drop public synonym to utp;

alter user utp quota unlimited on users;
exit
SQL

sqlplus -S -L utp/utp <<SQL
@ut_i_do.sql install
exit
SQL
