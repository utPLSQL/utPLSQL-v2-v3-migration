create or replace package test_migration as

  --%suite(Test migration of utPLSQL v2 package into utPLSQL v3 package)

  --%beforeall
  procedure coverage_develop_start;

  --%afterall
  procedure coverage_develop_stop;

  --%beforeeach
  procedure create_ut_v2_packages;

  --%aftereach
  procedure drop_ut_v2_packages;

  procedure remove_ut_v2_executions;

  procedure register_ut_v2_packages;

  --%test(Does not migrate unit tests that were not executed)
  --%beforetest(remove_ut_v2_executions)
  procedure ut_v2_with_no_executions;

  --%test(Does not raise exception when migrating an executed unit test package that doesn't exist)
  --%beforetest(register_ut_v2_packages)
  procedure ut_v2_dropped_package;

  --%test(Migrates an existing and executed unit test package)
  --%beforetest(register_ut_v2_packages)
  procedure ut_v2_migration_one_pkg;

  --%test(Migrates a registered suite packages)
  --%beforetest(register_ut_v2_packages)
  procedure ut_v2_migration_one_suite;

  --%test(Migrates all packages in schema)
  --%beforetest(register_ut_v2_packages)
  procedure ut_v2_migration_one_schema;

  --%test(Migrates all packages)
  --%beforetest(register_ut_v2_packages)
  procedure ut_v2_migration_all;
end;
/
