create or replace package body test_migration as

  gc_tested_function varchar2(32767) := q'[create or replace function betwnstr( a_string varchar2, a_start_pos integer, a_end_pos integer ) return varchar2 is
  l_start_pos pls_integer := a_start_pos;
begin
  if l_start_pos = 0 then
    l_start_pos := 1;
  end if;
  return substr( a_string, l_start_pos, a_end_pos - l_start_pos + 1);
end;]';
  gc_ut_betwnstr_package varchar2(32767) := q'[create or replace package ut_betwnstr as
  procedure ut_setup;
  procedure ut_teardown;
  procedure ut_normal_case;
end;
]';
  gc_ut_betwnstr_body varchar2(32767) := q'[create or replace package body ut_betwnstr as
  procedure ut_setup is begin null; end;
  procedure ut_teardown is begin null; end;
  procedure ut_normal_case is
  begin
    utassert.eq( 'Returns substring from start position to end position',betwnstr( '1234567', 2, 5 ), '2345');
  end;
end;
]';
  gc_ut_betwnstr_new_package varchar2(32767) := q'[create or replace package ut_betwnstr_new as
  procedure ut_setup;
  procedure ut_teardown;
  procedure ut_normal_case;
end;
]';
  gc_ut_betwnstr_new_body varchar2(32767) := q'[create or replace package body ut_betwnstr_new as
  procedure ut_setup is begin null; end;
  procedure ut_teardown is begin null; end;
  procedure ut_normal_case is
  begin
    utassert.eq( 'Returns substring from start position to end position',betwnstr( '1234567', 2, 5 ), '2345');
  end;
end;
]';

  procedure coverage_develop_start is
  begin
    ut3.ut_coverage.coverage_start_develop();
  end;

  procedure coverage_develop_stop is
  begin
    ut3.ut_coverage.coverage_stop_develop();
  end;

  procedure create_ut_v2_packages is
    pragma autonomous_transaction;
  begin
    execute immediate gc_tested_function;
    execute immediate gc_ut_betwnstr_package;
    execute immediate gc_ut_betwnstr_body;
    execute immediate gc_ut_betwnstr_new_package;
    execute immediate gc_ut_betwnstr_new_body;
    dbms_output.put_line('create_ut_v2_packages');
  end;

  procedure remove_ut_v2_executions is
    pragma autonomous_transaction;
  begin
    dbms_output.put_line('remove_ut_v2_executions');
    utpackage.rem(to_number(null),'UT_BETWNSTR');
    utpackage.rem(to_number(null),'UT_BETWNSTR_NEW');
    utSuite.rem('MIGRATION');
    commit;
  end;

  procedure drop_ut_v2_packages is
    pragma autonomous_transaction;
    procedure exec(p_what varchar2) is
    begin
      execute immediate p_what;
    exception
      when others then
        null;
    end;

  begin
    dbms_output.put_line('drop_ut_v2_packages');
    exec('drop package ut_betwnstr');
    exec('drop package ut_betwnstr_new');
    exec('drop function betwnstr');
    remove_ut_v2_executions;
  end;

  procedure register_ut_v2_packages is
    l_lines    dbmsoutput_linesarray;
    l_numlines integer;
    pragma autonomous_transaction;
  begin
    dbms_output.put_line('register_ut_v2_packages');
    utConfig.autocompile(false);
    utplsql.run('UT_BETWNSTR');
    utSuite.add ('MIGRATION');
    utPackage.add('MIGRATION', 'UT_BETWNSTR_NEW', samepackage_in => true);
    utplsql.testsuite ('MIGRATION');

    dbms_output.get_lines ( l_lines, l_numlines );
    commit;
  end;

  procedure ut_v2_with_no_executions is
    pragma autonomous_transaction;
    l_package clob;
  begin
    --act
    ut_v2_migration.run(user);
    --assert
    l_package := dbms_metadata.get_ddl('PACKAGE','UT_BETWNSTR');
    ut.expect( l_package ).not_to_match('-- %suite');
    ut.expect( l_package ).not_to_match('-- %test');
    ut.expect( l_package ).not_to_match('-- %beforeall');
    ut.expect( l_package ).not_to_match('-- %afterall');
  end;

  procedure ut_v2_dropped_package is
    l_sqlcode integer;
    pragma autonomous_transaction;
  begin
    --arrange
    drop_ut_v2_packages;
    --act
    begin
      dbms_output.disable;
      ut_v2_migration.run(user);
      dbms_output.enable;
    exception
      when others then
        l_sqlcode := sqlcode;
    end;
    ut.expect(l_sqlcode).to_be_null;
  end;

  procedure ut_v2_migration_one_pkg is
    pragma autonomous_transaction;
    l_package clob;
  begin
    --act
    ut_v2_migration.run(user, 'UT_BETWNSTR');
    --assert
    l_package := dbms_metadata.get_ddl('PACKAGE','UT_BETWNSTR');
    ut.expect( l_package ).to_match('-- %suite');
    ut.expect( l_package ).not_to_match('-- %suitepath');
    ut.expect( l_package ).to_match('-- %test');
    ut.expect( l_package ).to_match('-- %beforeall');
    ut.expect( l_package ).to_match('-- %afterall');
    l_package := dbms_metadata.get_ddl('PACKAGE','UT_BETWNSTR_NEW');
    ut.expect( l_package ).not_to_match('-- %suite');
  end;

  procedure ut_v2_migration_one_suite is
    pragma autonomous_transaction;
    l_package clob;
  begin
    --act
    ut_v2_migration.run_for_suite('MIGRATION');
    --assert
    l_package := dbms_metadata.get_ddl('PACKAGE','UT_BETWNSTR_NEW');
    ut.expect( l_package ).to_match('-- %suite');
    ut.expect( l_package ).to_match('-- %suitepath\(MIGRATION\)');
    ut.expect( l_package ).to_match('-- %test');
    ut.expect( l_package ).to_match('-- %beforeall');
    ut.expect( l_package ).to_match('-- %afterall');
    l_package := dbms_metadata.get_ddl('PACKAGE','UT_BETWNSTR');
    ut.expect( l_package ).not_to_match('-- %suite');
  end;

  procedure ut_v2_migration_one_schema is
    pragma autonomous_transaction;
    l_package clob;
  begin
    --act
    ut_v2_migration.run(USER);
    --assert
    l_package := dbms_metadata.get_ddl('PACKAGE','UT_BETWNSTR_NEW');
    ut.expect( l_package ).to_match('-- %suite');
    l_package := dbms_metadata.get_ddl('PACKAGE','UT_BETWNSTR');
    ut.expect( l_package ).to_match('-- %suite');
  end;

  procedure ut_v2_migration_all is
    pragma autonomous_transaction;
    l_package clob;
  begin
    --act
    ut_v2_migration.run_all;
    --assert
    l_package := dbms_metadata.get_ddl('PACKAGE','UT_BETWNSTR_NEW');
    ut.expect( l_package ).to_match('-- %suite');
    l_package := dbms_metadata.get_ddl('PACKAGE','UT_BETWNSTR');
    ut.expect( l_package ).to_match('-- %suite');
  end;

end;
/
