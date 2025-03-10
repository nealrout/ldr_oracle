DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM all_tables WHERE table_name = 'ERR_VALIDATION' AND owner = 'DAAS';
    IF v_count > 0 THEN
        EXECUTE IMMEDIATE 'DROP TABLE ERR_VALIDATION CASCADE CONSTRAINTS PURGE';
    END IF;

    EXECUTE IMMEDIATE '
        CREATE TABLE ERR_VALIDATION (
            LOAD_LOG_ID NUMBER NOT NULL,
            LOAD_LOG_DETAIL_ID NUMBER NOT NULL,
            SRC_TABLE VARCHAR2(250),
            TGT_TABLE VARCHAR2(250),
            UNIQUE_IDENTIFIER VARCHAR2(4000),
            UNIQUE_IDENTIFIER_VALUE VARCHAR2(4000),
            FIELD_NAME VARCHAR2(250),
            FIELD_VALUE CLOB,
            VALIDATION VARCHAR2(4000),
            ERROR_CODE VARCHAR2(250),
            ERROR_MESSAGE VARCHAR2(4000),
            CREATE_TS TIMESTAMP WITH TIME ZONE
        )';

    
END;