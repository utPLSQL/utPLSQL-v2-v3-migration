create or replace package body ut_v2_migration is

  procedure upgrade_v2_package_spec(a_owner_name varchar2, a_packge_name varchar2, a_package_desc varchar2, a_package_prefix varchar2, a_parent_suite varchar2, a_compile_flag boolean) is
    l_resolved_owner       varchar2(128 char);
    l_resolver_object_name varchar2(128 char);
    l_source               clob;
    l_setup_proc           varchar2(128 char);
    l_teardown_proc        varchar2(128 char);
    l_repalce_pattern      varchar2(50);
    l_suite                ut_test_suite;
    l_suite_desc           varchar2(4000);
    l_suite_package        varchar2(4000); 
  begin
    l_resolved_owner       := a_owner_name;
    l_resolver_object_name := a_packge_name;
  
    ut_metadata.do_resolve(a_owner          => l_resolved_owner
                          ,a_object         => l_resolver_object_name);
  
    l_suite := ut_suite_manager.config_package(a_owner_name  => l_resolved_owner
                                              ,a_object_name => l_resolver_object_name);
  
    if l_suite is not null then
      raise_application_error(-20400, 'Package '||a_packge_name||' is already version 3 compatible');
    end if;
  
    l_setup_proc    := upper(a_package_prefix || 'setup');
    l_teardown_proc := upper(a_package_prefix || 'teardown');
  
    l_source := ut_metadata.get_package_spec_source(l_resolved_owner, l_resolver_object_name);
    
    if trim(a_package_desc) is not null then
      l_suite_desc := '('||trim(a_package_desc)||')';
    end if;
    
    if trim(a_parent_suite) is not null then
      l_suite_package := chr(10)||'  -- %suitepath('||trim(a_parent_suite)||')';
    end if;
    
    if not regexp_like(l_source,'\A(\s*PACKAGE\s+(\w+\.)?' || l_resolver_object_name || '\s+(AS|IS))','i') then
      raise_application_error(-20401,'Could not parse the package');
    end if;
  
    l_source := regexp_replace(srcstr     => l_source
                              ,pattern    => '\A(\s*PACKAGE\s+(\w+\.)?' || l_resolver_object_name || '\s+(AS|IS))'
                              ,replacestr => 'CREATE OR REPLACE \1' || chr(10) || chr(10) || '  -- %suite' || l_suite_desc ||
                                             l_suite_package || chr(10) || chr(10)
                              ,modifier   => 'i'
                              ,occurrence => 1);
  
    for rec in (select t.*
                  from all_procedures t
                 where t.owner = l_resolved_owner
                   and t.object_name = l_resolver_object_name
                   and t.procedure_name is not null
                   and upper(t.procedure_name) like upper(replace(a_package_prefix, '_', '\_') || '%') escape '\') loop
    
      l_repalce_pattern := case upper(rec.procedure_name)
                             when l_setup_proc then
                              chr(10) || '\2-- %beforeall' || chr(10) || '\1'
                             when l_teardown_proc then
                              chr(10) || '\2-- %afterall' || chr(10) || '\1'
                             else
                              chr(10) || '\2-- %test' || chr(10) || '\1'
                           end;
    
      l_source := regexp_replace(l_source
                                ,'^(( *)procedure\s+' || rec.procedure_name || ')'
                                ,l_repalce_pattern
                                ,modifier => 'im');
    
    end loop;
  
    if a_compile_flag then
      ut_utils.debug_log('Compiling package: ' || l_resolver_object_name);
      ut_utils.debug_log(l_source);
          
      execute immediate l_source;
    else
      dbms_output.put_line(l_source);
      dbms_output.put_line('/');
    end if;
    
    dbms_lob.freetemporary(l_source);
  
  end upgrade_v2_package_spec;
  
  procedure migrate_v2_packages(a_compile_flag boolean default true) is
    l_items_processed pls_integer := 0;
    l_items_succeeded pls_integer := 0;
    l_items_skipped pls_integer := 0;
    
    ex_compiled_with_errors exception;
    pragma exception_init(ex_compiled_with_errors,-24344);
  begin
    for rec in (select p.owner
                      ,p.name
                      ,p.description as package_desc
                      ,nvl(p.prefix, c.prefix) prefix
                      ,s.name suite_name
                      ,s.description as suite_desc
                      ,o.status
                  from ut_package p
                      ,ut_suite s
                      ,ut_config c
                      ,all_objects o
                 where p.id in (select max(p2.id) keep(dense_rank first order by p2.suite_id desc nulls last)  
                                  from ut_package p2 
                                 group by upper(p2.owner)
                                         ,upper(p2.name))
                   and p.suite_id = s.id(+)
                   and upper(p.owner) = upper(c.username(+))
                   and upper(p.owner) = o.owner
                   and upper(p.name) = o.object_name
                   and o.object_type in ('PACKAGE')) loop
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
          dbms_output.put_line('INVALID package ' || rec.owner || '.' || rec.name ||  ' was skipped');
          l_items_skipped := l_items_skipped +1;
        end if;
        
      exception 
        when ut_utils.ex_package_already_migrated then
          ut_utils.debug_log('[IGNORE] Package ' || rec.owner || '.' || rec.name || ' already migrated');
          if not a_compile_flag then
            dbms_output.put('--');
          end if;
          dbms_output.put_line('Package ' || rec.owner || '.' || rec.name ||  ' already migrated. Package is skipped');
          l_items_skipped := l_items_skipped +1;
        when ut_utils.ex_package_parsing_failed then
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

end ut_v2_migration;
/
