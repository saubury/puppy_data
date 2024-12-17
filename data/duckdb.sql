INSTALL postgres;
LOAD postgres;

.open ha_local.db

ATTACH 'dbname=hass_db port=5432 user=ha_user host=192.168.1.30' AS db (TYPE POSTGRES, READ_ONLY, SCHEMA 'hass_schema');

-- abouyt 5 min
CREATE OR REPLACE TABLE ha_states
AS
SELECT *
FROM db.hass_schema.states;

CREATE OR REPLACE TABLE ha_states_meta
AS
SELECT *
FROM db.hass_schema.states_meta;


CREATE OR REPLACE TABLE ha_state_events
AS
SELECT sm.entity_id 
, st.state 
, to_timestamp(st.last_updated_ts) as last_updated_ts
FROM ha_states st
LEFT JOIN ha_states_meta sm ON st.metadata_id = sm.metadata_id
where sm.entity_id in (
    -- temperature
    'sensor.lumi_lumi_weather_501f0707_temperature'
    -- RSSI
    , 'sensor.esp_barn_ble_fitbark_rssi_value'
    -- door
    , 'binary_sensor.balcony_sliding_door_fded288b_ias_zone'
    -- weight
    , 'sensor.esp_barn_hx711_value'
    -- activity
    , 'sensor.fitbark_activityseries_min_rest', 'sensor.fitbark_activityseries_min_active', 'sensor.fitbark_activity_series_min_play_2'
)
;


SELECT last_updated_ts
, strftime(last_updated_ts, '%d/%m/%Y') as date
, entity_id
, state 
FROM ha_state_events
WHERE last_updated_ts > TIMESTAMPTZ '1992-03-22 01:02:03'
ORDER BY last_updated_ts, entity_id;


COPY (
    SELECT strftime(last_updated_ts, '%d/%m/%Y') as date
    , entity_id
    , state 
    FROM ha_state_events
    WHERE last_updated_ts > TIMESTAMPTZ '1992-03-22 01:02:03'
    ORDER BY last_updated_ts, entity_id
)
TO 'ha_state_events.csv';



CREATE OR REPLACE TABLE puppy_weight AS
SELECT last_updated_ts
, cast(state as double) AS weight_kg
FROM ha_state_events
where entity_id = 'sensor.esp_barn_hx711_value'
and state not in ('unavailable', 'unknown');

COPY
(
    WITH cte AS
    (
        SELECT date_trunc('day', last_updated_ts) AS last_updated_ts
        , round(avg(weight_kg), 2) AS weight_kg
        FROM puppy_weight 
        WHERE weight_kg BETWEEN 4 AND 20
        GROUP BY 1
        ORDER BY 1
    )
    SELECT strftime(last_updated_ts, '%d/%m/%Y') as date
    , weight_kg
    FROM cte
)
TO 'daily_weight.csv';


-- hourly_activity.csv

COPY
(
    SELECT cast(datetrunc('hour', last_updated_ts) - interval 1 hour as timestamp) as ACTIVITY_TS
    , case when entity_id='sensor.fitbark_activityseries_min_rest' then 'rest' 
        when entity_id='sensor.fitbark_activityseries_min_active' then 'active'
        when entity_id='sensor.fitbark_activity_series_min_play_2' then 'play'
        else 'unknown' end as ACTIVITY_TYPE
    , TRY_CAST(state AS INTEGER) as ACTIVITY_MIN
    FROM ha_state_events
    WHERE entity_id in ('sensor.fitbark_activityseries_min_rest', 'sensor.fitbark_activityseries_min_active', 'sensor.fitbark_activity_series_min_play_2')
    ORDER BY last_updated_ts, entity_id
) TO 'hourly_activity.csv';



