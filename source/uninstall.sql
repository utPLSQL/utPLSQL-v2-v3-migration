drop package utassert;
drop package utassert2;
drop package ut_v2_migration;
drop public synonym ut_v2_migration;
create or replace public synonym utassert  for &&utplsql_v2_owner..utassert;
create or replace public synonym utassert2 for &&utplsql_v2_owner..utassert2;
drop package ut_v2_migration;
