DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM all_tables WHERE table_name = 'FACILITY' AND owner = 'DAAS';
    IF v_count > 0 THEN
        EXECUTE IMMEDIATE 'DROP TABLE facility CASCADE CONSTRAINTS PURGE';
    END IF;

    EXECUTE IMMEDIATE '
        CREATE TABLE facility (
            id NUMBER(19,0) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            account_id NUMBER(19,0) NOT NULL,
            facility_nbr VARCHAR2(250) NOT NULL,
            facility_code VARCHAR2(250),
            facility_name VARCHAR2(250),
            create_ts TIMESTAMP WITH TIME ZONE,
            update_ts TIMESTAMP WITH TIME ZONE DEFAULT SYSTIMESTAMP
        )';

    EXECUTE IMMEDIATE 'ALTER TABLE facility ADD CONSTRAINT unique_facility_nbr UNIQUE (facility_nbr)';
    
    SELECT COUNT(*) INTO v_count FROM user_indexes WHERE index_name = 'IDX_FACILITY_UPDATE_TS';
    IF v_count = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX IDX_FACILITY_UPDATE_TS ON facility(update_ts)';
    END IF;
    
    SELECT COUNT(*) INTO v_count FROM user_indexes WHERE index_name = 'IDX_FACILITY_CREATE_TS';
    IF v_count = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX IDX_FACILITY_CREATE_TS ON facility(create_ts)';
    END IF;
    
END;