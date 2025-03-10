DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM all_tables WHERE table_name = 'SERVICE' AND owner = 'DAAS';
    IF v_count > 0 THEN
        EXECUTE IMMEDIATE 'DROP TABLE service CASCADE CONSTRAINTS PURGE';
    END IF;

    EXECUTE IMMEDIATE '
        CREATE TABLE service (
            id NUMBER(19,0) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            asset_id NUMBER(19,0) NOT NULL,
            service_nbr VARCHAR2(250) NOT NULL,
            service_code VARCHAR2(250),
            service_name VARCHAR2(250),
            status_code VARCHAR2(250) default ''UNKNOWN'' NOT NULL,
            create_ts TIMESTAMP WITH TIME ZONE,
            update_ts TIMESTAMP WITH TIME ZONE DEFAULT SYSTIMESTAMP
        )';

    EXECUTE IMMEDIATE 'ALTER TABLE service ADD CONSTRAINT unique_service_nbr UNIQUE (service_nbr)';

    SELECT COUNT(*) INTO v_count FROM user_indexes WHERE index_name = 'IDX_SERVICE_SERVICE_CODE';
    IF v_count = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX idx_service_service_code ON service(service_code, status_code)';
    END IF;

    SELECT COUNT(*) INTO v_count FROM user_indexes WHERE index_name = 'IDX_SERVICE_UPDATE_TS';
    IF v_count = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX idx_service_update_ts ON service(update_ts)';
    END IF;

    SELECT COUNT(*) INTO v_count FROM user_indexes WHERE index_name = 'IDX_SERVICE_CREATE_TS';
    IF v_count = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX idx_service_create_ts ON service(create_ts)';
    END IF;
    
END;