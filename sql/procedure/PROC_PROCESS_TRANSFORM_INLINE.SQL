CREATE OR REPLACE PROCEDURE PROCESS_TRANSFORM_INLINE (
    p_load_log_id IN NUMBER,
    p_load_log_detail_id IN NUMBER,
    p_tgt_table IN VARCHAR2,
    p_src_table IN VARCHAR2
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
            WHERE STEP_CODE = 'TRANSFORM_INLINE'   
            AND UPPER(SRC_TABLE) = UPPER('STG_MAP_01')
            AND UPPER(TGT_TABLE) = UPPER('STG_TRANSFORM_01') 
        ),
        cte_parsed_json AS (
            SELECT 
                j.ID, 
                j.STEP_CODE,
                j.SRC_TABLE, 
                j.TGT_TABLE, 
                DBMS_LOB.SUBSTR(jt.fieldName, 4000, 1) AS fieldName, 
                DBMS_LOB.SUBSTR(jt.transformation, 4000, 1) AS transformation,
                DBMS_LOB.SUBSTR(jt.uniqueIdentifier, 4000, 1) AS uniqueIdentifier
            FROM json_data j,
            JSON_TABLE(j.CONFIG, '$' 
                COLUMNS (
                    uniqueIdentifier CLOB PATH '$.uniqueIdentifier',
                    NESTED PATH '$.transformations[*]' 
                    COLUMNS (
                        fieldName CLOB PATH '$.fieldName',
                        transformation CLOB PATH '$.transformation'
                    )
                )
            ) jt
        )
        SELECT DISTINCT uniqueIdentifier FROM cte_parsed_json
    )
    WHERE ROWNUM = 1; -- Ensuring a single unique identifier

    -- Initialize SQL fragments with dynamic table names and unique identifier
    v_merge_sql := 'MERGE INTO ' || p_tgt_table || ' target USING ' || p_src_table || ' source ON (' ||
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
            WHERE STEP_CODE = 'TRANSFORM_INLINE'   
            AND UPPER(SRC_TABLE) = UPPER('STG_MAP_01')
            AND UPPER(TGT_TABLE) = UPPER('STG_TRANSFORM_01') 
        ),
        cte_parsed_json AS (
            SELECT 
                j.ID, 
                j.STEP_CODE,
                j.SRC_TABLE, 
                j.TGT_TABLE, 
                DBMS_LOB.SUBSTR(jt.fieldName, 4000, 1) AS fieldName, 
                DBMS_LOB.SUBSTR(jt.transformation, 4000, 1) AS transformation,
                DBMS_LOB.SUBSTR(jt.uniqueIdentifier, 4000, 1) AS uniqueIdentifier
            FROM json_data j,
            JSON_TABLE(j.CONFIG, '$' 
                COLUMNS (
                    uniqueIdentifier CLOB PATH '$.uniqueIdentifier',
                    NESTED PATH '$.transformations[*]' 
                    COLUMNS (
                        fieldName CLOB PATH '$.fieldName',
                        transformation CLOB PATH '$.transformation'
                    )
                )
            ) jt
        )
        SELECT DISTINCT fieldName, transformation FROM cte_parsed_json
    ) LOOP
        -- Exclude the unique identifier from UPDATE SET
        IF rec.fieldName <> v_unique_identifier THEN
            v_update_columns := v_update_columns || 'target.' || rec.fieldName || ' = source.' || rec.transformation || ', ';
        END IF;

        -- Include all fields in INSERT
        v_insert_columns := v_insert_columns || rec.fieldName || ', ';
        v_insert_values := v_insert_values || 'source.' || rec.transformation || ', ';
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

--     Append the WHERE NOT EXISTS condition dynamically
--    v_merge_sql := v_merge_sql || ' WHERE NOT EXISTS (' ||
--                   'SELECT 1 FROM ERR_VALIDATION EV ' ||
--                   'WHERE EV.LOAD_LOG_ID = ' || p_load_log_id || 
--                   ' AND EV.UNIQUE_IDENTIFIER = ''' || v_unique_identifier || '''' ||
--                   ' AND DBMS_LOB.SUBSTR(EV.UNIQUE_IDENTIFIER_VALUE, 4000, 1) = ' ||
--                   'DBMS_LOB.SUBSTR(source.' || v_unique_identifier || ', 4000, 1))';

    -- Print the query for debugging
    DBMS_OUTPUT.PUT_LINE(v_merge_sql);

--    UPDATE LOAD_LOG_DETAIL SET SQL = v_merge_sql WHERE ID = p_load_log_detail_id;
    UPDATE LOAD_LOG_DETAIL SET SQL = v_merge_sql WHERE ID = -4;

    -- Check length before execution
    IF LENGTH(v_merge_sql) > 32767 THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Query too long! Switching to DBMS_SQL.PARSE().');
    ELSE
        EXECUTE IMMEDIATE v_merge_sql;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END PROCESS_TRANSFORM_INLINE;
