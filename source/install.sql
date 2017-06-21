prompt Installing utplsql v2-v3 migration utility

set serveroutput on size unlimited
set timing off
set feedback off
set verify off

whenever sqlerror exit failure rollback
whenever oserror exit failure rollback

define utplsql_v2_owner=&1
define utplsql_v3_owner=&2

alter session set current_schema = &&utplsql_v3_owner;

grant execute on sys.utl_file to &&utplsql_v3_owner;

drop public synonym utassert2;
drop public synonym utassert;

@@migration/utassert2.pks
@@migration/utassert.pks
@@migration/utassert2.pkb
@@migration/utassert.pkb
@@migration/ut_v2_migration.pks
@@migration/ut_v2_migration.pkb

create or replace public synonym utassert  for &&utplsql_v2_owner..utassert;
create or replace public synonym utassert2 for &&utplsql_v2_owner..utassert2;
create or replace public synonym ut_v2_migration for ut_v2_migration;

grant execute on utassert  to public;
grant execute on utassert2 to public;
grant execute on ut_v2_migration to public;

exit success
