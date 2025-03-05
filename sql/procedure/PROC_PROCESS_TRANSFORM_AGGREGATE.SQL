CREATE OR REPLACE PROCEDURE PROCESS_TRANSFORM_AGGREGATE(
    p_load_log_id IN NUMBER,
    p_load_log_detail_id IN NUMBER,
    p_src_table IN VARCHAR2,
    p_tgt_table IN VARCHAR2    
)
IS
    v_uniqueIdentifier VARCHAR2(4000);
    v_srcTable VARCHAR2(4000);
    v_tgtTable VARCHAR2(4000);
    v_fieldName VARCHAR2(4000);
    v_transformation CLOB;
    v_dynamic_query CLOB;
    v_update_stmt CLOB;
    v_existing_sql CLOB;  -- Holds the existing SQL CLOB content

    TYPE cur_type IS REF CURSOR;
    v_cursor cur_type;

    v_id_value VARCHAR2(4000);
    v_transformed_value VARCHAR2(4000);

BEGIN
    -- Fetch transformation details from LOAD_CONFIG
    FOR rec IN (
        WITH json_data AS (
            SELECT ID, STEP_CODE, SRC_TABLE, TGT_TABLE, CONFIG 
            FROM LOAD_CONFIG
            WHERE STEP_CODE = 'TRANSFORM_AGGREGATE'   
            AND UPPER(SRC_TABLE) = UPPER(p_src_table)
            AND UPPER(TGT_TABLE) = UPPER(p_tgt_table) 
        ) ,
        cte_parsed_json AS (
            SELECT 
                j.ID, 
                j.STEP_CODE,
                j.SRC_TABLE AS SRC_TABLE,  
                j.TGT_TABLE AS TGT_TABLE,  
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
        SELECT DISTINCT uniqueIdentifier, SRC_TABLE, TGT_TABLE, fieldName, transformation 
        FROM cte_parsed_json
    ) LOOP
        v_uniqueIdentifier := rec.uniqueIdentifier;
        v_srcTable := rec.SRC_TABLE;  
        v_tgtTable := rec.TGT_TABLE;  
        v_fieldName := rec.fieldName;
        v_transformation := rec.transformation;

        DBMS_OUTPUT.PUT_LINE(v_transformation);
        
        -- Open cursor to execute transformation query dynamically
        v_dynamic_query := v_transformation;
        DBMS_OUTPUT.PUT_LINE('HERE1');
        DBMS_OUTPUT.PUT_LINE(v_dynamic_query);
        OPEN v_cursor FOR v_dynamic_query;

		LOOP
		    FETCH v_cursor INTO v_id_value, v_transformed_value;
		    EXIT WHEN v_cursor%NOTFOUND;
		    
		    -- Convert CLOB to VARCHAR2 and handle NULL values
		    v_transformed_value := NVL(DBMS_LOB.SUBSTR(v_transformed_value, 4000, 1), 'NULL');
		
		    -- Build the UPDATE statement
		    v_update_stmt := 'UPDATE ' || v_tgtTable || 
		                     ' SET ' || v_fieldName || ' = ''' || v_transformed_value || ''' ' ||
		                     ' WHERE ' || v_uniqueIdentifier || ' = ''' || v_id_value || '''';
		
		    DBMS_OUTPUT.PUT_LINE(v_update_stmt);
		    
		    -- Retrieve the current SQL field content (CLOB) from LOAD_LOG_DETAIL
		    SELECT SQL INTO v_existing_sql FROM LOAD_LOG_DETAIL 
		    WHERE ID = p_load_log_detail_id 
		    FOR UPDATE;
		
		    -- Initialize CLOB if NULL
		    IF v_existing_sql IS NULL THEN
		        DBMS_LOB.CREATETEMPORARY(v_existing_sql, TRUE);
		    END IF;
		
		    -- Append new update statement to the CLOB field correctly
		    DBMS_LOB.APPEND(v_existing_sql, CHR(10) || v_update_stmt);
		
		    -- Update the SQL field with the appended CLOB content
		    UPDATE LOAD_LOG_DETAIL 
		    SET SQL = v_existing_sql
		    WHERE ID = p_load_log_detail_id;
		
		    -- Execute the dynamically built UPDATE statement
		    EXECUTE IMMEDIATE v_update_stmt;
		
		END LOOP;
		


        CLOSE v_cursor;
        
    END LOOP;
    
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        IF v_cursor%ISOPEN THEN
            CLOSE v_cursor;
        END IF;
        RAISE;
END PROCESS_TRANSFORM_AGGREGATE;
