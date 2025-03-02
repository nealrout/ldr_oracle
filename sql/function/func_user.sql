


CREATE OR REPLACE FUNCTION get_user(
    p_user_id NUMBER DEFAULT NULL,
    p_source_ts TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    p_target_ts TIMESTAMP WITH TIME ZONE DEFAULT NULL
) RETURN user_table PIPELINED
IS
BEGIN
    FOR rec IN (
        SELECT au.username, au.first_name, au.last_name, au.email, au.is_staff, au.is_superuser, au.is_active
               TO_CLOB(json_arrayagg(f.facility_nbr)) as facility_nbr 
        FROM auth_user au 
        LEFT JOIN userfacility uf ON au.id = uf.user_id
        LEFT JOIN facility f ON uf.facility_id = f.Id
        WHERE 
            (
                (SELECT COUNT(*) FROM auth_user auin WHERE auin.is_superuser = 1 AND auin.id = p_user_id) > 0 
                OR p_user_id IS NULL
            )
            OR au.id = p_user_id
        GROUP BY au.username, au.first_name, au.last_name, au.email, au.is_staff, au.is_superuser, au.is_active
    ) LOOP
        PIPE ROW(user_record(
            rec.username, rec.first_name, rec.last_name, rec.email, rec.is_staff, rec.is_superuser, rec.is_active, rec.facility_nbr
        ));
    END LOOP;
END;
/
CREATE OR REPLACE FUNCTION get_user_by_json(
    p_jsonb CLOB,
    p_user_id NUMBER DEFAULT NULL
) RETURN user_table PIPELINED
IS
	v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count 
    FROM auth_user auin 
    WHERE auin.is_superuser = 1 
    AND auin.id = p_user_id;

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20000, 'user_id ' || p_user_id || ' does not have super_user permission');
    END IF;

    FOR rec IN (
        /* FOR TESTING */
        /*
        WITH json_data AS (
            SELECT '{
            "username": ["daas","test"]
            ,"first_name": ["app"]
            ,"last_name": ["user"]
            ,"email" :["nroutson@gmail.com"]
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
                    NESTED PATH '$.username[*]' COLUMNS (username VARCHAR2(255) PATH '$'),
                    NESTED PATH '$.first_name[*]' COLUMNS (first_name VARCHAR2(255) PATH '$'),
                    NESTED PATH '$.last_name[*]' COLUMNS (last_name VARCHAR2(255) PATH '$'),
                    NESTED PATH '$.email[*]' COLUMNS (email VARCHAR2(255) PATH '$')
                )
            ) j
        )
        --SELECT * FROM cte_parsed_json;
        SELECT au.username, au.first_name, au.last_name, au.email, au.is_staff, au.is_superuser, au.is_active
            ,json_arrayagg(f.facility_nbr) as facility_nbr
        FROM auth_user au 
        LEFT JOIN userfacility uf ON au.id = uf.user_id
        LEFT JOIN facility f ON uf.facility_id  = f.Id
        WHERE 
            (EXISTS (SELECT 1 FROM cte_parsed_json p WHERE au.username = p.username) OR (SELECT COUNT(*) FROM cte_parsed_json WHERE username IS NOT NULL) = 0)
            AND (EXISTS (SELECT 1 FROM cte_parsed_json p WHERE au.first_name = p.first_name) OR (SELECT COUNT(*) FROM cte_parsed_json WHERE first_name IS NOT NULL) = 0)
            AND (EXISTS (SELECT 1 FROM cte_parsed_json p WHERE au.last_name = p.last_name) OR (SELECT COUNT(*) FROM cte_parsed_json WHERE last_name IS NOT NULL) = 0)
            AND (EXISTS (SELECT 1 FROM cte_parsed_json p WHERE au.email = p.email) OR (SELECT COUNT(*) FROM cte_parsed_json WHERE email IS NOT NULL) = 0)
        GROUP BY au.username, au.first_name, au.last_name, au.email, au.is_staff, au.is_superuser, au.is_active
    ) LOOP
        PIPE ROW(user_record(
            rec.username, rec.first_name, rec.last_name, rec.email, rec.is_staff, rec.is_superuser, rec.is_active, rec.facility_nbr
        ));
    END LOOP;
END;
/
CREATE OR REPLACE PROCEDURE upsert_user_from_json(
    p_json_in CLOB,
    p_channel_name VARCHAR2,
    p_user_id NUMBER,
    p_parent_channel_name VARCHAR2 DEFAULT NULL
)
IS
    v_count NUMBER;
BEGIN
    /*  SAMPLE p_json_in
        '[
            {
                "username": "daas",
                "first_name": "app",
                "last_name": "user",
                "email": "nroutson@gmail.com"
            },
            {
                "username": "test",
                "first_name": "test",
                "last_name": "test",
                "email": "test@gmail.com"
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
    INSERT INTO temp_stage_user (id, username, first_name, last_name, email)
    SELECT au.id, 
           COALESCE(j.username, au.username), 
           COALESCE(j.first_name, au.first_name), 
           COALESCE(j.last_name, au.last_name), 
           COALESCE(j.email, au.email)
    FROM (
        SELECT * FROM JSON_TABLE(p_json_in, '$[*]' 
            COLUMNS (
                username NVARCHAR2(150) PATH '$.username',
                first_name NVARCHAR2(150) PATH '$.first_name',
                last_name NVARCHAR2(150) PATH '$.last_name',
                email NVARCHAR2(254) PATH '$.email'
            )
        )
    ) j
    LEFT JOIN auth_user au 
    ON j.username = au.username;

    MERGE INTO auth_user target
    USING temp_stage_user source
    ON (target.id = source.id)
    WHEN MATCHED THEN
        UPDATE SET 
            target.first_name = source.first_name,
            target.last_name = source.last_name,
            target.email = source.email;
--    WHEN NOT MATCHED THEN
--        INSERT (username, first_name, last_name, email)
--        VALUES (source.username, source.first_name, source.last_name, source.email);

    COMMIT;
    
END;
