prompt Installing utplsql v2-v3 bridge and migration utility

set serveroutput on size unlimited
set timing off
set define off

whenever sqlerror exit failure rollback
whenever oserror exit failure rollback

alter session set current_schema = &&utplsql_v3_owner;

drop public synonym ut_assert2;
drop public synonym ut_assert;
@@migration/ut_assert2.pks
@@migration/ut_assert.pks
@@migration/ut_assert2.pkb
@@migration/ut_assert.pkb
@@migration/ut_v2_migration.pks
@@migration/ut_v2_migration.pkb

create or replace public synonym ut_assert  for &&utplsql_v2_owner..ut_assert;
create or replace public synonym ut_assert2 for &&utplsql_v2_owner..ut_assert2;
create or replace public synonym ut_v2_migration for ut_v2_migration;

grant execute on ut_assert  to public;
grant execute on ut_assert2 to public;
grant execute on ut_v2_migration to public;

exit success
