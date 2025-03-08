DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM all_tables WHERE table_name = 'LOAD_LOG' AND owner = 'DAAS';
    IF v_count > 0 THEN
        EXECUTE IMMEDIATE 'DROP TABLE LOAD_LOG CASCADE CONSTRAINTS PURGE';
    END IF;

    EXECUTE IMMEDIATE '
        CREATE TABLE LOAD_LOG (
            ID NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            STATUS_CODE VARCHAR2(255) not null,
            START_TS TIMESTAMP WITH TIME ZONE null,
            END_TS TIMESTAMP WITH TIME ZONE DEFAULT SYSTIMESTAMP,
            EXCEPTION_MSG CLOB,
            EXCEPTION_STACK CLOB,
            EXCEPTION_CODE VARCHAR2(255)
        )';

END;