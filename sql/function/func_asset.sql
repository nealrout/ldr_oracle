CREATE OR REPLACE FUNCTION get_asset(
    p_user_id NUMBER DEFAULT NULL,
    p_source_ts TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    p_target_ts TIMESTAMP WITH TIME ZONE DEFAULT NULL
) RETURN asset_table PIPELINED
IS
BEGIN
    FOR rec IN (
		SELECT 
			acc.account_nbr, facility.facility_nbr, asset.asset_nbr, asset.sys_id, asset.asset_code, asset.status_code, asset.create_ts, asset.update_ts
		FROM 
			asset asset
	    	JOIN facility facility on asset.facility_id = facility.id
			JOIN userfacility uf on facility.id = uf.facility_id
			JOIN account acc on facility.account_id = acc.id
		WHERE 
			(
				(p_source_ts IS NOT NULL AND asset.update_ts >= p_source_ts)
				OR 
				p_source_ts IS NULL
			)
			AND
			(
				(p_target_ts IS NOT NULL AND asset.update_ts <= p_target_ts)
				OR
				p_target_ts IS NULL
			)
			AND
				(uf.user_id = p_user_id OR p_user_id is null)
    ) LOOP
        PIPE ROW(asset_record(
            rec.account_nbr, rec.facility_nbr, rec.asset_nbr, rec.sys_id, rec.asset_code, rec.status_code, rec.create_ts, rec.update_ts
        ));
    END LOOP;
END;
/
CREATE OR REPLACE FUNCTION get_asset_by_json(
    p_jsonb CLOB,
    p_user_id NUMBER DEFAULT NULL
) RETURN asset_table PIPELINED
IS
	v_count NUMBER;
