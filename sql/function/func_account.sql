CREATE OR REPLACE FUNCTION get_account(
    p_user_id NUMBER DEFAULT NULL,
    p_source_ts TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    p_target_ts TIMESTAMP WITH TIME ZONE DEFAULT NULL
) RETURN account_table PIPELINED
IS
BEGIN
    FOR rec IN (
		SELECT
			ac.account_nbr, ac.account_code, ac.account_name, TO_CLOB(json_arrayagg(f.facility_nbr)) as facility_nbr
		FROM account ac
		LEFT JOIN facility f on ac.id = f.account_id
		LEFT JOIN userfacility uf on f.id = uf.facility_id
			WHERE 
			(
				(p_source_ts IS NOT NULL AND ac.update_ts >= p_source_ts)
				OR 
				p_source_ts IS NULL
			)
			AND
			(
				(p_target_ts IS NOT NULL AND ac.update_ts <= p_target_ts)
				OR
				p_target_ts IS NULL
			)
			AND
				(uf.user_id = p_user_id OR p_user_id is null)
		GROUP BY ac.account_nbr, ac.account_code, ac.account_name
    ) LOOP
        PIPE ROW(account_record(
            rec.account_nbr, rec.account_code, rec.account_name, rec.facility_nbr
        ));
    END LOOP;
END;
/
CREATE OR REPLACE FUNCTION get_account_by_json(
    p_jsonb CLOB,
    p_user_id NUMBER DEFAULT NULL
) RETURN account_table PIPELINED
IS
	v_count NUMBER;
BEGIN
    FOR rec IN (
        /* FOR TESTING */
    /*
        WITH json_data AS (
            SELECT '{
			    "account_nbr": ["ACCT_NBR_09", "ACCT_NBR_10"]
			    ,"account_code":["US_ACCT_09", "US_ACCT_10"]
			    ,"account_name":["account 09", "account 10"]
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
                    NESTED PATH '$.account_code[*]' COLUMNS (account_code VARCHAR2(255) PATH '$'),
                    NESTED PATH '$.account_name[*]' COLUMNS (account_name VARCHAR2(255) PATH '$')
                )
            ) j
        )
--       SELECT * FROM cte_parsed_json;

        SELECT
			ac.account_nbr, ac.account_code, ac.account_name, TO_CLOB(json_arrayagg(f.facility_nbr)) as facility_nbr, ac.create_ts, ac.update_ts
		FROM account ac
		LEFT JOIN facility f on ac.id = f.account_id
		LEFT JOIN userfacility uf on f.id = uf.facility_id       
		WHERE 
            (EXISTS (SELECT 1 FROM cte_parsed_json p WHERE ac.account_nbr = p.account_nbr) OR (SELECT COUNT(*) FROM cte_parsed_json WHERE account_nbr IS NOT NULL) = 0)
            AND (EXISTS (SELECT 1 FROM cte_parsed_json p WHERE ac.account_code = p.account_code) OR (SELECT COUNT(*) FROM cte_parsed_json WHERE account_code IS NOT NULL) = 0)
            AND (EXISTS (SELECT 1 FROM cte_parsed_json p WHERE ac.account_name = p.account_name) OR (SELECT COUNT(*) FROM cte_parsed_json WHERE account_name IS NOT NULL) = 0)
            AND (uf.user_id = p_user_id OR p_user_id is null)
        GROUP BY ac.account_nbr, ac.account_code, ac.account_name
    ) LOOP
        PIPE ROW(account_record(
            rec.account_nbr, rec.account_code, rec.account_name, rec.facility_nbr
        ));
    END LOOP;
END;
/
CREATE OR REPLACE PROCEDURE upsert_account_from_json(
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

    -- Stage data
    INSERT INTO temp_stage_account (id, account_nbr, account_code, account_name)
    SELECT acc.id, 
           COALESCE(j.account_nbr, acc.account_nbr), 
           COALESCE(j.account_code, acc.account_code), 
           COALESCE(j.account_name, acc.account_name)
    FROM (
        SELECT * FROM JSON_TABLE(p_json_in, '$[*]' 
            COLUMNS (
                account_nbr VARCHAR2(255) PATH '$.account_nbr',
                account_code VARCHAR2(255) PATH '$.account_code',
                account_name VARCHAR2(255) PATH '$.account_name'
            )
        )
    ) j
    LEFT JOIN account acc on j.account_nbr = acc.account_nbr; 
  
	-- remove upserts where the user does not have access to the facility
	IF p_user_id IS NOT NULL THEN
		DELETE FROM temp_stage_account t
		WHERE EXISTS (
		    SELECT 1
		    FROM facility f
		    WHERE t.id = f.account_id 
		    AND NOT EXISTS (
		        SELECT 1 
		        FROM userfacility uf 
		        WHERE uf.facility_id = f.id 
		        AND uf.user_id = p_user_id
		    )
		);
	END IF;
    
    MERGE INTO account target
    USING temp_stage_account source
    ON (target.id = source.id)
    WHEN MATCHED THEN
        UPDATE SET 
            target.account_nbr = source.account_nbr,
            target.account_code = source.account_code,
            target.account_name = source.account_name
    WHEN NOT MATCHED THEN
        INSERT (account_nbr, account_code, account_name, create_ts)
        VALUES (source.account_nbr, source.account_code, source.account_name, SYSTIMESTAMP);

    COMMIT;
    
END;
/