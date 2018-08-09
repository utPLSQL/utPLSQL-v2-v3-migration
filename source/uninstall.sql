prompt Removing utplsql v2-v3 migration utility

set timing off
set feedback off
set verify off
set heading off
set linesize 1000
set pagesize 0
set echo off
set termout off
set serveroutput on size unlimited format truncated

column 1 new_value 1 noprint
column 2 new_value 2 noprint
select null as "1", null as "2" from dual where 1=0;
column sep new_value sep noprint
select '--------------------------------------------------------------' as sep from dual;

spool params.sql.tmp

select
  case
    when '&&1' is null then q'[ACCEPT utplsql_v2_owner CHAR DEFAULT 'UTP' PROMPT 'Provide schema owning the utPLSQL v2 (UTP)']'
    else 'define utplsql_v2_owner=&&1'
  end
from dual;
select
  case
    when '&&2' is null then q'[ACCEPT utplsql_v3_owner CHAR DEFAULT 'UT3' PROMPT 'Provide schema owning the utPLSQL v3 (UT3)']'
    else 'define utplsql_v3_owner=&&2'
  end
from dual;

spool off
set termout on
@params.sql.tmp

spool uninstall.log

drop package &&utplsql_v3_owner..ut_v2_migration;
drop public synonym ut_v2_migration;
drop package &&utplsql_v3_owner..utassert;
drop package &&utplsql_v3_owner..utassert2;
create or replace public synonym utassert  for &&utplsql_v2_owner..utassert;
create or replace public synonym utassert2 for &&utplsql_v2_owner..utassert2;

spool off
/*
* cleanup temporary sql files
*/
--try running on windows
$ del *.sql.tmp
--try running on linux/unix
! rm *.sql.tmp

exit success
