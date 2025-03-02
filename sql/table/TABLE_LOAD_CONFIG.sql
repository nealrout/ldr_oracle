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
            STEP_CODE VARCHAR2(255) NOT NULL,
            CONFIG CLOB NULL,
            CREATE_TS TIMESTAMP WITH TIME ZONE,
            UPDATE_TS TIMESTAMP WITH TIME ZONE DEFAULT SYSTIMESTAMP
        )';

END;