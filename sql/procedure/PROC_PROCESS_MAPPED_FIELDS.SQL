CREATE OR REPLACE PROCEDURE PROCESS_MAPPED_FIELDS (
    p_load_log_id IN NUMBER,
    p_load_log_detail_id IN NUMBER,
    p_target_table IN VARCHAR2,
    p_source_table IN VARCHAR2
)
IS
    v_merge_sql VARCHAR2(32767);  
    v_update_columns VARCHAR2(32767);
    v_insert_columns VARCHAR2(32767);
    v_insert_values VARCHAR2(32767);
    v_unique_identifier VARCHAR2(4000);
BEGIN
    -- Fetch the unique identifier dynamically
    SELECT DISTINCT uniqueIdentifier 
    INTO v_unique_identifier
    FROM (
        WITH json_data AS (
            SELECT ID, STEP_CODE, SRC_TABLE, TGT_TABLE, CONFIG 
            FROM LOAD_CONFIG
            WHERE STEP_CODE = 'PROCESS_MAPPED'   
            AND UPPER(SRC_TABLE) = UPPER(p_source_table)
            AND UPPER(TGT_TABLE) = UPPER(p_target_table) 
        ),
        cte_parsed_json AS (
            SELECT 
                j.ID, 
                j.STEP_CODE,
                j.SRC_TABLE, 
                j.TGT_TABLE, 
                DBMS_LOB.SUBSTR(jt.srcField, 4000, 1) AS srcField, 
                DBMS_LOB.SUBSTR(jt.tgtField, 4000, 1) AS tgtField,
                DBMS_LOB.SUBSTR(jt.uniqueIdentifier, 4000, 1) AS uniqueIdentifier
            FROM json_data j,
            JSON_TABLE(j.CONFIG, '$' 
                COLUMNS (
                    uniqueIdentifier CLOB PATH '$.uniqueIdentifier',
                    NESTED PATH '$.mappings[*]' 
                    COLUMNS (
                        srcField CLOB PATH '$.srcField',
                        tgtField CLOB PATH '$.tgtField'
                    )
                )
            ) jt
        )
        SELECT DISTINCT uniqueIdentifier FROM cte_parsed_json
    )
    WHERE ROWNUM = 1; -- Ensuring a single unique identifier

    -- Initialize SQL fragments with dynamic table names and unique identifier
    v_merge_sql := 'MERGE INTO ' || p_target_table || ' target USING ' || p_source_table || ' source ON (' ||
                   'DBMS_LOB.SUBSTR(target.' || v_unique_identifier || ', 4000, 1) = ' ||
                   'DBMS_LOB.SUBSTR(source.' || v_unique_identifier || ', 4000, 1)) WHEN MATCHED THEN UPDATE SET ';

    v_update_columns := '';
    v_insert_columns := 'LOAD_LOG_ID, CREATE_TS, ';
    v_insert_values := p_load_log_id || ', SYSTIMESTAMP, ';

    -- Loop through column mappings
    FOR rec IN (
        WITH json_data AS (
            SELECT ID, STEP_CODE, SRC_TABLE, TGT_TABLE, CONFIG 
            FROM LOAD_CONFIG
            WHERE STEP_CODE = 'PROCESS_MAPPED'   
            AND UPPER(SRC_TABLE) = UPPER(p_source_table)
            AND UPPER(TGT_TABLE) = UPPER(p_target_table) 
        ),
        cte_parsed_json AS (
            SELECT 
                j.ID, 
                j.STEP_CODE,
                j.SRC_TABLE, 
                j.TGT_TABLE, 
                DBMS_LOB.SUBSTR(jt.srcField, 4000, 1) AS srcField, 
                DBMS_LOB.SUBSTR(jt.tgtField, 4000, 1) AS tgtField,
                DBMS_LOB.SUBSTR(jt.uniqueIdentifier, 4000, 1) AS uniqueIdentifier
            FROM json_data j,
            JSON_TABLE(j.CONFIG, '$' 
                COLUMNS (
                    uniqueIdentifier CLOB PATH '$.uniqueIdentifier',
                    NESTED PATH '$.mappings[*]' 
                    COLUMNS (
                        srcField CLOB PATH '$.srcField',
                        tgtField CLOB PATH '$.tgtField'
                    )
                )
            ) jt
        )
        SELECT DISTINCT srcField, tgtField FROM cte_parsed_json
    ) LOOP
        -- Exclude the unique identifier from UPDATE SET
        IF rec.tgtField <> v_unique_identifier THEN
            v_update_columns := v_update_columns || 'target.' || rec.tgtField || ' = source.' || rec.srcField || ', ';
        END IF;

        -- Include all fields in INSERT
        v_insert_columns := v_insert_columns || rec.tgtField || ', ';
        v_insert_values := v_insert_values || 'source.' || rec.srcField || ', ';
    END LOOP;

    -- Fix trailing commas
    v_update_columns := RTRIM(v_update_columns, ', ');  
    v_insert_columns := RTRIM(v_insert_columns, ', ');  
    v_insert_values := RTRIM(v_insert_values, ', ');

    -- Construct final MERGE statement
    IF v_update_columns IS NOT NULL THEN
        v_merge_sql := v_merge_sql || ' ' || v_update_columns;
    ELSE
        -- If no columns to update, remove the `WHEN MATCHED` clause
        v_merge_sql := REPLACE(v_merge_sql, 'WHEN MATCHED THEN UPDATE SET ', '');
    END IF;

    v_merge_sql := v_merge_sql || ' WHEN NOT MATCHED THEN INSERT (' || v_insert_columns || ') VALUES (' || v_insert_values || ')';

    -- Print the query for debugging
    DBMS_OUTPUT.PUT_LINE(v_merge_sql);

    UPDATE LOAD_LOG_DETAIL SET SQL = v_merge_sql WHERE ID = p_load_log_detail_id;

    -- Check length before execution
    IF LENGTH(v_merge_sql) > 32767 THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Query too long! Switching to DBMS_SQL.PARSE().');
    ELSE
        EXECUTE IMMEDIATE v_merge_sql;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END PROCESS_MAPPED_FIELDS;
