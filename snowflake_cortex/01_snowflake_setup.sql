-- inspired by https://quickstarts.snowflake.com/guide/getting_started_with_cortex_analyst_in_snowflake/index.html#1

USE ROLE sysadmin;

CREATE OR REPLACE DATABASE puppy_db;

CREATE OR REPLACE SCHEMA puppy_data;

CREATE OR REPLACE WAREHOUSE puppy_wh
    WAREHOUSE_SIZE = 'large'
    WAREHOUSE_TYPE = 'standard'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
COMMENT = 'warehouse for cortex puppy data analysis';

CREATE STAGE raw_data DIRECTORY = (ENABLE = TRUE);

-----

USE puppy_db.puppy_data;

USE warehouse puppy_wh;

CREATE OR REPLACE TABLE puppy_db.puppy_data.DAILY_WEIGHT (
	DATE DATE,
	WEIGHT_KG FLOAT
);

CREATE OR REPLACE TABLE puppy_db.puppy_data.HOURLY_ACTIVITY (
	ACTIVITY_TS TIMESTAMP,
	ACTIVITY_TYPE VARCHAR(100),
	ACTIVITY_MIN FLOAT
);
