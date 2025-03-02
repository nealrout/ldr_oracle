CREATE OR REPLACE FUNCTION get_facility(
    p_user_id NUMBER DEFAULT NULL,
    p_source_ts TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    p_target_ts TIMESTAMP WITH TIME ZONE DEFAULT NULL
) RETURN facility_table PIPELINED
IS
BEGIN
    FOR rec IN (
		SELECT
			ac.account_nbr, f.facility_nbr, f.facility_code, f.facility_name, f.create_ts, f.update_ts
		FROM facility f
	JOIN userfacility uf on f.id = uf.facility_id
	JOIN account ac ON f.account_id = ac.Id
	WHERE 
		(
			(p_source_ts IS NOT NULL AND f.update_ts >= p_source_ts)
			OR 
			p_source_ts IS NULL
		)
		AND
		(
			(p_target_ts IS NOT NULL AND f.update_ts <= p_target_ts)
			OR
			p_target_ts IS NULL
		)
		AND
			(uf.user_id = p_user_id OR p_user_id is null)
    ) LOOP
        PIPE ROW(facility_record(
            rec.account_nbr, rec.facility_nbr, rec.facility_code, rec.facility_name, rec.create_ts, rec.update_ts
        ));
    END LOOP;
END;
/
CREATE OR REPLACE FUNCTION get_facility_by_json(
    p_jsonb CLOB,
    p_user_id NUMBER DEFAULT NULL
) RETURN facility_table PIPELINED
IS
	v_count NUMBER;
BEGIN
    FOR rec IN (
        /* FOR TESTING */
    /*
        WITH json_data AS (
            SELECT '{
		   "account_nbr": [
		       "ACCT_NBR_10"
		   ],
		   "facility_code": [
		       "US_TEST_10"
		   ],
		   "facility_name": [
		       "TEST FACILITY 10",
		       "TEST FACILITY 18"
		   ],
		   "facility_nbr": [
		       "FAC_NBR_10",
		       "FAC_NBR_02"
		   ]
		}' AS json_val
	*/
        WITH json_data as (SELECT p_jsonb as json_val
            FROM dual
        ),
        cte_parsed_json AS (
            SELECT j.*
            FROM json_data cte,
            JSON_TABLE(cte.json_val, '$' 
                COLUMNS (
                    NESTED PATH '$.account_nbr[*]' COLUMNS (account_nbr VARCHAR2(255) PATH '$'),
                    NESTED PATH '$.facility_nbr[*]' COLUMNS (facility_nbr VARCHAR2(255) PATH '$'),
                    NESTED PATH '$.facility_code[*]' COLUMNS (facility_code VARCHAR2(255) PATH '$'),
                    NESTED PATH '$.facility_name[*]' COLUMNS (facility_name VARCHAR2(255) PATH '$')
                )
            ) j
        )
--       SELECT * FROM cte_parsed_json;
       	SELECT
			acc.account_nbr, fac.facility_nbr, fac.facility_code, fac.facility_name, fac.create_ts, fac.update_ts
		FROM account acc
		JOIN facility fac ON acc.id = fac.account_id 
		JOIN userfacility uf on fac.id = uf.facility_id
		WHERE 
            (EXISTS (SELECT 1 FROM cte_parsed_json p WHERE acc.account_nbr = p.account_nbr) OR (SELECT COUNT(*) FROM cte_parsed_json WHERE account_nbr IS NOT NULL) = 0)
            AND (EXISTS (SELECT 1 FROM cte_parsed_json p WHERE fac.facility_nbr = p.facility_nbr) OR (SELECT COUNT(*) FROM cte_parsed_json WHERE facility_nbr IS NOT NULL) = 0)
            AND (EXISTS (SELECT 1 FROM cte_parsed_json p WHERE fac.facility_code = p.facility_code) OR (SELECT COUNT(*) FROM cte_parsed_json WHERE facility_code IS NOT NULL) = 0)
            AND (EXISTS (SELECT 1 FROM cte_parsed_json p WHERE fac.facility_name = p.facility_name) OR (SELECT COUNT(*) FROM cte_parsed_json WHERE facility_name IS NOT NULL) = 0)
            AND (uf.user_id = p_user_id OR p_user_id is null)
    ) LOOP
        PIPE ROW(facility_record(
            rec.account_nbr, rec.facility_nbr, rec.facility_code, rec.facility_name, rec.create_ts, rec.update_ts
        ));
    END LOOP;
