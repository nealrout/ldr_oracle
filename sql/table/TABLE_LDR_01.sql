DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM all_tables WHERE table_name = 'LDR_01' AND owner = 'DAAS';
    IF v_count > 0 THEN
        EXECUTE IMMEDIATE 'DROP TABLE LDR_01 CASCADE CONSTRAINTS PURGE';
    END IF;

    EXECUTE IMMEDIATE '
        CREATE TABLE LDR_01 (
            LOAD_LOG_ID NUMBER NOT NULL,
            CREATE_TS TIMESTAMP WITH TIME ZONE,
            UPDATE_TS TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            FIELD_001 CLOB,
            FIELD_002 CLOB,
            FIELD_003 CLOB,
            FIELD_004 CLOB,
            FIELD_005 CLOB,
            FIELD_006 CLOB,
            FIELD_007 CLOB,
            FIELD_008 CLOB,
            FIELD_009 CLOB,
            FIELD_010 CLOB,
            FIELD_011 CLOB,
            FIELD_012 CLOB,
            FIELD_013 CLOB,
            FIELD_014 CLOB,
            FIELD_015 CLOB,
            FIELD_016 CLOB,
            FIELD_017 CLOB,
            FIELD_018 CLOB,
            FIELD_019 CLOB,
            FIELD_020 CLOB,
            FIELD_021 CLOB,
            FIELD_022 CLOB,
            FIELD_023 CLOB,
            FIELD_024 CLOB,
            FIELD_025 CLOB,
            FIELD_026 CLOB,
            FIELD_027 CLOB,
            FIELD_028 CLOB,
            FIELD_029 CLOB,
            FIELD_030 CLOB,
            FIELD_031 CLOB,
            FIELD_032 CLOB,
            FIELD_033 CLOB,
            FIELD_034 CLOB,
            FIELD_035 CLOB,
            FIELD_036 CLOB,
            FIELD_037 CLOB,
            FIELD_038 CLOB,
            FIELD_039 CLOB,
            FIELD_040 CLOB,
            FIELD_041 CLOB,
            FIELD_042 CLOB,
            FIELD_043 CLOB,
            FIELD_044 CLOB,
            FIELD_045 CLOB,
            FIELD_046 CLOB,
            FIELD_047 CLOB,
            FIELD_048 CLOB,
            FIELD_049 CLOB,
            FIELD_050 CLOB
        )';

    
END;