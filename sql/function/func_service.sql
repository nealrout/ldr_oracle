CREATE OR REPLACE FUNCTION get_service(
    p_user_id NUMBER DEFAULT NULL,
    p_source_ts TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    p_target_ts TIMESTAMP WITH TIME ZONE DEFAULT NULL
) RETURN service_table PIPELINED
IS
BEGIN
    FOR rec IN (
	    SELECT 
			account.account_nbr, facility.facility_nbr, asset.asset_nbr, asset.sys_id, service.service_nbr, service.service_code, service.service_name, service.status_code, service.create_ts, service.update_ts
		FROM 
			asset asset
			JOIN service service on asset.id = service.asset_id
			JOIN facility facility on asset.facility_id = facility.id
			JOIN account account on facility.account_id = account.id
			JOIN userfacility uf on facility.id = uf.facility_id
		WHERE 
			(
				(p_source_ts IS NOT NULL AND service.update_ts >= p_source_ts)
				OR 
				p_source_ts IS NULL
			)
			AND
			(
				(p_target_ts IS NOT NULL AND service.update_ts <= p_target_ts)
				OR
				p_target_ts IS NULL
			)
			AND
				(uf.user_id = p_user_id OR p_user_id is null)
    ) LOOP
        PIPE ROW(service_record(
            rec.account_nbr, rec.facility_nbr, rec.asset_nbr, rec.sys_id, rec.service_nbr, rec.service_code, rec.service_name, rec.status_code, rec.create_ts, rec.update_ts
        ));
    END LOOP;
END;
/
CREATE OR REPLACE FUNCTION get_service_by_json(
    p_jsonb CLOB,
    p_user_id NUMBER DEFAULT NULL
) RETURN service_table PIPELINED
IS
	v_count NUMBER;