BEGIN
    FOR rec IN (
        /* FOR TESTING */
    /*
        WITH json_data AS (
            SELECT '{
			    "account_nbr": ["ACCT_NBR_09"]
			    ,"facility_nbr": ["FAC_NBR_09", "FAC_NBR_20"]
			    ,"asset_nbr": ["asset_nbr_82", "asset_nbr_83"]
			    ,"asset_code": ["asset_code_82", "asset_code_83"]
			    ,"sys_id": ["system_03","system_02"]
			    ,"status_code": ["UNKNOWN"]
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
                    NESTED PATH '$.asset_nbr[*]' COLUMNS (asset_nbr VARCHAR2(255) PATH '$'),
                    NESTED PATH '$.sys_id[*]' COLUMNS (sys_id VARCHAR2(255) PATH '$'),
                    NESTED PATH '$.asset_code[*]' COLUMNS (asset_code VARCHAR2(255) PATH '$'),
                    NESTED PATH '$.status_code[*]' COLUMNS (status_code VARCHAR2(255) PATH '$')
                )
            ) j
        )
--       SELECT * FROM cte_parsed_json;
       		SELECT
				acc.account_nbr, fac.facility_nbr, a.asset_nbr, a.sys_id, a.asset_code, a.status_code, a.create_ts, a.update_ts
			FROM account acc
			JOIN facility fac ON acc.id = fac.account_id 
			JOIN asset a ON fac.id = a.facility_id 
			JOIN userfacility uf on fac.id = uf.facility_id
			WHERE 
            (EXISTS (SELECT 1 FROM cte_parsed_json p WHERE acc.account_nbr = p.account_nbr) OR (SELECT COUNT(*) FROM cte_parsed_json WHERE account_nbr IS NOT NULL) = 0)
            AND (EXISTS (SELECT 1 FROM cte_parsed_json p WHERE fac.facility_nbr = p.facility_nbr) OR (SELECT COUNT(*) FROM cte_parsed_json WHERE facility_nbr IS NOT NULL) = 0)
            AND (EXISTS (SELECT 1 FROM cte_parsed_json p WHERE a.asset_nbr = p.asset_nbr) OR (SELECT COUNT(*) FROM cte_parsed_json WHERE asset_nbr IS NOT NULL) = 0)
            AND (EXISTS (SELECT 1 FROM cte_parsed_json p WHERE a.sys_id = p.sys_id) OR (SELECT COUNT(*) FROM cte_parsed_json WHERE sys_id IS NOT NULL) = 0)
            AND (EXISTS (SELECT 1 FROM cte_parsed_json p WHERE a.asset_code = p.asset_code) OR (SELECT COUNT(*) FROM cte_parsed_json WHERE asset_code IS NOT NULL) = 0)
            AND (EXISTS (SELECT 1 FROM cte_parsed_json p WHERE a.status_code = p.status_code) OR (SELECT COUNT(*) FROM cte_parsed_json WHERE status_code IS NOT NULL) = 0)
            AND (uf.user_id = p_user_id OR p_user_id is null)
    ) LOOP
        PIPE ROW(asset_record(
            rec.account_nbr, rec.facility_nbr, rec.asset_nbr, rec.sys_id, rec.asset_code, rec.status_code, rec.create_ts, rec.update_ts
        ));
    END LOOP;
END;
/
CREATE OR REPLACE PROCEDURE upsert_asset_from_json(
    p_json_in CLOB,
    p_channel_name VARCHAR2,
    p_user_id NUMBER,
    p_parent_channel_name VARCHAR2 DEFAULT NULL
)
IS
    v_count NUMBER;
	v_unknown_facility_id NUMBER(19,0);
BEGIN
    /*  SAMPLE p_json_in
        ' [
		    {
		        "asset_nbr": "asset_01",
		        "facility_nbr": "FAC_NBR_01",
		        "sys_id": "system_01",
		        "asset_code": "asset_code_01"
		    },
		    {
		        "asset_nbr": "asset_02",
		        "facility_nbr": "FAC_NBR_01",
		        "sys_id": "system_02",
		        "asset_code": "asset_code_02"
		    },
		    {
		        "asset_nbr": "asset_03",
		        "facility_nbr": "FAC_NBR_01",
		        "sys_id": "system_03",
		        "asset_code": "asset_code_03"
		    }
		]
		'
    */

    SELECT id INTO v_unknown_facility_id
    FROM facility
    WHERE facility_nbr = 'UNKNOWN';
    
    -- Stage data
    INSERT INTO temp_stage_asset (id, facility_id, facility_nbr, asset_nbr, sys_id, asset_code, status_code)
    SELECT 
   		a.id, 
   		f.id,
		COALESCE(j.facility_nbr, f.facility_nbr), 
		COALESCE(j.asset_nbr, a.asset_nbr),
		COALESCE(j.sys_id, a.sys_id),
		COALESCE(j.asset_code, a.asset_code),
		COALESCE(astat.status_code, a.status_code, 'UNKNOWN')
    FROM (
        SELECT * FROM JSON_TABLE(p_json_in, '$[*]' 
            COLUMNS (
                facility_nbr VARCHAR2(255) PATH '$.facility_nbr',
                asset_nbr VARCHAR2(255) PATH '$.asset_nbr',
                sys_id VARCHAR2(255) PATH '$.sys_id',
                asset_code VARCHAR2(255) PATH '$.asset_code',
                status_code VARCHAR2(255) PATH '$.status_code'
            )
        )
    ) j
	left join asset a on j.asset_nbr = a.asset_nbr
	left join facility f on a.facility_id = f.id
	left join asset_status astat on j.status_code = astat.status_code;
    
	UPDATE temp_stage_asset t
	SET facility_id = COALESCE((SELECT f.id FROM facility f WHERE t.facility_nbr = f.facility_nbr), v_unknown_facility_id)
	WHERE EXISTS (
	    SELECT 1 FROM facility f WHERE t.facility_nbr = f.facility_nbr
	);

	-- remove upserts where the user does not have access to the facility
	IF p_user_id IS NOT NULL THEN
 		DELETE from temp_stage_asset t
 		WHERE t.id IS NOT NULL 
 			AND	NOT EXISTS (select 1 FROM userfacility uf WHERE t.id = uf.facility_id AND uf.user_id = p_user_id);
	END IF;
    
    MERGE INTO asset target
    USING temp_stage_asset source
    ON (target.id = source.id)
    WHEN MATCHED THEN
        UPDATE SET 
            target.facility_id = source.facility_id,
            target.sys_id = source.sys_id,
            target.asset_code = source.asset_code,
            target.status_code = source.status_code,
            update_ts = SYSTIMESTAMP
    WHEN NOT MATCHED THEN
        INSERT (facility_id, asset_nbr, sys_id, asset_code, status_code, create_ts)
        VALUES (source.facility_id, source.asset_nbr, source.sys_id, SOURCE.asset_code, SOURCE.status_code, SYSTIMESTAMP);

 	COMMIT;

    -- Raise event for consumers
--    FOR asset_nbr IN
--        SELECT a.asset_nbr 
--		FROM asset a
--		JOIN update_stage t ON a.asset_nbr = t.asset_nbr
--    LOOP
--		INSERT INTO event_notification_buffer(channel, payload, create_ts)
--		VALUES (p_channel_name, asset_nbr, now());
--        PERFORM pg_notify(p_channel_name, asset_nbr);
--    END LOOP;
--	
    
END;
/