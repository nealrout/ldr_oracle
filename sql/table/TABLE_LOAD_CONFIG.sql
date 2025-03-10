DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM all_tables WHERE table_name = 'LOAD_CONFIG' AND owner = 'DAAS';
    IF v_count > 0 THEN
        EXECUTE IMMEDIATE 'DROP TABLE LOAD_CONFIG CASCADE CONSTRAINTS PURGE';
    END IF;

    EXECUTE IMMEDIATE '
        CREATE TABLE LOAD_CONFIG (
            ID NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            ALIAS VARCHAR2(250),
            STEP_CODE VARCHAR2(250) NOT NULL,
            STEP_ORDER NUMBER,
            SRC_TABLE VARCHAR2(250),
            TGT_TABLE VARCHAR2(250),
            CONFIG CLOB,
            CREATE_TS TIMESTAMP WITH TIME ZONE,
            UPDATE_TS TIMESTAMP WITH TIME ZONE DEFAULT SYSTIMESTAMP,
            CONSTRAINT UNIQUE_STEP_CODE_SRC_TABLE_TGT_TABLE UNIQUE (STEP_CODE, SRC_TABLE, TGT_TABLE)
        )';

END;