BEGIN
    FOR rec IN (
        /* FOR TESTING */
    /*
        WITH json_data AS (
            SELECT '{
		    "account_nbr": ["ACCT_NBR_01","ACCT_NBR_02"]
		    ,"facility_nbr": ["FAC_NBR_01","FAC_NBR_02"]
		    ,"asset_nbr": ["asset_nbr_01"]
		    ,"sys_id": ["system_01"]
		    ,"service_nbr" :["SVC_NBR_004","SVC_NBR_005"]
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
                    NESTED PATH '$.service_nbr[*]' COLUMNS (service_nbr VARCHAR2(255) PATH '$'),
                    NESTED PATH '$.service_code[*]' COLUMNS (service_code VARCHAR2(255) PATH '$'),
                    NESTED PATH '$.service_name[*]' COLUMNS (service_name VARCHAR2(255) PATH '$'),
                    NESTED PATH '$.status_code[*]' COLUMNS (status_code VARCHAR2(255) PATH '$')
                )
            ) j
        )
--       SELECT * FROM cte_parsed_json;
			SELECT
				acc.account_nbr, fac.facility_nbr, a.asset_nbr, a.sys_id, s.service_nbr, s.service_code, s.service_name, s.status_code, s.create_ts, s.update_ts
			FROM account acc
			JOIN facility fac ON acc.id = fac.account_id 
			JOIN asset a ON fac.id = a.facility_id 
			JOIN service s on a.id = s.asset_id
			JOIN userfacility uf on fac.id = uf.facility_id
			WHERE 
            (EXISTS (SELECT 1 FROM cte_parsed_json p WHERE acc.account_nbr = p.account_nbr) OR (SELECT COUNT(*) FROM cte_parsed_json WHERE account_nbr IS NOT NULL) = 0)
            AND (EXISTS (SELECT 1 FROM cte_parsed_json p WHERE fac.facility_nbr = p.facility_nbr) OR (SELECT COUNT(*) FROM cte_parsed_json WHERE facility_nbr IS NOT NULL) = 0)
            AND (EXISTS (SELECT 1 FROM cte_parsed_json p WHERE a.asset_nbr = p.asset_nbr) OR (SELECT COUNT(*) FROM cte_parsed_json WHERE asset_nbr IS NOT NULL) = 0)
            AND (EXISTS (SELECT 1 FROM cte_parsed_json p WHERE a.sys_id = p.sys_id) OR (SELECT COUNT(*) FROM cte_parsed_json WHERE sys_id IS NOT NULL) = 0)
            AND (EXISTS (SELECT 1 FROM cte_parsed_json p WHERE s.service_nbr = p.service_nbr) OR (SELECT COUNT(*) FROM cte_parsed_json WHERE service_nbr IS NOT NULL) = 0)
            AND (EXISTS (SELECT 1 FROM cte_parsed_json p WHERE s.service_code = p.service_code) OR (SELECT COUNT(*) FROM cte_parsed_json WHERE service_code IS NOT NULL) = 0)
            AND (EXISTS (SELECT 1 FROM cte_parsed_json p WHERE s.service_name = p.service_name) OR (SELECT COUNT(*) FROM cte_parsed_json WHERE service_name IS NOT NULL) = 0)
            AND (EXISTS (SELECT 1 FROM cte_parsed_json p WHERE s.status_code = p.status_code) OR (SELECT COUNT(*) FROM cte_parsed_json WHERE status_code IS NOT NULL) = 0)
            AND (uf.user_id = p_user_id OR p_user_id is null)
    ) LOOP
        PIPE ROW(service_record(
            rec.account_nbr, rec.facility_nbr, rec.asset_nbr, rec.sys_id, rec.service_nbr, rec.service_code, rec.service_name, rec.status_code, rec.create_ts, rec.update_ts
        ));
    END LOOP;
END;
/
CREATE OR REPLACE PROCEDURE upsert_service_from_json(
    p_json_in CLOB,
    p_channel_name VARCHAR2,
    p_user_id NUMBER,
    p_parent_channel_name VARCHAR2 DEFAULT NULL
)
IS
    v_count NUMBER;
BEGIN
    /*  SAMPLE p_json_in
        ' [
		    {
		        "asset_nbr": "asset_nbr_01",
		        "status_code": "UNKNOWN",
		        "service_code": "SVC_008",
		        "service_name": "Service Name_008",
		        "service_nbr": "SVC_NBR_008"
		    },
		    {
		        "asset_nbr": "asset_nbr_01",
		        "status_code": "UNKNOWN",
		        "service_code": "SVC_009",
		        "service_name": "Service Name_009",
		        "service_nbr": "SVC_NBR_009"
		    }
		]
		'
    */

    -- Stage data
    INSERT INTO temp_stage_service (id, facility_id, target_asset_id, service_nbr, service_code, service_name, status_code)
    SELECT 
   		s.id, 
   		f.id AS facility_id,
		COALESCE(a_new.id, s.asset_id) as target_asset_id,
		COALESCE(j.service_nbr, s.service_nbr),
		COALESCE(j.service_code, s.service_code),
		COALESCE(j.service_name, s.service_name),
		COALESCE(sstate.status_code, s.status_code, 'UNKNOWN')
    FROM (
        SELECT * FROM JSON_TABLE(p_json_in, '$[*]' 
            COLUMNS (
                account_nbr VARCHAR2(255) PATH '$.account_nbr',
                asset_nbr VARCHAR2(255) PATH '$.asset_nbr',
                service_nbr VARCHAR2(255) PATH '$.service_nbr',
                service_code VARCHAR2(255) PATH '$.service_code',
                service_name VARCHAR2(255) PATH '$.service_name',
                status_code VARCHAR2(255) PATH '$.status_code'
            )
        )
    ) j
	left join service s on j.service_nbr = s.service_nbr
	left join asset a on s.asset_id = a.id
	left join facility f on a.facility_id = f.id
	left join asset a_new on j.asset_nbr = a_new.asset_nbr
	left join service_status sstate on j.status_code = sstate.status_code;
    
   	-- asset is a requirement to insert or update an sr.
	DELETE from temp_stage_service where target_asset_id IS NULL;
    
	-- remove upserts where the user does not have access to the facility
	IF p_user_id IS NOT NULL THEN
	    DELETE FROM temp_stage_service t
	    WHERE EXISTS (
	        SELECT 1 
	        FROM asset a
	        WHERE t.target_asset_id = a.id
	        AND NOT EXISTS (
	            SELECT 1 
	            FROM userfacility uf 
	            WHERE a.facility_id = uf.facility_id 
	            AND uf.user_id = p_user_id
	        )
	    );
	END IF;
    
    MERGE INTO service target
    USING temp_stage_service source
    ON (target.id = source.id)
    WHEN MATCHED THEN
        UPDATE SET 
            target.asset_id = source.target_asset_id,
            target.service_code = source.service_code,
            target.service_name = source.service_name,
            target.status_code = source.status_code,
            update_ts = SYSTIMESTAMP
    WHEN NOT MATCHED THEN
        INSERT (asset_id, service_nbr, service_code, service_name, status_code, create_ts)
        VALUES (source.target_asset_id, source.service_nbr, source.service_code, SOURCE.service_name, SOURCE.status_code, SYSTIMESTAMP);

 	COMMIT;

    -- Raise event for consumers
--    FOR service_nbr IN
--        SELECT s.service_nbr
--		FROM service s
--		JOIN update_stage t ON s.service_nbr = t.service_nbr
--    LOOP
--		INSERT INTO event_notification_buffer(channel, payload, create_ts)
--		VALUES (p_channel_name, service_nbr, now());
--        PERFORM pg_notify(p_channel_name, service_nbr);
--    END LOOP;

--	
    
END;
/