END;
/
CREATE OR REPLACE PROCEDURE upsert_facility_from_json(
    p_json_in CLOB,
    p_channel_name VARCHAR2,
    p_user_id NUMBER,
    p_parent_channel_name VARCHAR2 DEFAULT NULL
)
IS
    v_count NUMBER;
	v_unknown_account_id NUMBER(19,0);
BEGIN
    /*  SAMPLE p_json_in
        ' [
	        {
	            "account_nbr": "ACCT_NBR_01",
	            "account_code": "US_ACCT_01",
	            "account_name": "account 01"
	        },
	        {
	            "account_nbr": "ACCT_NBR_02",
	            "account_code": "US_ACCT_02",
	            "account_name": "account 02"
	        }
		]
		'
    */

    SELECT id INTO v_unknown_account_id
    FROM account
    WHERE account_nbr = 'UNKNOWN';
    
    -- Stage data
    INSERT INTO temp_stage_facility (id, target_account_id, account_nbr, facility_nbr, facility_code, facility_name)
    SELECT acc.id, 
    	   COALESCE(target_acc.id, acc.id, v_unknown_account_id) as target_account_id,
           COALESCE(j.account_nbr, acc.account_nbr), 
           COALESCE(j.facility_nbr, f.facility_nbr), 
           COALESCE(j.facility_code, f.facility_code),
           COALESCE(j.facility_name, f.facility_name)
    FROM (
        SELECT * FROM JSON_TABLE(p_json_in, '$[*]' 
            COLUMNS (
                account_nbr VARCHAR2(255) PATH '$.account_nbr',
                facility_nbr VARCHAR2(255) PATH '$.facility_nbr',
                facility_code VARCHAR2(255) PATH '$.facility_code',
                facility_name VARCHAR2(255) PATH '$.facility_name'
            )
        )
    ) j
    LEFT JOIN facility f on j.facility_nbr = f.facility_nbr
 	LEFT JOIN account acc on f.account_id = acc.id
 	LEFT JOIN account target_acc on j.account_nbr = target_acc.account_nbr;
  
	-- remove upserts where the user does not have access to the facility
	IF p_user_id IS NOT NULL THEN
 		DELETE from temp_stage_facility t
 		WHERE t.id IS NOT NULL 
 			AND	NOT EXISTS (select 1 FROM userfacility uf WHERE t.id = uf.facility_id AND uf.user_id = p_user_id);
	END IF;
    
    MERGE INTO facility target
    USING temp_stage_facility source
    ON (target.id = source.id)
    WHEN MATCHED THEN
        UPDATE SET 
            target.account_id = source.target_account_id,
            target.facility_code = source.facility_code,
            target.facility_name = source.facility_name
    WHEN NOT MATCHED THEN
        INSERT (account_id, facility_nbr, facility_code, facility_name, create_ts)
        VALUES (source.target_account_id, source.facility_nbr, source.facility_code, SOURCE.facility_name, SYSTIMESTAMP);

 	COMMIT;

--     -- Raise event for consumers
--     FOR account_nbr, facility_nbr IN
--         SELECT acc.account_nbr, f.facility_nbr 
-- 		FROM facility f
-- 		JOIN account acc on f.account_id = acc.id
-- 		JOIN update_stage t ON f.facility_nbr = t.facility_nbr
--     LOOP
-- 		-- insert account now that we may have attached new facilities
-- 		INSERT INTO event_notification_buffer(channel, payload, create_ts)
-- 		VALUES (p_parent_channel_name, account_nbr, now());
--         PERFORM pg_notify(p_parent_channel_name, account_nbr);
		
-- 		-- insert facility
-- 		INSERT INTO event_notification_buffer(channel, payload, create_ts)
-- 		VALUES (p_channel_name, facility_nbr, now());
--         PERFORM pg_notify(p_channel_name, facility_nbr);
--     END LOOP;
    
END;
/
