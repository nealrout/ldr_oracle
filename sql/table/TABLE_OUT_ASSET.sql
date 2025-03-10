DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM all_tables WHERE table_name = 'ASSET' AND owner = 'DAAS';
    IF v_count > 0 THEN
        EXECUTE IMMEDIATE 'DROP TABLE asset CASCADE CONSTRAINTS PURGE';
    END IF;

    EXECUTE IMMEDIATE '
        CREATE TABLE asset (
            id NUMBER(19,0) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            facility_id NUMBER(19,0) NOT NULL,
            asset_nbr VARCHAR2(250) NOT NULL,
            asset_code VARCHAR2(250),
            sys_id VARCHAR2(250),
            status_code VARCHAR2(250) default ''UNKNOWN'' NOT NULL,
            create_ts TIMESTAMP WITH TIME ZONE,
            update_ts TIMESTAMP WITH TIME ZONE DEFAULT SYSTIMESTAMP
        )';

    EXECUTE IMMEDIATE 'ALTER TABLE asset ADD CONSTRAINT unique_asset_nbr UNIQUE (asset_nbr)';

    SELECT COUNT(*) INTO v_count FROM user_indexes WHERE index_name = 'IDX_ASSET_ASSET_NBR';
    IF v_count = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX idx_asset_asset_nbr ON asset(asset_nbr, status_code)';
    END IF;
    
    SELECT COUNT(*) INTO v_count FROM user_indexes WHERE index_name = 'IDX_ASSET_SYS_ID';
    IF v_count = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX idx_asset_sys_id ON asset(sys_id, status_code)';
    END IF;
    
    SELECT COUNT(*) INTO v_count FROM user_indexes WHERE index_name = 'IDX_ASSET_UPDATE_TS';
    IF v_count = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX idx_asset_update_ts ON asset(update_ts)';
    END IF;

    SELECT COUNT(*) INTO v_count FROM user_indexes WHERE index_name = 'IDX_ASSET_CREATE_TS';
    IF v_count = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX idx_asset_create_ts ON asset(create_ts)';
    END IF;

END;