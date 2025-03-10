/*====================================================================================
    PROCEDURE:   WRAPPER
    PURPOSE:     This procedure orchestrates the execution of data processing steps
                 in a predefined sequence, ensuring proper error handling and
                 logging throughout the process.
                 
                 The procedure:
                 1. Manages the execution of multiple processing steps in order.
                 2. Checks for and recovers from failed or incomplete executions.
                 3. Logs execution status in the LOAD_LOG and LOAD_LOG_DETAIL tables.
                 4. Dynamically calls the appropriate procedures for each processing step.
                 5. Handles errors gracefully, logging error messages and stack traces.

    PARAMETERS:
    --------------------------------------------------------------------------------
    | Parameter Name  | Type      | Description                                     |
    --------------------------------------------------------------------------------
    | None           | N/A       | This procedure does not take input parameters   |
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

CREATE OR REPLACE PROCEDURE WRAPPER
IS
	v_table_name VARCHAR2(200);
    v_sql        VARCHAR2(500);
	v_count_running NUMBER;
	v_count_success NUMBER;
	v_count_failed NUMBER;
	v_count NUMBER;
	v_load_log_id NUMBER;
	v_load_log_detail_id NUMBER;
	v_load_step_code VARCHAR2(250);
	v_load_step_code_last_success VARCHAR2(250);
	v_load_step_first VARCHAR2(250);
	v_load_step_last VARCHAR2(250);
	v_load_step_next VARCHAR2(250);
	v_current_step_number NUMBER;
	v_max_step_number NUMBER;
	v_status_code_running VARCHAR2(10) := 'RUNNING';
	v_status_code_success VARCHAR2(10) := 'SUCCESS';
	v_status_code_failed VARCHAR2(10) := 'FAILED';

    TYPE ProcMap IS TABLE OF VARCHAR2(100) INDEX BY VARCHAR2(50);
    v_procedures ProcMap;
    -- Ordered list of steps
    TYPE StepList IS TABLE OF VARCHAR2(50);
--    v_steps StepList := StepList('VALIDATE', 'MAP_FIELDS', 'TRANSFORM_INLINE', 'TRANSFORM_AGGREGATE', 'LDR', 'OUT');
    v_steps StepList := StepList('VALIDATE', 'MAP_FIELDS', 'TRANSFORM_INLINE', 'TRANSFORM_AGGREGATE', 'LDR', 'OUT');

    v_start BOOLEAN := FALSE; -- Flag to start execution
    v_source_table VARCHAR2(250);
    v_target_table VARCHAR2(250);
	v_alias VARCHAR2(250);
BEGIN
	DBMS_OUTPUT.PUT_LINE('___________________________WRAPPER STARING___________________________');

	-- PRE-TRUNCATE ALL STG TABLES
	TRUNCATE_TABLES_BY_PREFIX('STG_MAP_');
	TRUNCATE_TABLES_BY_PREFIX('STG_TRANSFORM_');

	SELECT COUNT(*) INTO v_count_running FROM LOAD_LOG WHERE STATUS_CODE = v_status_code_running;
	SELECT COUNT(*) INTO v_count_success FROM LOAD_LOG WHERE STATUS_CODE = v_status_code_success;
	SELECT COUNT(*) INTO v_count_failed FROM LOAD_LOG WHERE STATUS_CODE = v_status_code_failed;
	
	SELECT STEP_CODE INTO v_load_step_first 
	FROM LOAD_STEP 
	ORDER BY STEP_NUMBER ASC
	FETCH FIRST 1 ROW ONLY;
	
	SELECT STEP_CODE INTO v_load_step_last 
	FROM LOAD_STEP 
	ORDER BY STEP_NUMBER DESC
	FETCH FIRST 1 ROW ONLY;
	
	SELECT MAX(STEP_NUMBER) INTO v_max_step_number
	FROM LOAD_STEP;
	/*************************************************************************************
	 * 									LOAD_LOG LOGIC
	 *************************************************************************************/
	
	IF v_count_running > 0 THEN
		SELECT ID INTO v_load_log_id FROM LOAD_LOG WHERE STATUS_CODE = v_status_code_running
		ORDER BY START_TS DESC
		FETCH FIRST 1 ROW ONLY;
	ELSE
		IF v_count_failed > 0 THEN
			SELECT ID INTO v_load_log_id FROM LOAD_LOG WHERE STATUS_CODE = v_status_code_failed
			ORDER BY START_TS DESC
			FETCH FIRST 1 ROW ONLY;
		ELSE
			DBMS_OUTPUT.PUT_LINE('INSERTING - LOAD_LOG - STATUS_CODE: ' || v_status_code_running);
			INSERT INTO LOAD_LOG (STATUS_CODE, START_TS) VALUES (v_status_code_running, SYSTIMESTAMP)
			RETURNING ID INTO v_load_log_id;
	
			COMMIT;
		END IF;
	END IF;
	
