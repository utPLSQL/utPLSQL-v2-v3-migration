create or replace package body ut_v2_migration is

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

  procedure upgrade_v2_package_spec(a_owner_name varchar2, a_packge_name varchar2, a_package_desc varchar2, a_package_prefix varchar2, a_parent_suite varchar2, a_compile_flag boolean) is
    l_source               clob;
    l_setup_proc           varchar2(128 char) := upper(a_package_prefix || 'setup');
    l_teardown_proc        varchar2(128 char) := upper(a_package_prefix || 'teardown');
    l_replace_pattern      varchar2(50);
    l_suite_desc           varchar2(4000);
    l_suite_package        varchar2(4000);
  begin

    l_source := dbms_metadata.get_ddl('PACKAGE', a_packge_name, a_owner_name);

    if ut.version like '%v3.0.0%' or ut.version like '%v3.0.1%' or ut.version like '%v3.0.2%' or ut.version like '%v3.0.3%' then
      execute immediate q'[
       declare
         l_annotations ut_annotations.typ_annotated_package := ut_annotations.parse_package_annotations(:l_source);
       begin
         if l_annotations.package_annotations.exists('suite') then
           raise_application_error(-20400, 'Package '||:a_packge_name||' is already version 3 compatible');
         end if;
       end;
      ]' using l_source, a_packge_name;
    else
      execute immediate q'[
      declare
        l_exists integer;
      begin
        dbms_output.put_line('checking annotations');
        select 1
          into l_exists
          from table( ut_annotation_parser.parse_object_annotations( :l_source ) )
         where name = 'suite';
        raise_application_error(-20400, 'Package '||:a_packge_name||' is already version 3 compatible');
      exception
        when no_data_found then
        null;
      end;]' using l_source, a_packge_name;
    end if;

    if trim(a_package_desc) is not null then
      l_suite_desc := '('||trim(a_package_desc)||')';
    end if;

    if trim(a_parent_suite) is not null then
      l_suite_package := chr(10)||'  -- %suitepath('||trim(a_parent_suite)||')';
    end if;

    if not regexp_like(l_source,'\A(\s*(CREATE\s+(OR\s+REPLACE)?(\s+(NON)?EDITIONABLE)?\s+)?PACKAGE\s+)"'||a_owner_name||'"."'||a_packge_name||'"([^;]*?(AS|IS))','i') then
      raise_application_error(-20401,'Could not parse the package');
    end if;

    l_source := regexp_replace(srcstr     => l_source
                              ,pattern    => '\A(\s*(CREATE\s+(OR\s+REPLACE)?(\s+(NON)?EDITIONABLE)?\s+)?PACKAGE\s+)"'||a_owner_name||'"."'||a_packge_name||'"([^;]*?(AS|IS))'
                              ,replacestr => '\1' || a_owner_name || '.' || a_packge_name || '\6' || chr(10) || chr(10) || '  -- %suite' || l_suite_desc ||
                                             l_suite_package || chr(10) || chr(10)
                              ,modifier   => 'i'
                              ,occurrence => 1);

    for rec in (select t.*
                  from all_procedures t
                 where t.owner = a_owner_name
                   and t.object_name = a_packge_name
                   and t.procedure_name is not null
                   and upper(t.procedure_name) like upper(replace(a_package_prefix, '_', '\_') || '%') escape '\') loop

      l_replace_pattern := case upper(rec.procedure_name)
                             when l_setup_proc then
                              chr(10) || '\2-- %beforeall' || chr(10) || '\1'
                             when l_teardown_proc then
                              chr(10) || '\2-- %afterall' || chr(10) || '\1'
                             else
                              chr(10) || '\2-- %test' || chr(10) || '\1'
                           end;

      l_source := regexp_replace(l_source
                                ,'^(( *)procedure\s+' || rec.procedure_name || ')'
                                ,l_replace_pattern
                                ,modifier => 'im');

    end loop;

    if a_compile_flag then
      ut_utils.debug_log('Compiling package: ' || a_packge_name);
      ut_utils.debug_log(l_source);

      execute immediate l_source;
    else
      dbms_output.put_line(l_source);
      dbms_output.put_line('/');
    end if;

    dbms_lob.freetemporary(l_source);

  end upgrade_v2_package_spec;

  procedure migrate_v2_packages(a_owner_name varchar2 := null, a_package_name varchar2 := null, a_suite_name varchar2 := null, a_compile_flag boolean := true) is
    l_items_processed pls_integer := 0;
    l_items_succeeded pls_integer := 0;
    l_items_skipped pls_integer := 0;

    ex_compiled_with_errors exception;
    pragma exception_init(ex_compiled_with_errors,-24344);
  begin

    dbms_metadata.set_transform_param(dbms_metadata.session_transform,'BODY',false);

    for rec in (select p.owner
                      ,p.name
                      ,p.description as package_desc
                      ,nvl(p.prefix, c.prefix) prefix
                      ,s.name suite_name
                      ,s.description as suite_desc
                      ,o.status
                  from &&utplsql_v2_owner..ut_package p
                      ,&&utplsql_v2_owner..ut_suite s
                      ,&&utplsql_v2_owner..ut_config c
                      ,all_objects o
                 where p.id in (select max(p2.id) keep(dense_rank first order by p2.suite_id desc nulls last)
                                  from &&utplsql_v2_owner..ut_package p2
                                 group by upper(p2.owner)
                                         ,upper(p2.name))
                   and p.suite_id = s.id(+)
                   and p.owner = c.username(+)
                   and p.owner = o.owner
                   and p.name = o.object_name
                   and o.object_type in ('PACKAGE')
                   and p.owner = nvl(a_owner_name, p.owner)
                   and p.name = nvl(a_package_name, p.name)
                   and (s.name = a_suite_name or a_suite_name is null)
                   and upper(p.name) like upper(nvl(p.prefix, c.prefix))||'%'
    ) loop
      begin
        l_items_processed := l_items_processed +1;
        ut_utils.debug_log('Processing ' || rec.owner || '.' || rec.name);
        if rec.status = 'VALID' then
          upgrade_v2_package_spec(a_owner_name     => rec.owner,
                                  a_packge_name    => rec.name,
                                  a_package_desc   => rec.package_desc,
                                  a_package_prefix => rec.prefix,
                                  a_parent_suite   => rec.suite_name,
                                  a_compile_flag   => a_compile_flag);

          if a_compile_flag then
            dbms_output.put_line('Package ' || rec.owner || '.' || rec.name ||  ' migrated');
          end if;
          l_items_succeeded := l_items_succeeded + 1;
        else
          if not a_compile_flag then
            dbms_output.put('--');
          end if;
          dbms_output.put_line('Package ' || rec.owner || '.' || rec.name ||  ' is in invalid state - skipping');
          l_items_skipped := l_items_skipped +1;
        end if;

      exception
        when ex_package_already_migrated then
          ut_utils.debug_log('[IGNORE] Package ' || rec.owner || '.' || rec.name || ' already migrated');
          if not a_compile_flag then
            dbms_output.put('--');
          end if;
          dbms_output.put_line('Package ' || rec.owner || '.' || rec.name ||  ' already migrated. Package is skipped');
          l_items_skipped := l_items_skipped +1;
        when ex_package_parsing_failed then
          ut_utils.debug_log('[ERROR] Package ' || rec.owner || '.' || rec.name || ' parsing failed');

          if not a_compile_flag then
             dbms_output.put('--');
          end if;
          dbms_output.put_line('Package ' || rec.owner || '.' || rec.name ||  ' parsing failed. Package not migrated');
        when ex_compiled_with_errors then
          if a_compile_flag then
            dbms_output.put_line('Package ' || rec.owner || '.' || rec.name || ' compiled with errors ');
          else
            raise;
          end if;
      end;
    end loop;

    dbms_output.put_line('------------------');
    dbms_output.put_line('-----' || l_items_processed || ' items processed. '
                         || l_items_succeeded || ' - success, '
                         || l_items_skipped || ' - skipped, '
                         || (l_items_processed - l_items_succeeded - l_items_skipped) || ' - errors.');
    dbms_output.put_line('------------------');

  end;

  procedure dry_run(a_owner varchar2, a_package varchar2 := null) is
  begin
    migrate_v2_packages(a_owner_name => a_owner, a_package_name => a_package, a_compile_flag => false);
  end;

  procedure dry_run_for_suite(a_suite_name varchar2) is
  begin
    migrate_v2_packages( a_suite_name => a_suite_name, a_compile_flag => false);
  end;

  procedure dry_run_all is
  begin
    migrate_v2_packages(a_compile_flag => false);
  end;

  procedure run(a_owner varchar2, a_package varchar2 := null) is
  begin
    migrate_v2_packages(a_owner_name => a_owner, a_package_name => a_package);
  end;

  procedure run_for_suite(a_suite_name varchar2) is
  begin
    migrate_v2_packages(a_suite_name => a_suite_name);
  end;

  procedure run_all is
  begin
    migrate_v2_packages();
  end;

end ut_v2_migration;
/
