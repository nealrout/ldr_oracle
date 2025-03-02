BEGIN
    INSERT ALL
        INTO LOAD_STEP_TYPE (STEP_CODE, DESCRIPTION, CREATE_TS) VALUES ('PROCESS_NON_MAPPED', 'ASDF', SYSTIMESTAMP)
        INTO LOAD_STEP_TYPE (STEP_CODE, DESCRIPTION, CREATE_TS) VALUES ('PROCESS_MAPPED', 'ASDF', SYSTIMESTAMP)
        INTO LOAD_STEP_TYPE (STEP_CODE, DESCRIPTION, CREATE_TS) VALUES ('VALIDATE', 'ASDF', SYSTIMESTAMP)
        INTO LOAD_STEP_TYPE (STEP_CODE, DESCRIPTION, CREATE_TS) VALUES ('TRANSFORM_INLINE', 'ASDF', SYSTIMESTAMP)
        INTO LOAD_STEP_TYPE (STEP_CODE, DESCRIPTION, CREATE_TS) VALUES ('TRANSFORM_AGGREGATE', 'ASDF', SYSTIMESTAMP)
    SELECT * FROM DUAL;
    
    COMMIT;
END;