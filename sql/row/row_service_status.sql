BEGIN
    INSERT ALL
        INTO service_status (status_code, create_ts) VALUES ('UNKNOWN', SYSTIMESTAMP)
        INTO service_status (status_code, create_ts) VALUES ('open', SYSTIMESTAMP)
        INTO service_status (status_code, create_ts) VALUES ('close', SYSTIMESTAMP)
    SELECT * FROM DUAL;
    
    COMMIT;
END;