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
      l_suite_package := chr(10)||'  -- %suitepackage('||trim(a_parent_suite)||')';
    end if;
  
    l_source := regexp_replace(srcstr     => l_source
                              ,pattern    => '^(\s*PACKAGE\s+(\w+\.)?' || l_resolver_object_name || '\s+(AS|IS))'
                              ,replacestr => 'CREATE OR REPLACE \1' || chr(10) || chr(10) || '  -- %suite' || l_suite_desc ||
                                             l_suite_package || chr(10) || chr(10)
                              ,modifier   => 'i'
                              ,occurrence => 1);
  
    for rec in (select t.*
                  from all_procedures t
                 where t.owner = l_resolved_owner
                   and t.object_name = l_resolver_object_name
                   and t.procedure_name is not null
                   and t.procedure_name like replace(a_package_prefix, '_', '\_') || '%' escape '\') loop
    
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
      ut_utils.debug_log('Compiling package');
      ut_utils.debug_log(l_source);
          
      execute immediate l_source;
    else
      dbms_output.put_line(l_source);
    end if;
  
  end upgrade_v2_package_spec;
  
  procedure migrate_v2_packages(a_compile_flag boolean default true) is
  begin
    for rec in (select p.owner
                      ,p.name
                      ,p.description as package_desc
                      ,nvl(p.prefix, c.prefix) prefix
                      ,s.name suite_name
                      ,s.description as suite_desc
                  from ut_package p
                      ,ut_suite s
                      ,ut_config c
                 where p.id in (select max(p2.id) keep(dense_rank first order by p2.suite_id desc)  
                                  from ut_package p2 
                                 group by p2.owner,p2.name)
                   and p.suite_id = s.id(+)
                   and p.owner = c.username(+)) loop
      begin             
        ut_utils.debug_log('Migrating ' || rec.owner || '.' || rec.name);
        upgrade_v2_package_spec(a_owner_name     => rec.owner,
                                a_packge_name    => rec.name,
                                a_package_desc   => rec.package_desc,
                                a_package_prefix => rec.prefix,
                                a_parent_suite   => rec.suite_name,
                                a_compile_flag   => a_compile_flag);
                                     
       exception when ut_utils.ex_package_already_migrated then
         ut_utils.debug_log('[IGNORE] Package ' || rec.owner || '.' || rec.name || ' already migrated');
       end;
    end loop;
    
  end;

end ut_v2_migration;
/
