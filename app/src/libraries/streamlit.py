# Import libraries
from snowflake.snowpark.context import get_active_session
from snowflake.snowpark.functions import sum, col, when, max, lag
from snowflake.snowpark import Window
from datetime import timedelta
import altair as alt
import streamlit as st
import pandas as pd
import snowflake.permissions as permissions

##import plotly.express as px 
import datetime as dt

# Set page config
st.set_page_config(layout="wide")
# Get current session
session = get_active_session()

#TITRE
st.header("ACTIN TABLE COMPARISON")

st.subheader(":dart: COMPARE TABLES BETWEEN A SOURCE ENVIRONMENT AND A TARGET ENVIRONMENT")

st.write("----------------:one: Update settings file to set tables to compare")
st.write("----------------:two: Launch the tables comparison and save results in a new file")
st.write("----------------:three: Visualize and interpret results")


#PARTIE 1 MODIFIER LES TABLES A COMPARER EN INPUT
st.subheader(":wrench: 1 : SET THE LIST OF TABLES TO BE COMPARED")
st.write(" Informations required are the source (DATABASE_SOURCE, SCHEMA_SOURCE) and the target (DATABASE_CIBLE, SCHEMA_CIBLE) environments, as well as the table name (TABLE_NAME)")
st.write("DATE_SCOPE delimits the temporal scope with MIN_DATE and MAX_DATE bounds for both tables. If DATE_SCOPE is NULL, the entire table is used.")
  
#On affiche la table de paramétrage 
table_list="TABLE_LIST"
table_list_df=session.table(table_list).to_pandas()

#On permet à l'utilisateur de modifier la table de paramétrage
with st.form("table write"):
    df_edited=st.experimental_data_editor(table_list_df, use_container_width= True , num_rows="dynamic")
    write_to_snowflake=st.form_submit_button("UPDATE")

#Mise à jour dans Snowflake 
if write_to_snowflake:
    with st.spinner("UPDATING..."):
        try:
            session.write_pandas(df_edited, table_list, overwrite = True)
            session.sql('GRANT SELECT ON TABLE TABLE_LIST TO APPLICATION ROLE app_instance_role').collect()
        except:
            st.write('Error saving to table.')
    st.success("The input table has been successfully updated in Snowflake!")

st.divider()


#PARTIE 2 LANCER LA COMPARAISON DES TABLES
st.subheader(":telescope: 2 : LAUNCH TABLE COMPARISON")


#Création d'un suffixe datetime pour identifier la table résultats de manière unique 
current_time = dt.datetime.now() 
tb_result_default=str(current_time.year)+('0'+str(current_time.month))[-2:]+('0'+str(current_time.day))[-2:]+'_'+('0'+str(current_time.hour))[-2:]+('0'+str(current_time.minute))[-2:]+('0'+str(current_time.second))[-2:]

#On permet à l'utilisateur de changer le nom de la table résultats

col1, col2, col3 = st.columns(3)
with col1:
    tb_results_name = st.text_input( 'CHANGE THE TABLE NAME SUFFIX TO RECORD THE VARIOUS RESULTS :',value=tb_result_default)
    composed_query="""CREATE or REPLACE TABLE """+tb_results_name +""" AS SELECT * FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())) ORDER BY 1;"""
    with st.form("Proc stockées"):
        launch_proc_stock=st.form_submit_button("LAUNCH TABLE COMPARISON")



#Lancer les procedures stockées
#with st.form("Proc stockées"):
#    launch_proc_stock=st.form_submit_button("LANCER LA COMPARAISON DES TABLES")

if launch_proc_stock:
    with st.spinner("CALCULATION IN PROGRESS..."):

        df = session.sql("""call GET_DICTIONNARY_SOURCE('TABLE_LIST')""").collect()
        df = session.sql("CREATE or REPLACE TABLE SOURCE_DICTIONNARY AS SELECT * FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())) ORDER BY 1;").collect()
        
        #df = session.sql("""call GET_STATISTICS('SOURCE_DICTIONNARY')""").collect()
        #df = session.sql("CREATE or REPLACE TABLE SOURCE_STATISTICS AS SELECT * FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())) ORDER BY 1;").collect()

        
        #df = session.sql("""call GET_DICTIONNARY_CIBLE('TABLE_LIST','PC_ALTERYX_DB.INFORMATION_SCHEMA.COLUMNS')""").collect()
        #df = session.sql("CREATE or REPLACE TABLE CIBLE_DICTIONNARY AS SELECT * FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())) ORDER BY 1;").collect()
        
        #df = session.sql("""call GET_STATISTICS('CIBLE_DICTIONNARY')""").collect()
        #df = session.sql("CREATE or REPLACE TABLE CIBLE_STATISTICS AS SELECT * FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())) ORDER BY 1;").collect()
        
        #df = session.sql("""call COMPARE_STATISTICS('CIBLE_STATISTICS', 'SOURCE_STATISTICS')""").collect()
        #df = session.sql(composed_query).collect()

    st.success("Successfully run in Snowflake! Statistics ready for viewing! :point_down:")

st.divider()
