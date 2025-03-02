CREATE OR REPLACE FUNCTION get_userfacility_by_user(p_user_id IN NUMBER)
RETURN userfacility_by_user_table PIPELINED
IS
BEGIN
	FOR rec in(
	    SELECT f.facility_nbr
	    FROM auth_user au 
	    JOIN userfacility uf ON au.id = uf.user_id
	    JOIN facility f ON uf.facility_id = f.id
	    WHERE au.id = p_user_id
	) LOOP
        PIPE ROW(userfacility_by_user_record(
            rec.facility_nbr
        ));
    END LOOP;
END;
/
CREATE OR REPLACE FUNCTION get_userfacility(
    p_user_id NUMBER DEFAULT NULL,
    p_source_ts TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    p_target_ts TIMESTAMP WITH TIME ZONE DEFAULT NULL
) RETURN userfacility_table PIPELINED
IS
BEGIN
    FOR rec IN (
	    SELECT au.username, TO_CLOB(json_arrayagg(f.facility_nbr)) as facility_nbr
	    FROM auth_user au 
	    LEFT JOIN userfacility uf ON au.id = uf.user_id
	    LEFT JOIN facility f ON uf.facility_id = f.id
		WHERE -- Person selecting this is a super user, or p_user_id was not specified
			(
				(SELECT count(*) FROM auth_user auin WHERE auin.is_superuser = 1 AND auin.id = p_user_id) >0 
				OR p_user_id IS NULL
			)
			OR au.id = p_user_id		
		GROUP BY au.username, uf.create_ts, uf.update_ts
    ) LOOP
        PIPE ROW(userfacility_record(
            rec.username, rec.facility_nbr
        ));
    END LOOP;
END;
/
CREATE OR REPLACE FUNCTION get_userfacility_by_json(
    p_jsonb CLOB,
    p_user_id NUMBER DEFAULT NULL
) RETURN userfacility_table PIPELINED
IS
	v_count NUMBER;
BEGIN
    FOR rec IN (
        /* FOR TESTING */
    /*
        WITH json_data AS (
            SELECT '{
			"username": ["daas","asdf"]
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
                    NESTED PATH '$.username[*]' COLUMNS (username VARCHAR2(255) PATH '$')
                )
            ) j
        )
--       SELECT * FROM cte_parsed_json;

		SELECT au.username, TO_CLOB(json_arrayagg(f.facility_nbr)) as facility_nbr
	    FROM auth_user au 
	    LEFT JOIN userfacility uf ON au.id = uf.user_id
	    LEFT JOIN facility f ON uf.facility_id = f.id
		WHERE 
			(-- Person selecting this is a super user, or p_user_id was not specified
				(
					(SELECT count(*) FROM auth_user auin WHERE auin.is_superuser = 1 AND auin.id = p_user_id) >0 
					OR p_user_id IS NULL
				)
				OR au.id = p_user_id		
			)
            AND (EXISTS (SELECT 1 FROM cte_parsed_json p WHERE au.username = p.username) OR (SELECT COUNT(*) FROM cte_parsed_json WHERE username IS NOT NULL) = 0)
        GROUP BY au.username
    ) LOOP
        PIPE ROW(userfacility_record(
            rec.username, rec.facility_nbr
        ));
    END LOOP;
END;
/

CREATE OR REPLACE PROCEDURE upsert_userfacility_from_json(
    p_json_in CLOB,
    p_channel_name VARCHAR2,
    p_user_id NUMBER,
    p_parent_channel_name VARCHAR2 DEFAULT NULL,
    p_delete_current_mappings NUMBER DEFAULT 1
)
IS
    v_count NUMBER;
BEGIN
    /*  SAMPLE p_json_in
        '[
			{
			    "username": "test", "facility_nbr":["FAC_NBR_01","FAC_NBR_02"]
			}
        ]'

    */
    -- Check if user is a superuser
    SELECT COUNT(*) INTO v_count 
    FROM auth_user 
    WHERE is_superuser = 1 
    AND id = p_user_id;

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20000, 'user_id ' || p_user_id || ' does not have super_user permission');
    END IF;

    -- Stage data
    INSERT INTO temp_stage_userfacility (user_id, username, facility_nbr, facility_id)
    SELECT au.id AS user_id, 
           COALESCE(j.username, au.username), 
           j.facility_nbr,
           f.id AS facility_id
    FROM (
        SELECT * FROM JSON_TABLE(p_json_in,'$[*]' 
        COLUMNS (
	        username NVARCHAR2(150) PATH '$.username',
    	    NESTED PATH '$.facility_nbr[*]' COLUMNS (facility_nbr VARCHAR2(255) PATH '$')
	    ))
    ) j
    JOIN auth_user au  ON j.username = au.username
    JOIN facility f ON j.facility_nbr = f.facility_nbr;

	-- Pre delete all mappings, before adding new mappings.
	IF p_delete_current_mappings = 1 THEN
	    DELETE FROM userfacility uf
	    WHERE EXISTS (
	        SELECT 1
	        FROM temp_stage_userfacility t
	        WHERE uf.user_id = t.user_id
	    );
	END IF;
    
    MERGE INTO userfacility target
    USING temp_stage_userfacility source
    ON (target.user_id = source.user_id AND target.facility_id = source.facility_id)
    WHEN MATCHED THEN
        UPDATE SET 
            target.update_ts = SYSTIMESTAMP
    WHEN NOT MATCHED THEN
        INSERT (user_id, facility_id, create_ts)
        VALUES (source.user_id, source.facility_id, SYSTIMESTAMP);

    COMMIT;
    
    -- Raise event for consumers
--    FOR username IN
--        SELECT au.username
--		FROM auth_user au
--		JOIN update_stage t ON au.id = t.user_id
--    LOOP
--		INSERT INTO event_notification_buffer(channel, payload, create_ts)
--		VALUES (p_channel_name, username, now());
--        PERFORM pg_notify(p_channel_name, username);
--    END LOOP;
END;
/