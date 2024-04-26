-- ==========================================
-- This script runs when the app is installed 
-- ==========================================

-- Create Application Role 
create application role if not exists app_instance_role;


--Creation du shcema app_instance_schema
create or alter versioned schema app_instance_schema;
grant usage on schema app_instance_schema to application role app_instance_role;


--La procedure sotckée UPDATE_REFERENCE : création et droits 
create or replace procedure app_instance_schema.update_reference(ref_name string, operation string, ref_or_alias string)
returns string
language sql
as $$
begin
  case (operation)
    when 'ADD' then
       select system$set_reference(:ref_name, :ref_or_alias);
    when 'REMOVE' then
       select system$remove_reference(:ref_name, :ref_or_alias);
    when 'CLEAR' then
       select system$remove_all_references();
    else
       return 'Unknown operation: ' || operation;
  end case;
  return 'Success';
end;
$$;

--grant usage
grant usage on procedure app_instance_schema.update_reference(string, string, string) to application role app_instance_role;



--Les procédures stockées GET_DICTIONNARY_CIBLE, GET_DICTIONNARY_SOURCE, COMPARE_STATISTICS, GET_STATISTICS  : création et droits
CREATE OR REPLACE PROCEDURE app_instance_schema.GET_DICTIONNARY_SOURCE(table_list string, information_schema_columns string)
RETURNS TABLE ()
LANGUAGE SQL
EXECUTE AS OWNER
AS 'DECLARE
        res RESULTSET DEFAULT (
        with 
        t1 as (
          select * from IDENTIFIER(:table_list)
        )
        ,t2 as (
          select TABLE_CATALOG,TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME ,IS_NULLABLE ,DATA_TYPE from IDENTIFIER(:information_schema_columns)
          
        )
       select t2.*,t1.min_date,t1.max_date, t1.date_scope from t1
        inner join t2
        on t1.TABLE_NAME=t2.TABLE_NAME and 
        t1.schema_source=t2.TABLE_SCHEMA);
        
    BEGIN
        return table(res);
END';

CREATE OR REPLACE PROCEDURE app_instance_schema.GET_DICTIONNARY_CIBLE(table_list string)
RETURNS TABLE ()
LANGUAGE SQL
EXECUTE AS OWNER
AS 'DECLARE
        res RESULTSET DEFAULT (
        with 
        t1 as (
          select * from IDENTIFIER(:table_list)
        )
        ,t2 as (
          select TABLE_CATALOG,TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME ,IS_NULLABLE ,DATA_TYPE from reference('information_schema')
          
        )
       select t2.*,t1.min_date,t1.max_date, t1.date_scope from t1
        inner join t2
        on t1.TABLE_NAME=t2.TABLE_NAME and 
        t1.schema_cible=t2.TABLE_SCHEMA);
        
    BEGIN
        return table(res);
END';


