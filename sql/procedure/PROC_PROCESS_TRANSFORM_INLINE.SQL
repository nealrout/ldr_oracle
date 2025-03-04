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
            AND UPPER(SRC_TABLE) = UPPER(p_src_table)
            AND UPPER(TGT_TABLE) = UPPER(p_tgt_table) 
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

    -- Initialize SQL fragments
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
            AND UPPER(SRC_TABLE) = UPPER(p_src_table)
            AND UPPER(TGT_TABLE) = UPPER(p_tgt_table) 
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
        -- Replace "STATIC_FIELD_NAME" with the actual column name (source.FIELD_XXX)
        DECLARE
            v_actual_transformation VARCHAR2(4000);
        BEGIN
            v_actual_transformation := REPLACE(rec.transformation, 'STATIC_FIELD_NAME', 'source.' || rec.fieldName);

            -- Exclude the unique identifier from UPDATE SET
            IF rec.fieldName <> v_unique_identifier THEN
                v_update_columns := v_update_columns || 'target.' || rec.fieldName || ' = ' || v_actual_transformation || ', ';
            END IF;

            -- Include all fields in INSERT
            v_insert_columns := v_insert_columns || rec.fieldName || ', ';
            v_insert_values := v_insert_values || v_actual_transformation || ', ';
        END;
    END LOOP;

    -- Ensure the unique identifier is included in the INSERT statement
    IF INSTR(v_insert_columns, v_unique_identifier) = 0 THEN
        v_insert_columns := v_insert_columns || v_unique_identifier || ', ';
        v_insert_values := v_insert_values || 'source.' || v_unique_identifier || ', ';
    END IF;

    -- Fix trailing commas
    v_update_columns := RTRIM(v_update_columns, ', ');  
    v_insert_columns := RTRIM(v_insert_columns, ', ');  
    v_insert_values := RTRIM(v_insert_values, ', ');

    -- Construct final MERGE statement
    IF v_update_columns IS NOT NULL THEN
        v_merge_sql := v_merge_sql || ' ' || v_update_columns;
    ELSE
        v_merge_sql := REPLACE(v_merge_sql, 'WHEN MATCHED THEN UPDATE SET ', '');
    END IF;

    v_merge_sql := v_merge_sql || ' WHEN NOT MATCHED THEN INSERT (' || v_insert_columns || ') VALUES (' || v_insert_values || ')';

    -- Debugging: Print final SQL
    DBMS_OUTPUT.PUT_LINE('SQL: ' || v_merge_sql);

    -- Update log
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
END PROCESS_TRANSFORM_INLINE;
