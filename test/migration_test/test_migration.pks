create or replace package test_migration as

  -- %suite(Test migration of utPLSQL v2 package into utPLSQL v3 package)

  -- %beforeeach
  procedure create_ut_v2_package;

  -- %aftereach
  procedure drop_ut_v2_package;

  procedure execute_ut_v2_betwnstr;

  -- %test(Does not migrate unit tests that were not executed)
  procedure ut_v2_with_no_executions;

  -- %test(Does not migrate unit tests that don't exist)
  -- %beforetest(execute_ut_v2_betwnstr)
  -- %aftertest(create_ut_v2_package)
  procedure ut_v2_dropped_package;


end;
/