CREATE OR REPLACE PROCEDURE app_instance_schema.COMPARE_STATISTICS(table_prod_statistics string, table_dev_statistics string)
RETURNS TABLE ()
LANGUAGE SQL
EXECUTE AS OWNER
AS 'DECLARE
        res RESULTSET DEFAULT 
        (
        
        select ''PROD'' as source, 
        iff(not(a.DATA_TYPE=b.DATA_TYPE),1, 0)  as data_type_issue, 
         iff(not(a.UNIQUE_VALUES=b.UNIQUE_VALUES),1, 0) as unique_values_issue, 
         iff(not(a.MAX_LENGTH=b.MAX_LENGTH and a.MIN_LENGTH=b.MIN_LENGTH  ),1, 0) as length_issue,
         iff(not(a.SUM_VALUE=b.SUM_VALUE),1, 0) as sum_issue,
         iff(not(a.MIN_VALUE=b.MIN_VALUE and a.MIN_DATE=b.MIN_DATE),1, 0) as min_issue, 
        iff(not(a.MAX_VALUE=b.MAX_VALUE and a.MAX_DATE=b.MAX_DATE),1, 0) as max_issue,  
        a.*
    from IDENTIFIER(:table_prod_statistics) a inner join IDENTIFIER(:table_dev_statistics) b
                on a.TABLE_NAME=b.TABLE_NAME and 
                    a.COLUMN_NAME=b.COLUMN_NAME
        union all 
        
        select ''DEV'' as source,  
        iff(not(a.DATA_TYPE=b.DATA_TYPE),1, 0)  as data_type_issue, 
         iff(not(a.UNIQUE_VALUES=b.UNIQUE_VALUES),1, 0) as unique_values_issue, 
         iff(not(a.MAX_LENGTH=b.MAX_LENGTH and a.MIN_LENGTH=b.MIN_LENGTH  ),1, 0) as length_issue,
         iff(not(a.SUM_VALUE=b.SUM_VALUE),1, 0) as sum_issue,
         iff(not(a.MIN_VALUE=b.MIN_VALUE and a.MIN_DATE=b.MIN_DATE),1, 0) as min_issue, 
        iff(not(a.MAX_VALUE=b.MAX_VALUE and a.MAX_DATE=b.MAX_DATE),1, 0) as max_issue,  
        a.*
    from IDENTIFIER(:table_dev_statistics) a inner join IDENTIFIER(:table_prod_statistics) b
                on a.TABLE_NAME=b.TABLE_NAME and 
                    a.COLUMN_NAME=b.COLUMN_NAME
               
            order by table_name, column_name
          );
        
    BEGIN
        return table(res);
END';



CREATE OR REPLACE PROCEDURE app_instance_schema.GET_STATISTICS(dictionnary_table string)
RETURNS TABLE ()
LANGUAGE SQL
EXECUTE AS OWNER
AS 'DECLARE
        sql string;
        final_sql := '''';
        res RESULTSET DEFAULT (SELECT * FROM IDENTIFIER(:dictionnary_table));
        c1 cursor for res;
    BEGIN
        FOR record in c1 do
        
                if (record.DATA_TYPE in (''NUMBER'',''DECIMAL'', ''NUMERIC'', ''INT'', ''INTEGER'', ''BIGINT'', ''SMALLINT'', ''TINYINT'', ''BYTEINT'', ''FLOAT'', ''FLOAT4'',''FLOAT8'',''DOUBLE'', ''DOUBLE PRECISION'',''REAL'')) 
                    then 
                    sql := ''SELECT ''''''||record.TABLE_NAME||'''''' as TABLE_NAME,  ''''''||REPLACE(record.COLUMN_NAME,'''''''', '''''''''''')||'''''' as COLUMN_NAME, ''''''||record.DATA_TYPE||'''''' as DATA_TYPE, count( distinct "''||record.COLUMN_NAME||''") as UNIQUE_VALUES,  null as MAX_LENGTH, null as MIN_LENGTH, SUM("''||record.COLUMN_NAME||''") as SUM_VALUE, MAX("''||record.COLUMN_NAME||''") as MAX_VALUE,  MIN("''||record.COLUMN_NAME||''") as MIN_VALUE,null as MAX_DATE, null as MIN_DATE FROM ''||record.TABLE_CATALOG||''.''||record.TABLE_SCHEMA||''."''||record.TABLE_NAME||''" '';
                
                   elseif (record.DATA_TYPE in (''DATE'',''DATETIME'',''TIME'',''TIMESTAMP_LTZ'',''TIMESTAMP_NTZ'',''TIMESTAMP_TZ'')) then 
                    sql := ''SELECT ''''''||record.TABLE_NAME||'''''' as TABLE_NAME,  ''''''||REPLACE(record.COLUMN_NAME,'''''''', '''''''''''')||'''''' as COLUMN_NAME, ''''''||record.DATA_TYPE||'''''' as DATA_TYPE, count(distinct "''||record.COLUMN_NAME||''") as UNIQUE_VALUES, null as MAX_LENGTH, null as MIN_LENGTH, null as SUM_VALUE, null as MAX_VALUE, null as MIN_VALUE, MAX("''||record.COLUMN_NAME||''") as MAX_DATE, MIN("''||record.COLUMN_NAME||''") as MIN_DATE FROM ''||record.TABLE_CATALOG||''.''||record.TABLE_SCHEMA||''."''||record.TABLE_NAME||''" ''; 

                     else
                    sql := ''SELECT ''''''||record.TABLE_NAME||'''''' as TABLE_NAME, ''''''||REPLACE(record.COLUMN_NAME,'''''''', '''''''''''')||'''''' as COLUMN_NAME, ''''''||record.DATA_TYPE||'''''' as DATA_TYPE, count( distinct "''||record.COLUMN_NAME||''") as UNIQUE_VALUES, MAX(LEN("''||record.COLUMN_NAME||''")) as MAX_LENGTH, MIN(LEN("''||record.COLUMN_NAME||''")) as MIN_LENGTH, null as SUM_VALUE, null as MAX_VALUE, null as MIN_VALUE,  null as MAX_DATE, null as MIN_DATE FROM ''||record.TABLE_CATALOG||''.''||record.TABLE_SCHEMA||''."''||record.TABLE_NAME||''" '';
                    
                    end if;

                 if(record.DATE_SCOPE is not null) then 
                    sql := sql || ''where "''||record.DATE_SCOPE||''" between ''''''||record.MIN_DATE||'''''' and ''''''||record.MAX_DATE||'''''' ''  ;end if;

                
                if(final_sql<>'''')then 
                    final_sql := final_sql || '' UNION ALL '';
                end if;
                
                final_sql := final_sql || sql;
        
        END FOR;
    res := (EXECUTE IMMEDIATE :final_sql);
    RETURN TABLE (res);
