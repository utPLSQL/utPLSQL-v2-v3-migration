create or replace package ut_v2_migration authid current_user is

  /*
  utPLSQL v2 migration
  Copyright 2017 utPLSQL Project

  Licensed under the Apache License, Version 2.0 (the "License"):
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
  */

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

  procedure dry_run(a_owner varchar2, a_package varchar2 := null);
  procedure dry_run_for_suite(a_suite_name varchar2);
  procedure dry_run_all;

  procedure run(a_owner varchar2, a_package varchar2 := null);
  procedure run_for_suite(a_suite_name varchar2);
  procedure run_all;

end ut_v2_migration;
/
