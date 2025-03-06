DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM all_tables WHERE table_name = 'ACCOUNT' AND owner = 'DAAS';
    IF v_count > 0 THEN
        EXECUTE IMMEDIATE 'DROP TABLE account CASCADE CONSTRAINTS PURGE';
    END IF;

    EXECUTE IMMEDIATE '
        CREATE TABLE account (
            id NUMBER(19,0) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            account_nbr VARCHAR2(250) not null,
            account_code VARCHAR2(250) null,
            account_name VARCHAR2(250) null,
            country VARCHAR2(250) null,
            state VARCHAR2(250) null,
            county_code VARCHAR2(250) null,
            asset_count NUMBER null,
            create_ts TIMESTAMP WITH TIME ZONE null,
            update_ts TIMESTAMP WITH TIME ZONE DEFAULT SYSTIMESTAMP
        )';

    EXECUTE IMMEDIATE 'ALTER TABLE account ADD CONSTRAINT unique_account_nbr UNIQUE (account_nbr)';
    
    SELECT COUNT(*) INTO v_count FROM user_indexes WHERE index_name = 'IDX_ACCOUNT_UPDATE_TS';
    IF v_count = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX idx_account_update_ts ON account(update_ts)';
    END IF;

    SELECT COUNT(*) INTO v_count FROM user_indexes WHERE index_name = 'IDX_ACCOUNT_CREATE_TS';
    IF v_count = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX idx_account_create_ts ON account(create_ts)';
    END IF;
END;