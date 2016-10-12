create or replace package ut_v2_migration is

  /*
    procedure: upgrade_v2_package_spec
    
    conversta v2 package specification to v3 annotated package leaving all the procedures names the same
    only annotations are added
  */
  --procedure upgrade_v2_package_spec(a_owner_name varchar2, a_packge_name varchar2, a_compile_flag boolean);
  procedure migrate_v2_packages(a_compile_flag boolean default true);

end ut_v2_migration;
/
