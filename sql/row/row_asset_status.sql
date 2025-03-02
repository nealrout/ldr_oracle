BEGIN
    INSERT ALL
        INTO asset_status (status_code, create_ts) VALUES ('UNKNOWN', SYSTIMESTAMP)
        INTO asset_status (status_code, create_ts) VALUES ('up', SYSTIMESTAMP)
        INTO asset_status (status_code, create_ts) VALUES ('down', SYSTIMESTAMP)
        INTO asset_status (status_code, create_ts) VALUES ('partial', SYSTIMESTAMP)
    SELECT * FROM DUAL;
    
    COMMIT;
END;