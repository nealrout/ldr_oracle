DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM all_tables WHERE table_name = 'ASSET_STATUS' AND owner = 'DAAS';
    IF v_count > 0 THEN
        EXECUTE IMMEDIATE 'DROP TABLE asset_status CASCADE CONSTRAINTS PURGE';
    END IF;
    
    EXECUTE IMMEDIATE '
        CREATE TABLE asset_status (
            status_code VARCHAR2(250) PRIMARY KEY,
            create_ts TIMESTAMP WITH TIME ZONE,
            update_ts TIMESTAMP WITH TIME ZONE DEFAULT SYSTIMESTAMP
        )';
END;