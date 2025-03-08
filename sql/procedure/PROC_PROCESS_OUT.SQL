/*====================================================================================
    PROCEDURE:   PROCESS_OUT
    PURPOSE:     This procedure processes data from a source table and merges it 
                 into a target table dynamically based on mappings stored in the 
                 LOAD_CONFIG table.
                 
                 The procedure:
                 1. Extracts mapping configurations from JSON data where STEP_CODE = 'OUT'.
                 2. Dynamically constructs a SQL MERGE statement.
                 3. Joins with foreign key tables if necessary.
                 4. Updates existing records if a match is found based on UNIQUE_IDENTIFIER.
                 5. Inserts new records if no match is found.
                 6. Logs the generated SQL and ensures proper exception handling.

    PARAMETERS:
    --------------------------------------------------------------------------------
    | Parameter Name       | Type      | Description                               |
    --------------------------------------------------------------------------------
    | p_load_log_id        | NUMBER    | ID of the load log entry                  |
    | p_load_log_detail_id | NUMBER    | ID of the detailed log entry              |
    | p_src_table          | VARCHAR2  | Name of the source table (STG)            |
    | p_tgt_table          | VARCHAR2  | Name of the target table (LDR)            |
    --------------------------------------------------------------------------------

    EXCEPTION HANDLING:
        - Captures errors and logs them with SQL error message and stack trace.
        - Uses RAISE_APPLICATION_ERROR to propagate errors for debugging.
        - Ensures that the procedure does not leave partial transactions.

    AUTHOR:       [NEAL ROUTSON]
    CREATED ON:   [2025-03-01]
    
    REVISION HISTORY:
    -------------------------------------------------------------------------------
    | Date       | Author       | Description of Changes                          |
    -------------------------------------------------------------------------------
    | 2025-03-08 | Neal Routson | Initial Version                                 |
    -------------------------------------------------------------------------------
====================================================================================*/
CREATE OR REPLACE PROCEDURE PROCESS_OUT (
    p_load_log_id IN NUMBER,
    p_load_log_detail_id IN NUMBER,
    p_src_table IN VARCHAR2,
    p_tgt_table IN VARCHAR2
)
IS
    v_merge_sql VARCHAR2(32767);  
    v_update_columns VARCHAR2(32767) := '';
    v_insert_columns VARCHAR2(32767) := 'CREATE_TS, ';
    v_insert_values VARCHAR2(32767) := 'SYSTIMESTAMP, ';
    v_unique_identifier VARCHAR2(4000) := NULL;
    v_first_loop BOOLEAN := TRUE;
	v_fkTable VARCHAR2(4000);
	v_fkSrcField VARCHAR2(4000);
	v_fkTgtFieldName VARCHAR2(4000);
	v_fkTgtFieldNameId VARCHAR2(4000);

    v_procedure_name VARCHAR2(100);
    v_error_message VARCHAR2(4000);
    v_error_stack   VARCHAR2(4000);
