create or replace package test_migration as

  -- %suite(Test migration of utPLSQL v2 package into utPLSQL v3 package)

  -- %beforeall
  procedure coverage_develop_start;

  -- %afterall
  procedure coverage_develop_stop;

  -- %beforeeach
  procedure create_ut_v2_package;

  -- %aftereach
  procedure drop_ut_v2_package;

  procedure remove_ut_v2_execution;

  procedure execute_ut_v2_betwnstr;

  -- %test(Does not migrate unit tests that were not executed)
  -- %beforetest(remove_ut_v2_execution)
  procedure ut_v2_with_no_executions;

  -- %test(Does not raise exception when migrating an executed unit test package that doesn't exist)
  -- %beforetest(execute_ut_v2_betwnstr)
  procedure ut_v2_dropped_package;

  -- %test(Migrates an existing and executed unit test package)
  -- %beforetest(execute_ut_v2_betwnstr)
  procedure ut_v2_migration_success;

end;
/
