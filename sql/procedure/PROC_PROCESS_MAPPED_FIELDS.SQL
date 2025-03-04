CREATE OR REPLACE PROCEDURE PROCESS_MAPPED_FIELDS (
    p_load_log_id IN NUMBER,
    p_load_log_detail_id IN NUMBER,
    p_tgt_table IN VARCHAR2,
    p_src_table IN VARCHAR2
)
IS
    v_merge_sql VARCHAR2(32767);  
    v_update_columns VARCHAR2(32767) := '';
    v_insert_columns VARCHAR2(32767) := 'LOAD_LOG_ID, CREATE_TS, ';
    v_insert_values VARCHAR2(32767) := p_load_log_id || ', SYSTIMESTAMP, ';
    v_unique_identifier VARCHAR2(4000) := NULL;
    v_first_loop BOOLEAN := TRUE;
BEGIN
    -- **Step 1: Extract Unique Identifier & Mappings in One Query**
    FOR rec IN (
        WITH json_data AS (
            SELECT ID, STEP_CODE, SRC_TABLE, TGT_TABLE, CONFIG 
            FROM LOAD_CONFIG
            WHERE STEP_CODE = 'PROCESS_MAPPED'   
            AND UPPER(SRC_TABLE) = UPPER(p_src_table)
            AND UPPER(TGT_TABLE) = UPPER(p_tgt_table) 
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
        SELECT DISTINCT uniqueIdentifier, srcField, tgtField FROM cte_parsed_json
    ) LOOP
        -- **Initialize Unique Identifier & v_merge_sql Only Once**
        IF v_first_loop THEN
            v_unique_identifier := rec.uniqueIdentifier;
            v_first_loop := FALSE;

            v_merge_sql := 'MERGE INTO ' || p_tgt_table || ' target USING ' || p_src_table || ' source ON (' ||
                           'DBMS_LOB.SUBSTR(target.' || v_unique_identifier || ', 4000, 1) = ' ||
                           'DBMS_LOB.SUBSTR(source.' || v_unique_identifier || ', 4000, 1)) WHEN MATCHED THEN UPDATE SET ';
        END IF;
        
        -- **Exclude Unique Identifier from UPDATE SET**
        IF rec.tgtField <> v_unique_identifier THEN
            v_update_columns := v_update_columns || 'target.' || rec.tgtField || ' = source.' || rec.srcField || ', ';
        END IF;

        -- **Ensure Fields Are Included in INSERT**
        v_insert_columns := v_insert_columns || rec.tgtField || ', ';
        v_insert_values := v_insert_values || 'source.' || rec.srcField || ', ';
    END LOOP;

    -- **Ensure Unique Identifier is Included in INSERT Statement**
    IF v_unique_identifier IS NOT NULL AND INSTR(v_insert_columns, v_unique_identifier) = 0 THEN
        v_insert_columns := v_insert_columns || v_unique_identifier || ', ';
        v_insert_values := v_insert_values || 'source.' || v_unique_identifier || ', ';
    END IF;

    -- **Fix Trailing Commas**
    v_update_columns := RTRIM(v_update_columns, ', ');  
    v_insert_columns := RTRIM(v_insert_columns, ', ');  
    v_insert_values := RTRIM(v_insert_values, ', ');

    -- **Construct Final MERGE Statement**
    IF v_update_columns IS NOT NULL THEN
        v_merge_sql := v_merge_sql || ' ' || v_update_columns;
    ELSE
        v_merge_sql := REPLACE(v_merge_sql, 'WHEN MATCHED THEN UPDATE SET ', '');
    END IF;

    v_merge_sql := v_merge_sql || ' WHEN NOT MATCHED THEN INSERT (' || v_insert_columns || ') VALUES (' || v_insert_values || ')';

    -- **Append the WHERE NOT EXISTS condition dynamically**
    v_merge_sql := v_merge_sql || ' WHERE NOT EXISTS (' ||
                   'SELECT 1 FROM ERR_VALIDATION EV ' ||
                   'WHERE EV.LOAD_LOG_ID = ' || p_load_log_id || 
                   ' AND EV.UNIQUE_IDENTIFIER = ''' || v_unique_identifier || '''' ||
                   ' AND DBMS_LOB.SUBSTR(EV.UNIQUE_IDENTIFIER_VALUE, 4000, 1) = ' ||
                   'DBMS_LOB.SUBSTR(source.' || v_unique_identifier || ', 4000, 1))';

    -- **Debugging: Print Final SQL**
    DBMS_OUTPUT.PUT_LINE('SQL: ' || v_merge_sql);

    -- **Update log**
    UPDATE LOAD_LOG_DETAIL SET SQL = v_merge_sql WHERE ID = p_load_log_detail_id;

    -- **Check Length Before Execution**
    IF LENGTH(v_merge_sql) > 32767 THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Query too long! Switching to DBMS_SQL.PARSE().');
    ELSE
        EXECUTE IMMEDIATE v_merge_sql;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END PROCESS_MAPPED_FIELDS;