BEGIN
    v_procedure_name := REGEXP_SUBSTR(DBMS_UTILITY.FORMAT_CALL_STACK, 'procedure ([^ ]+)', 1, 1, NULL, 1);

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
		        DBMS_LOB.SUBSTR(jt.fkTable, 4000, 1) AS fkTable,
		        DBMS_LOB.SUBSTR(jt.fkSrcField, 4000, 1) AS fkSrcField,
		        DBMS_LOB.SUBSTR(jt.fkTgtFieldName, 4000, 1) AS fkTgtFieldName,
		        DBMS_LOB.SUBSTR(jt.fkTgtFieldNameId, 4000, 1) AS fkTgtFieldNameId,
		        DBMS_LOB.SUBSTR(jt.srcField, 4000, 1) AS srcField, 
		        DBMS_LOB.SUBSTR(jt.tgtField, 4000, 1) AS tgtField,
		        DBMS_LOB.SUBSTR(jt.tgtType, 4000, 1) AS tgtType
		    FROM json_data j,
		    JSON_TABLE(j.CONFIG, '$' 
		        COLUMNS (
		            uniqueIdentifier CLOB PATH '$.uniqueIdentifier',
		            fkTable CLOB PATH '$.fkTable',
		            fkSrcField CLOB PATH '$.fkSrcField',
		            fkTgtFieldName CLOB PATH '$.fkTgtFieldName',
		            fkTgtFieldNameId CLOB PATH '$.fkTgtFieldNameId',
		            NESTED PATH '$.mappings[*]' 
		            COLUMNS (
		                srcField CLOB PATH '$.srcField',
		                tgtField CLOB PATH '$.tgtField',
		                tgtType CLOB PATH '$.tgtType'
		                )
		            )
		        ) jt
		    )
		    SELECT DISTINCT uniqueIdentifier, fkTable, fkSrcField, fkTgtFieldName, fkTgtFieldNameId, srcField, tgtField, tgtType 
		    FROM cte_parsed_json
    ) LOOP

        IF v_first_loop THEN
            v_unique_identifier := rec.uniqueIdentifier;
			v_fkTable := rec.fkTable;
			v_fkSrcField := rec.fkSrcField;
			v_fkTgtFieldName := rec.fkTgtFieldName;
			v_fkTgtFieldNameId := rec.fkTgtFieldNameId;
            v_first_loop := FALSE;

            v_merge_sql := 'MERGE INTO ' || p_tgt_table || ' target USING (SELECT UNIQUE_IDENTIFIER, ';
            
            -- ADD FK FIELD INSERT IF CONFIGURED
            IF COALESCE(v_fkTable, v_fkSrcField, v_fkTgtFieldName, v_fkTgtFieldNameId) IS NOT NULL THEN
            	v_merge_sql := v_merge_sql || ' F.ID AS '||  v_fkTgtFieldNameId || ',';
            	v_insert_columns := v_insert_columns || v_fkTgtFieldNameId || ', ';
		        v_insert_values := v_insert_values || 'source.' || v_fkTgtFieldNameId || ', ';
            END IF;
            
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
        ELSE
        	-- ADD FK FIELD UPDATE IF CONFIGURED
        	IF COALESCE(v_fkTable, v_fkSrcField, v_fkTgtFieldName, v_fkTgtFieldNameId) IS NOT NULL THEN
	        	v_update_columns := v_update_columns || 'target.' || v_fkTgtFieldNameId || ' = source.' || v_fkTgtFieldNameId || ', ';
        	END IF;
        END IF;

        -- **Ensure Fields Are Included in INSERT**
        v_insert_columns := v_insert_columns || rec.tgtField || ', ';
        v_insert_values := v_insert_values || 'source.' || rec.tgtField || ', ';
    END LOOP;

    -- **Construct Final MERGE Statement with WHERE condition**
    v_merge_sql := RTRIM(v_merge_sql, ', ') || ' FROM ' || p_src_table || ' L ';
    
    -- ONLY JOIN TO FK TABLE IF IT IS CONFIGURED TO DO SO.
    IF COALESCE(v_fkTable, v_fkSrcField, v_fkTgtFieldName, v_fkTgtFieldNameId) IS NOT NULL THEN
    	v_merge_sql := v_merge_sql || ' JOIN ' || v_fkTable || ' F ON L.' || v_fkSrcField || '= F.' || v_fkTgtFieldName;
    END IF;
    
    v_merge_sql := v_merge_sql ||' WHERE IS_CHANGED = 1) source ON (' ||
                   'source.UNIQUE_IDENTIFIER = target.'|| v_unique_identifier ||') ' ||
                   'WHEN MATCHED THEN UPDATE SET ' || RTRIM(v_update_columns, ', ') ||
                   ' WHEN NOT MATCHED THEN INSERT (' || RTRIM(v_insert_columns, ', ') || ') VALUES (' || RTRIM(v_insert_values, ', ') || ')';

    DBMS_OUTPUT.PUT_LINE('SQL: ' || v_merge_sql);

    -- **Update log**
    UPDATE LOAD_LOG_DETAIL SET SQL = v_merge_sql WHERE ID = p_load_log_detail_id;
    COMMIT;

    -- **Check Length Before Execution**
    IF LENGTH(v_merge_sql) > 32767 THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Query too long! Raising exception.');
        RAISE NO_DATA_FOUND;
    ELSE
        EXECUTE IMMEDIATE v_merge_sql;
        
        -- **Update source table to reset IS_CHANGED flag**
        EXECUTE IMMEDIATE 'UPDATE ' || p_src_table || ' SET IS_CHANGED = 0 WHERE IS_CHANGED = 1';
        COMMIT;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        v_error_message := SQLERRM;
        v_error_stack := DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;

        RAISE_APPLICATION_ERROR(-20002, 
            'An error occurred in ' || v_procedure_name || ': ' || v_error_message || ' | STACK: ' || v_error_stack
        );
END PROCESS_OUT;
