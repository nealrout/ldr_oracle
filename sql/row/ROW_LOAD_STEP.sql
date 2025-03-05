BEGIN
    INSERT ALL
        INTO LOAD_STEP (STEP_CODE, STEP_NUMBER, DESCRIPTION, CREATE_TS) VALUES ('VALIDATE', 1, 'VALIDATIONS - FIELD MUST BE INTEGER, MAX LENGTH', SYSTIMESTAMP)
        INTO LOAD_STEP (STEP_CODE, STEP_NUMBER, DESCRIPTION, CREATE_TS) VALUES ('MAP_FIELDS', 2, 'MAP SRC TO TGT', SYSTIMESTAMP)
        INTO LOAD_STEP (STEP_CODE, STEP_NUMBER, DESCRIPTION, CREATE_TS) VALUES ('TRANSFORM_INLINE', 3, 'INLINE FUNCTIONS - SUBSTR, TRANSLATE, TRIM', SYSTIMESTAMP)
        INTO LOAD_STEP (STEP_CODE, STEP_NUMBER, DESCRIPTION, CREATE_TS) VALUES ('TRANSFORM_AGGREGATE', 4, 'AGGREGATE TRANSFORMATIONS - SUM, COUNT', SYSTIMESTAMP)
        INTO LOAD_STEP (STEP_CODE, STEP_NUMBER, DESCRIPTION, CREATE_TS) VALUES ('OUT', 5, 'WRITE DATA OUT TO MAIN TABLES', SYSTIMESTAMP)
    SELECT * FROM DUAL;
    
    COMMIT;
END;