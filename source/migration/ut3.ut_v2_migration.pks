create or replace package ut_v2_migration authid current_user is

  /*
    procedure: upgrade_v2_package_spec

    converts a v2 package specification to v3
    Conversion is done only for packages registered un tuPLSQL v2 meta-data tables
    Suites get automatically created from v2 suites.

    Both utplsql v2 and utplsql v3 needs to be installed on the database for migration to work.

    utplsql v2 and utplsql v3 needs to have public synonyms and be granted to public.

    The ut_v2_migration package needs to be installed in utPLSQL v3 schema.
    When compiling package body, you will need to provide the schema name where utplsql v2 is installed.

    User invoking ut_v2_migration.migrate_v2_packages needs to have privileges to compile (recreate) the packages
    in the migrated schema(s)

    Parameters:
      a_owner_name - name of schema for which the migration of ut v2 unit test packages is to be done
      a_package_name - name of individual package to run migration for
      a_compile_flag (boolean) - should the package be compiled or only displayed to the screen
  */

  ex_package_already_migrated exception;
  pragma exception_init(ex_package_already_migrated, -20400);
  ex_package_parsing_failed exception;
  pragma exception_init(ex_package_parsing_failed, -20401);

  procedure migrate_v2_packages(a_owner_name varchar2, a_package_name varchar2 := null, a_compile_flag boolean := true);
  procedure migrate_v2_packages(a_compile_flag boolean := true);

end ut_v2_migration;
/
