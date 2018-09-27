set heading off
set feedback off
def component = &&1
exec dbms_output.put_line('Installing component '||upper(regexp_substr('&&component','\/(\w*)\.',1,1,'i',1)));
@@&&component
show errors
exec dbms_output.put_line('--------------------------------------------------------------');
undef component