--	DBMS_OUTPUT.PUT_LINE('v_load_log_id: '|| v_load_log_id);
	
	SELECT COUNT(*) INTO v_count_running FROM LOAD_LOG_DETAIL WHERE LOAD_LOG_ID = v_load_log_id AND STATUS_CODE = v_status_code_running;
	SELECT COUNT(*) INTO v_count_success FROM LOAD_LOG_DETAIL WHERE LOAD_LOG_ID = v_load_log_id AND STATUS_CODE = v_status_code_success;
	SELECT COUNT(*) INTO v_count_failed FROM LOAD_LOG_DETAIL WHERE LOAD_LOG_ID = v_load_log_id AND STATUS_CODE = v_status_code_failed;
		
	/*************************************************************************************
	 * 								LOAD_LOG_DETAIL LOGIC
	 *************************************************************************************/
	IF v_count_running > 0 THEN															
		--RECOVER LAST RUNNING LOAD_LOG_DETAIL
		SELECT ID, STEP_CODE INTO v_load_log_detail_id, v_load_step_code
		FROM LOAD_LOG_DETAIL 
		WHERE LOAD_LOG_ID = v_load_log_id AND STATUS_CODE = v_status_code_running 
		ORDER BY START_TS DESC
		FETCH FIRST 1 ROW ONLY;
		DBMS_OUTPUT.PUT_LINE('RECOVERING - LOAD_LOG_DETAILS - STEP_CODE: ' || v_load_step_code || ', STATUS_CODE: ' || v_status_code_running);
	ELSIF v_count_failed > 0 THEN
		--RECOVER LAST FAILED LOAD_LOG_DETAIL														
		SELECT ID, STEP_CODE INTO v_load_log_detail_id, v_load_step_code
		FROM LOAD_LOG_DETAIL 
		WHERE LOAD_LOG_ID = v_load_log_id AND STATUS_CODE = v_status_code_failed 
		ORDER BY START_TS DESC
		FETCH FIRST 1 ROW ONLY;
		DBMS_OUTPUT.PUT_LINE('RECOVERING - LOAD_LOG_DETAILS - STEP_CODE: ' || v_load_step_code || ', STATUS_CODE: ' || v_status_code_failed);
	ELSIF v_count_running = 0 AND v_count_failed = 0 AND v_count_success > 0 THEN		
		-- NO RUNNING, NO FAILURE, START NEXT STEP
		SELECT STEP_CODE INTO v_load_step_code_last_success
		FROM LOAD_LOG_DETAIL
		WHERE LOAD_LOG_ID = v_load_log_id AND STATUS_CODE = v_status_code_success
		ORDER BY START_TS DESC
		FETCH FIRST 1 ROW ONLY;
	
		SELECT STEP_NUMBER INTO v_current_step_number
		FROM LOAD_STEP
		WHERE STEP_CODE = v_load_step_code_last_success;
		
		IF v_current_step_number < v_max_step_number THEN								
			-- ONLY SET NEXT STEP IF WE HAVE NOT SUCCEEEDED ON LAST POSSIBLE STEP IN THE CHAIN.
		
			SELECT STEP_CODE INTO v_load_step_code 
			FROM LOAD_STEP
			WHERE STEP_NUMBER = (v_current_step_number + 1);
			
			-- DBMS_OUTPUT.PUT_LINE('INSERTING - LOAD_LOG_DETAILS - STEP_CODE: ' || v_load_step_code || ', STATUS_CODE: ' || v_status_code_running);
			-- INSERT INTO LOAD_LOG_DETAIL (LOAD_LOG_ID, STEP_CODE, STATUS_CODE, START_TS)
			-- VALUES (v_load_log_id, v_load_step_code, v_status_code_running, SYSTIMESTAMP)
			-- RETURNING ID INTO v_load_log_detail_id;
			
			COMMIT;
		END IF;

	ELSE 																				
		-- BRAND NEW RUN OF LOAD_LOG_DETAILS

		-- DBMS_OUTPUT.PUT_LINE('INSERTING - LOAD_LOG_DETAILS - STEP_CODE: ' || v_load_step_first || ', STATUS_CODE: ' || v_status_code_running);
		-- INSERT INTO LOAD_LOG_DETAIL (LOAD_LOG_ID, STEP_CODE, STATUS_CODE, START_TS)
		-- VALUES (v_load_log_id, v_load_step_first, v_status_code_running, SYSTIMESTAMP)
		-- RETURNING ID INTO v_load_log_detail_id;
	
		-- COMMIT;
	
		v_load_step_code := v_load_step_first;
	END IF;
	
	
	DBMS_OUTPUT.PUT_LINE('DEBUG - v_load_log_id: ' || v_load_log_id || ', v_load_log_detail_id: '|| v_load_log_detail_id || ', v_load_step_code: ' || v_load_step_code);
	/*************************************************************************************
	 * 								PROCESSOR LOGIC
	 *************************************************************************************
	 *This will determine where we need to recover from.  The LOAD_STEP table had the 
	 *steps of this loader in order.  This will determien which step to start at based
	 *on the current v_load_step_code.  This was determined by looking at the LOAD_LOG_DETAIL
	 *table for our current LOAD_LOG.  If the previous job failed, or got stuck running, it will
	 *recover from that job forward.  Otherwise it will be fresh and run all of them in order.
	 *
	 */
	
    -- Initialize procedure mapping
    v_procedures('VALIDATE') := 'VALIDATE_AND_INSERT_ERRORS';
    v_procedures('MAP_FIELDS') := 'PROCESS_MAPPED_FIELDS';
    v_procedures('TRANSFORM_INLINE') := 'PROCESS_TRANSFORM_INLINE';
    v_procedures('TRANSFORM_AGGREGATE') := 'PROCESS_TRANSFORM_AGGREGATE';
	v_procedures('LDR') := 'PROCESS_MERGE_STG_TO_LDR';
	v_procedures('OUT') := 'PROCESS_OUT';

    -- Iterate over steps in order
    FOR i IN 1..v_steps.COUNT LOOP
        IF v_steps(i) = v_load_step_code THEN
            v_start := TRUE;  -- Found the start point, begin execution
        END IF;

        -- Execute only after reaching the start point
        IF v_start THEN
        	v_load_step_code := v_steps(i);
            DBMS_OUTPUT.PUT_LINE('##PROCESSING STEP - : ' || v_load_step_code);

            -- Open cursor dynamically for each step
            FOR rec IN (
                SELECT SRC_TABLE, TGT_TABLE, ALIAS
                FROM LOAD_CONFIG 
                WHERE STEP_CODE = v_steps(i)
				ORDER BY STEP_ORDER ASC
            ) LOOP
                v_source_table := rec.SRC_TABLE;
                v_target_table := rec.TGT_TABLE;
				v_alias := rec.ALIAS;
            
            	SELECT COUNT(*) INTO v_count FROM LOAD_LOG_DETAIL WHERE ID = v_load_log_detail_id AND SRC_TABLE IS NULL AND TGT_TABLE IS NULL;
            
            	IF v_count > 0 THEN
            		UPDATE LOAD_LOG_DETAIL SET SRC_TABLE = v_source_table, TGT_TABLE = v_target_table WHERE ID = v_load_log_detail_id;
            	ELSE
	            	DBMS_OUTPUT.PUT_LINE('INSERTING LOAD_LOG_DETAILS - STEP_CODE: ' || v_load_step_code || ', STATUS_CODE: ' || v_status_code_running);
					INSERT INTO LOAD_LOG_DETAIL (LOAD_LOG_ID, ALIAS, STEP_CODE, SRC_TABLE, TGT_TABLE, STATUS_CODE, START_TS)
					VALUES (v_load_log_id, v_alias, v_load_step_code, v_source_table, v_target_table, v_status_code_running, SYSTIMESTAMP)
					RETURNING ID INTO v_load_log_detail_id;
            	END IF;

            	DBMS_OUTPUT.PUT_LINE('****************************************************************************');
                DBMS_OUTPUT.PUT_LINE('####Executing: ' || v_procedures(v_load_step_code) || 
                                     ' ALIAS: ' || v_alias || 
                                     ' with SRC_TABLE: ' || v_source_table || 
                                     ', TGT_TABLE: ' || v_target_table ||
                					 ', v_load_log_id: ' || v_load_log_id ||
                					 ', v_load_log_detail_id: ' || v_load_log_detail_id);
            	DBMS_OUTPUT.PUT_LINE('****************************************************************************');

                BEGIN
	                EXECUTE IMMEDIATE 
	                    'BEGIN ' || v_procedures(v_load_step_code) || '(
	                        p_load_log_id => :1, 
	                        p_load_log_detail_id => :2, 
	                        p_src_table => :3,
	                        p_tgt_table => :4
	                    ); END;'
	                USING v_load_log_id, v_load_log_detail_id, v_source_table, v_target_table;
                
                    UPDATE LOAD_LOG_DETAIL SET STATUS_CODE = v_status_code_success, END_TS = SYSTIMESTAMP WHERE ID = v_load_log_detail_id;
		            COMMIT;
                    
					EXCEPTION
					    WHEN OTHERS THEN
					        DECLARE
					            v_error_message VARCHAR2(4000);
								v_error_code    VARCHAR2(4000);
					            v_error_stack   VARCHAR2(4000);
					        BEGIN
					            -- Capture error message and stack trace
					            v_error_message := SQLERRM;
								v_error_code := SQLCODE;
					            v_error_stack := DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
					
					            -- Print the error for debugging
					            DBMS_OUTPUT.PUT_LINE('!!!!!!!!!!!!!!!!! Error Occurred !!!!!!!!!!!!!!!!!!');
					            DBMS_OUTPUT.PUT_LINE('SQLCODE: ' || v_error_code);
					            DBMS_OUTPUT.PUT_LINE('ERROR MESSAGE: ' || v_error_message);
					            DBMS_OUTPUT.PUT_LINE('STACK TRACE: ' || v_error_stack);
					            DBMS_OUTPUT.PUT_LINE('!!!!!!!!!!!!!!!!! Error Occurred !!!!!!!!!!!!!!!!!!');
					
					            -- Store the error details in log tables
					            UPDATE LOAD_LOG_DETAIL  
					            SET STATUS_CODE = v_status_code_failed, EXCEPTION_MSG = v_error_message, EXCEPTION_STACK = v_error_stack, EXCEPTION_CODE = v_error_code
					            WHERE ID = v_load_log_detail_id;
					
					            UPDATE LOAD_LOG 
					            SET STATUS_CODE = v_status_code_failed, EXCEPTION_MSG = v_error_message, EXCEPTION_STACK = v_error_stack, EXCEPTION_CODE = v_error_code
					            WHERE ID = v_load_log_id;
					
					            COMMIT;
					
					            -- Raise application error with full details
					            RAISE_APPLICATION_ERROR(-20002, 'An error occurred in WRAPPER: ' || v_error_message || ' | STACK: ' || v_error_stack);
					        END;
				END;
            END LOOP; 
            

        END IF;
    END LOOP;
            
    UPDATE LOAD_LOG SET STATUS_CODE = v_status_code_success, END_TS = SYSTIMESTAMP WHERE ID = v_load_log_id;
    DBMS_OUTPUT.PUT_LINE('___________________________WRAPPER COMPLETED SUCCESSFULLY___________________________');

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error occurred in WRAPPER: ' || SQLERRM);
        UPDATE LOAD_LOG SET STATUS_CODE = v_status_code_failed WHERE ID = v_load_log_id;
        COMMIT;
        RAISE;
END WRAPPER;
