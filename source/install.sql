prompt Installing utplsql v2-v3 migration utility

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

spool install.log

set termout on
@params.sql.tmp

whenever sqlerror exit failure rollback
whenever oserror exit failure rollback

prompt &&sep
declare
  l_object varchar2(200);
begin
  l_object := dbms_assert.sql_object_name('&&utplsql_v2_owner..utplsql');
  execute immediate q'[begin dbms_output.put_line('User &&utplsql_v2_owner owns utPLSQL v2'); end;]';
exception
  when others then
    raise_application_error(-20000, 'User &&utplsql_v2_owner does not own utPLSQL v2 or current user('||user||') does not have privileges to access it.');
end;
/

prompt &&sep
declare
  l_object varchar2(200);
begin
  l_object := dbms_assert.sql_object_name('&&utplsql_v3_owner..ut');
  execute immediate q'[begin dbms_output.put_line('User &&utplsql_v3_owner owns utPLSQL v3'); end;]';
exception
  when others then
    raise_application_error(-20000, 'User &&utplsql_v3_owner does not own utPLSQL v3 or current user('||user||') does not have privileges to access it.');
end;
/

prompt &&sep
prompt Using schema (&&utplsql_v2_owner) as owner of utPLSQL v2
prompt Using schema (&&utplsql_v3_owner) as owner of utPLSQL v3

alter session set current_schema = &&utplsql_v3_owner;

prompt &&sep
PROMPT Installing into schema &&utplsql_v3_owner
prompt &&sep
set feedback on
set echo on
grant execute on sys.utl_file to &&utplsql_v3_owner;

drop public synonym utassert2;
drop public synonym utassert;

set echo off
@@install_component.sql 'migration/ut3.utassert2.pks'
@@install_component.sql 'migration/ut3.utassert.pks'
@@install_component.sql 'migration/ut3.ut_v2_migration.pks'

@@install_component.sql 'migration/ut3.utassert2.pkb'
@@install_component.sql 'migration/ut3.utassert.pkb'
@@install_component.sql 'migration/ut3.ut_v2_migration.pkb'

set echo on
create or replace public synonym utassert  for &&utplsql_v3_owner..utassert;
create or replace public synonym utassert2 for &&utplsql_v3_owner..utassert2;
create or replace public synonym ut_v2_migration for ut_v2_migration;

grant execute on utassert  to public;
grant execute on utassert2 to public;
grant execute on ut_v2_migration to public;

set echo off
set feedback off
whenever sqlerror continue
create or replace public synonym ut_annotation_parser for &&utplsql_v3_owner..ut_annotation_parser;
create or replace public synonym ut_annotations for &&utplsql_v3_owner..ut_annotations;
prompt &&sep
PROMPT Installation completed successfully
prompt &&sep

set termout off

spool off
/*
* cleanup temporary sql files
*/
--try running on windows
$ del *.sql.tmp
--try running on linux/unix
! rm *.sql.tmp

exit success
