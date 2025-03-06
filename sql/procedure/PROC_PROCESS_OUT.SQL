CREATE OR REPLACE PROCEDURE PROCESS_OUT (
    p_load_log_id IN NUMBER,
    p_load_log_detail_id IN NUMBER,
    p_src_table IN VARCHAR2,
    p_tgt_table IN VARCHAR2
)
IS
    v_merge_sql VARCHAR2(32767);  
    v_update_columns VARCHAR2(32767) := '';
    v_insert_columns VARCHAR2(32767) := 'LOAD_LOG_ID, UNIQUE_IDENTIFIER, CREATE_TS, ';
    v_insert_values VARCHAR2(32767) := '';
    v_unique_identifier VARCHAR2(4000) := NULL;
    v_first_loop BOOLEAN := TRUE;
BEGIN
    -- **Extract Unique Identifier & Mappings**
    FOR rec IN (
        WITH json_data AS (
            SELECT ID, STEP_CODE, SRC_TABLE, TGT_TABLE, CONFIG 
            FROM LOAD_CONFIG
            WHERE STEP_CODE = 'OUT'   
            AND UPPER(SRC_TABLE) = UPPER(p_src_table)
            AND UPPER(TGT_TABLE) = UPPER(p_tgt_table) 
        ),
        cte_parsed_json AS (
            SELECT 
                j.ID, 
                j.STEP_CODE,
                j.SRC_TABLE, 
                j.TGT_TABLE,
                DBMS_LOB.SUBSTR(jt.uniqueIdentifier, 4000, 1) AS uniqueIdentifier,
                DBMS_LOB.SUBSTR(jt.srcField, 4000, 1) AS srcField, 
                DBMS_LOB.SUBSTR(jt.tgtField, 4000, 1) AS tgtField,
                DBMS_LOB.SUBSTR(jt.tgtType, 4000, 1) AS tgtType
            FROM json_data j,
            JSON_TABLE(j.CONFIG, '$' 
                COLUMNS (
                    uniqueIdentifier CLOB PATH '$.uniqueIdentifier',
                    NESTED PATH '$.mappings[*]' 
                    COLUMNS (
                        srcField CLOB PATH '$.srcField',
                        tgtField CLOB PATH '$.tgtField',
                        tgtType CLOB PATH '$.tgtType'
                    )
                )
            ) jt
        )
        SELECT DISTINCT uniqueIdentifier, srcField, tgtField, tgtType FROM cte_parsed_json
    ) LOOP
        -- **Initialize Unique Identifier & v_merge_sql Once**
        IF v_first_loop THEN
            v_unique_identifier := rec.uniqueIdentifier;
            v_first_loop := FALSE;

            -- **Use target.UNIQUE_IDENTIFIER in the ON condition**
            v_merge_sql := 'MERGE INTO ' || p_tgt_table || ' target USING (SELECT ';
        END IF;
        
        -- **Ensure Fields Are Included in SELECT Statement (with Casting)**
        IF rec.tgtType LIKE 'NUMBER%' THEN
            v_merge_sql := v_merge_sql || 'CAST(' || rec.srcField || ' AS NUMBER) AS ' || rec.tgtField || ', ';
        ELSE
            v_merge_sql := v_merge_sql || 'CAST(' || rec.srcField || ' AS ' || rec.tgtType || ') AS ' || rec.tgtField || ', ';
        END IF;

        -- **Exclude Unique Identifier from UPDATE SET**
        IF rec.tgtField <> v_unique_identifier THEN
            v_update_columns := v_update_columns || 'target.' || rec.tgtField || ' = source.' || rec.tgtField || ', ';
        END IF;

        -- **Ensure Fields Are Included in INSERT**
        v_insert_columns := v_insert_columns || rec.tgtField || ', ';
        v_insert_values := v_insert_values || 'source.' || rec.tgtField || ', ';
    END LOOP;

    -- **Construct Final MERGE Statement with WHERE condition**
    v_merge_sql := RTRIM(v_merge_sql, ', ') || ' FROM ' || p_src_table || ' WHERE IS_CHANGED = 1) source ON (' ||
                   'target.UNIQUE_IDENTIFIER = source.' || v_unique_identifier || ') ' ||
                   'WHEN MATCHED THEN UPDATE SET ' || RTRIM(v_update_columns, ', ') ||
                   ' WHEN NOT MATCHED THEN INSERT (' || RTRIM(v_insert_columns, ', ') || ') VALUES (' || RTRIM(v_insert_values, ', ') || ')';

    -- **Debugging: Print Final SQL**
    DBMS_OUTPUT.PUT_LINE('SQL: ' || v_merge_sql);

    -- **Update log**
    UPDATE LOAD_LOG_DETAIL SET SQL = v_merge_sql WHERE ID = p_load_log_detail_id;

    -- **Check Length Before Execution**
    IF LENGTH(v_merge_sql) > 32767 THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Query too long! Raising exception.');
        RAISE NO_DATA_FOUND;
    ELSE
        EXECUTE IMMEDIATE v_merge_sql;
        
        -- **Update source table to reset IS_CHANGED flag**
        EXECUTE IMMEDIATE 'UPDATE ' || p_src_table || ' SET IS_CHANGED = 0 WHERE IS_CHANGED = 1';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error occurred in PROCESS_OUT: ' || SQLERRM);
        RAISE_APPLICATION_ERROR(-20002, 'An error occurred in PROCESS_OUT: ' || SQLERRM);
END PROCESS_OUT;