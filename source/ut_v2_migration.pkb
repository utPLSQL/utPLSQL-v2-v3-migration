create or replace package body ut_v2_migration is

  procedure upgrade_v2_package_spec(a_owner_name varchar2, a_packge_name varchar2, a_compile_flag boolean) is
    l_resolved_owner       varchar2(32 char);
    l_resolver_object_name varchar2(32 char);
    l_source               clob;
    l_prefix               varchar2(32 char);
    l_setup_proc           varchar2(32 char);
    l_teardown_proc        varchar2(32 char);
    l_repalce_pattern      varchar2(50);
    l_suite                ut_test_suite;
  begin
    l_resolved_owner       := a_owner_name;
    l_resolver_object_name := a_packge_name;
  
    ut_metadata.do_resolve(a_owner          => l_resolved_owner
                          ,a_object         => l_resolver_object_name);
  
    l_suite := ut_suite_manager.config_package(a_owner_name  => l_resolved_owner
                                              ,a_object_name => l_resolver_object_name);
  
    if l_suite is not null then
      raise_application_error(-20201, 'The package is already version 3 compatible');
    end if;
  
    l_prefix := regexp_substr(l_resolver_object_name, '[a-z][a-z0-9#$]*_', modifier => 'i');
  
    l_setup_proc    := upper(l_prefix || 'setup');
    l_teardown_proc := upper(l_prefix || 'teardown');
  
    l_source := ut_metadata.get_package_spec_source(l_resolved_owner, l_resolver_object_name);
  
    l_source := regexp_replace(srcstr     => l_source
                              ,pattern    => '^(\s*PACKAGE\s+(\w+\.)?' || l_resolver_object_name || '\s+(AS|IS))'
                              ,replacestr => 'CREATE OR REPLACE \1' || chr(10) || chr(10) || '  -- %suite' || chr(10) ||
                                             chr(10)
                              ,modifier   => 'i'
                              ,occurrence => 1);
  
    for rec in (select t.*
                  from all_procedures t
                 where t.owner = l_resolved_owner
                   and t.object_name = l_resolver_object_name
                   and t.procedure_name is not null
                   and t.procedure_name like replace(l_prefix, '_', '\_') || '%' escape '\') loop
    
      l_repalce_pattern := case upper(rec.procedure_name)
                             when l_setup_proc then
                              chr(10) || '\2-- %suitesetup' || chr(10) || '\1'
                             when l_teardown_proc then
                              chr(10) || '\2-- %suiteteardown' || chr(10) || '\1'
                             else
                              chr(10) || '\2-- %test' || chr(10) || '\1'
                           end;
    
      l_source := regexp_replace(l_source
                                ,'^(( *)procedure\s+' || rec.procedure_name || ')'
                                ,l_repalce_pattern
                                ,modifier => 'im');
    
    end loop;
  
    if a_compile_flag then
      ut_utils.debug_log(l_source);
          
      execute immediate l_source;
    else
      dbms_output.put_line(l_source);
    end if;
  
  end upgrade_v2_package_spec;

end ut_v2_migration;
/
