drop package ut_assert;
drop package ut_assert2;
drop package ut_v2_migration;
drop public synonym ut_v2_migration;
create or replace public synonym ut_assert  for &&utplsql_v2_owner..ut_assert;
create or replace public synonym ut_assert2 for &&utplsql_v2_owner..ut_assert2;
drop package ut_v2_migration;
