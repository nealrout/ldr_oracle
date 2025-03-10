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
            account_nbr VARCHAR2(250) NOT NULL,
            account_code VARCHAR2(250),
            account_name VARCHAR2(250),
            country VARCHAR2(250),
            state VARCHAR2(250),
            county_code VARCHAR2(250),
            asset_count NUMBER,
            create_ts TIMESTAMP WITH TIME ZONE,
            update_ts TIMESTAMP WITH TIME ZONE DEFAULT SYSTIMESTAMP
        )';

    EXECUTE IMMEDIATE 'ALTER TABLE account ADD CONSTRAINT unique_account_nbr UNIQUE (account_nbr)';
    
    SELECT COUNT(*) INTO v_count FROM user_indexes WHERE index_name = 'IDX_ACCOUNT_UPDATE_TS';
    IF v_count = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX IDX_ACCOUNT_UPDATE_TS ON account(update_ts)';
    END IF;

    SELECT COUNT(*) INTO v_count FROM user_indexes WHERE index_name = 'IDX_ACCOUNT_CREATE_TS';
    IF v_count = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX IDX_ACCOUNT_CREATE_TS ON account(create_ts)';
    END IF;
END;