-- #########################################
-- PACKAGE SETUP
-- #########################################

CREATE APPLICATION PACKAGE IDENTIFIER('"NATIVE_APP_QUICKSTART_PACKAGE"') COMMENT = '' DISTRIBUTION = 'INTERNAL';
USE DATABASE NATIVE_APP_QUICKSTART_PACKAGE;

CREATE OR REPLACE SCHEMA NATIVE_APP_QUICKSTART_SCHEMA;
USE SCHEMA NATIVE_APP_QUICKSTART_SCHEMA;

-- we will upload our project files here, directly into our app package
CREATE OR REPLACE STAGE NATIVE_APP_QUICKSTART_STAGE 
	DIRECTORY = ( ENABLE = true ) 
	COMMENT = '';

CREATE OR REPLACE WAREHOUSE NATIVE_APP_QUICKSTART_WH WAREHOUSE_SIZE=SMALL INITIALLY_SUSPENDED=TRUE;

-- this database is used to store our test data
CREATE OR REPLACE DATABASE NATIVE_APP_QUICKSTART_DB;
USE DATABASE NATIVE_APP_QUICKSTART_DB;

CREATE OR REPLACE SCHEMA NATIVE_APP_QUICKSTART_SCHEMA;
USE SCHEMA NATIVE_APP_QUICKSTART_SCHEMA;

CREATE OR REPLACE TABLE MFG_ORDERS (
  order_id NUMBER(38,0), 
  material_name VARCHAR(60),
  supplier_name VARCHAR(60),
  quantity NUMBER(38,0),
  cost FLOAT,
  process_supply_day NUMBER(38,0)
);

-- Load app/data/orders_data.csv using Snowsight

CREATE OR REPLACE TABLE MFG_SHIPPING (
  order_id NUMBER(38,0), 
  ship_order_id NUMBER(38,0),
  status VARCHAR(60),
  lat FLOAT,
  lon FLOAT,
  duration NUMBER(38,0)
);

-- Load app/data/shipping_data.csv using Snowsight

CREATE OR REPLACE TABLE MFG_SITE_RECOVERY (
  event_id NUMBER(38,0), 
  recovery_weeks NUMBER(38,0),
  lat FLOAT,
  lon FLOAT
);

-- Load app/data/site_recovery_data.csv using Snowsight

-- ################################################################
-- Create SHARED_CONTENT_SCHEMA to share in the application package
-- ################################################################
use database NATIVE_APP_QUICKSTART_PACKAGE;
create schema shared_content_schema;

use schema shared_content_schema;
create or replace view MFG_SHIPPING as select * from NATIVE_APP_QUICKSTART_DB.NATIVE_APP_QUICKSTART_SCHEMA.MFG_SHIPPING;

grant usage on schema shared_content_schema to share in application package NATIVE_APP_QUICKSTART_PACKAGE;
grant reference_usage on database NATIVE_APP_QUICKSTART_DB to share in application package NATIVE_APP_QUICKSTART_PACKAGE;
grant select on view MFG_SHIPPING to share in application package NATIVE_APP_QUICKSTART_PACKAGE;

-- ################################################################
-- TEST APP LOCALLY
-- ################################################################

USE DATABASE NATIVE_APP_QUICKSTART_DB;
USE SCHEMA NATIVE_APP_QUICKSTART_SCHEMA;

-- This executes "setup.sql" linked in the manifest.yml; This is also what gets executed when installing the app
CREATE APPLICATION NATIVE_APP_QUICKSTART_APP FROM application package NATIVE_APP_QUICKSTART_PACKAGE using version V1 patch 0;
-- For example, CREATE APPLICATION LEAD_TIME_OPTIMIZER_APP FROM application package LEAD_TIME_OPTIMIZER_PKG using version V1 patch 0;

-- At this point you should see and run the app NATIVE_APP_QUICKSTART_APP listed under Apps
SHOW APPLICATION PACKAGES;
