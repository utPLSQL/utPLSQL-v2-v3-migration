create or replace package body test_migration as

  gc_tested_function varchar2(32767) := q'[create or replace function betwnstr( a_string varchar2, a_start_pos integer, a_end_pos integer ) return varchar2 is
  l_start_pos pls_integer := a_start_pos;
begin
  if l_start_pos = 0 then
    l_start_pos := 1;
  end if;
  return substr( a_string, l_start_pos, a_end_pos - l_start_pos + 1);
end;]';
  gc_test_package varchar2(32767) := q'[create or replace package ut_betwnstr as
  procedure ut_setup;
  procedure ut_teardown;
  procedure ut_normal_case;
  procedure ut_zero_start_position;
  procedure ut_big_end_position;
  procedure ut_null_string;
  procedure ut_bad_params;
  procedure ut_bad_test;
end;
]';
  gc_test_package_body varchar2(32767) := q'[create or replace package body test_betwnstr as
  procedure ut_setup is begin null; end;
  procedure ut_teardown is begin null; end;
  procedure ut_normal_case is
  begin
    utassert.eq( 'Returns substring from start position to end position',betwnstr( '1234567', 2, 5 ), '2345');
  end;
  procedure ut_zero_start_position is
  begin
    utassert.eq( 'Returns substring when start position is zero', betwnstr( '1234567', 0, 5 ), '12345');
  end;
  procedure ut_big_end_position is
  begin
    utassert.eq( 'Returns string until end if end position is greater than string length', betwnstr( '1234567', 0, 500 ), '1234567') ;
  end;
  procedure ut_null_string is
  begin
    utassert.eq( 'Returns null for null input string value', betwnstr( null, 2, 5 ) ).to_( be_null() );
  end;
  procedure ut_bad_params is
  begin
    utassert.isnull( 'A demo of test raising runtime exception', betwnstr( '1234567', 'a', 'b' ) );
  end;
  procedure ut_bad_test
  is
  begin
    utassert.eq( 'A demo of failing test', betwnstr( '1234567', 0, 500 ), '1');
  end;
end;
]';

  procedure create_ut_v2_package is
    pragma autonomous_transaction;
  begin
    execute immediate gc_tested_function;
    execute immediate gc_test_package;
    execute immediate gc_test_package_body;
  end;

  procedure drop_ut_v2_package is
    pragma autonomous_transaction;
  begin
    execute immediate q'[drop package ut_betwnstr]';
    execute immediate q'[drop function betwnstr]';
  end;

  procedure execute_ut_v2_betwnstr is
  begin
    utplsql.run('UT_BETWNSTR');
  end;

  procedure ut_v2_with_no_executions is
    pragma autonomous_transaction;
  begin
    --act
    ut_v2_migration.migrate_v2_packages(user);
    --assert

  end;

  procedure ut_v2_dropped_package is
    pragma autonomous_transaction;
  begin
    --arrange
    drop_ut_v2_package;
    --act
    ut_v2_migration.migrate_v2_packages(user);
    --assert

  end;


end;
/