end';


-- grant usage
grant usage on procedure app_instance_schema.GET_DICTIONNARY_SOURCE(string) to application role app_instance_role;
grant usage on procedure app_instance_schema.GET_DICTIONNARY_CIBLE(string,string) to application role app_instance_role;
grant usage on procedure app_instance_schema.COMPARE_STATISTICS(string, string) to application role app_instance_role;
grant usage on procedure app_instance_schema.GET_STATISTICS(string) to application role app_instance_role;


-- TABLE DE PARAMETRAGE : Creer le schema INPUT puis la table table_list 

CREATE or replace TABLE app_instance_schema.TABLE_LIST (
  table_name VARCHAR(100) DEFAULT NULL,
  database_source VARCHAR(100) DEFAULT NULL,
    schema_source VARCHAR(100) DEFAULT NULL,
    database_cible VARCHAR(100) DEFAULT NULL,
    schema_cible VARCHAR(100) DEFAULT NULL,
    date_scope VARCHAR(100) DEFAULT NULL,
    min_date DATE DEFAULT NULL,
    max_date DATE DEFAULT NULL
);

INSERT INTO app_instance_schema.TABLE_LIST
  VALUES
  ('Hypermarche_Achats','PC_ALTERYX_DB','HYPERMARCHE_DEV','PC_ALTERYX_DB','HYPERMARCHE','Date de commande','2019-01-01','2022-12-31'),
  ('Hypermarche_Personnes','PC_ALTERYX_DB','HYPERMARCHE_DEV','PC_ALTERYX_DB','HYPERMARCHE',null,null,null),
  ('Hypermarche_Retours','PC_ALTERYX_DB','HYPERMARCHE_DEV','PC_ALTERYX_DB','HYPERMARCHE',null,null,null);

GRANT SELECT ON TABLE app_instance_schema.TABLE_LIST TO APPLICATION ROLE app_instance_role;


-- CREATION DE L'APPLICATION STEAMLIT
create or replace streamlit app_instance_schema.streamlit from '/libraries' main_file='streamlit.py';

grant usage on streamlit app_instance_schema.streamlit to application role app_instance_role;
