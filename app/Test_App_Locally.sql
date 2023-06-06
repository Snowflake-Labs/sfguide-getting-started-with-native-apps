-- #########################################
-- DB SETUP
-- #########################################

USE DATABASE <YOUR_DB>;
USE SCHEMA <YOUR_SCHEMA>;

CREATE OR REPLACE TABLE MFG_ORDERS (
  order_id NUMBER(38,0), 
  material_name VARCHAR(60),
  supplier_name VARCHAR(60),
  quantity NUMBER(38,0),
  cost FLOAT,
  process_supply_day NUMBER(38,0)
);

-- Load orders_data.csv using Snowsight

CREATE OR REPLACE TABLE MFG_SHIPPING (
  order_id NUMBER(38,0), 
  ship_order_id NUMBER(38,0),
  status VARCHAR(60),
  lat FLOAT,
  lon FLOAT,
  duration NUMBER(38,0)
);

-- Load shipping_data.csv using Snowsight

CREATE OR REPLACE TABLE MFG_SITE_RECOVERY (
  event_id NUMBER(38,0), 
  recovery_weeks NUMBER(38,0),
  lat FLOAT,
  lon FLOAT
);

-- Load site_recovery_data.csv using Snowsight

################################################################
Create SHARED_CONTENT_SCHEMA to share in the application package
################################################################
use database <APPLICATION_PKG_NAME>;
create schema shared_content_schema;

use schema shared_content_schema;
create or replace view MFG_SHIPPING as select * from <YOUR_DB>.<YOUR_SCHEMA>.MFG_SHIPPING;

grant usage on schema shared_content_schema to share in application package <APPLICATION_PKG_NAME>;
grant reference_usage on database <YOUR_DB> to share in application package <APPLICATION_PKG_NAME>;
grant select on view MFG_SHIPPING to share in application package <APPLICATION_PKG_NAME>;

-- ################################################################
-- TEST APP LOCALLY
-- ################################################################

USE DATABASE <YOUR_DB>;
USE SCHEMA <YOUR_SCHEMA>;

-- This executes"setup.sql" from the manifest.yml; This is also what gets executed when installing the app
CREATE APPLICATION <APPLICATION_NAME> FROM application package <APPLICATION_PKG_NAME> using <YOUR_CODE_FILES_STAGE_NAME/folder>;

USE DATABASE <YOUR_DB>;
USE SCHEMA <YOUR_SCHEMA>;
GRANT USAGE on database DASH_DB to application <APPLICATION_NAME>;
GRANT USAGE on schema DASH_SCHEMA to application <APPLICATION_NAME>;
GRANT SELECT on MFG_ORDERS to application <APPLICATION_NAME>;
GRANT SELECT on MFG_SITE_RECOVERY to application <APPLICATION_NAME>;

-- At this point you should see and run the app <APPLICATION_NAME> listed under Apps