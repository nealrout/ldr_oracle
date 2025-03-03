BEGIN
    VALIDATE_AND_INSERT_ERRORS(
        p_load_log_id => -1,
        p_load_log_detail_id => -1,
        p_src_table => 'STG_INPUT_01',
        p_tgt_table => 'ERR_VALIDATION'
    );
END;

BEGIN
    PROCESS_MAPPED_FIELDS(
        p_load_log_id => -1,           
        p_load_log_detail_id => -1,    
        p_target_table => 'STG_INPUT_01',  
        p_source_table => 'LDR_01' 
    );
END;
/
