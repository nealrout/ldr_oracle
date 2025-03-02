DECLARE
    v_count NUMBER;
BEGIN
------------------------------------------------------------------------
--                           USER
------------------------------------------------------------------------
    -- Check if the table exists
    SELECT COUNT(*) INTO v_count 
    FROM user_tables 
    WHERE table_name = 'TEMP_STAGE_USER';

    -- Drop the table if it exists
    IF v_count > 0 THEN
        EXECUTE IMMEDIATE 'DROP TABLE temp_stage_user';
    END IF;

    -- Create the Global Temporary Table
    EXECUTE IMMEDIATE '
        CREATE GLOBAL TEMPORARY TABLE temp_stage_user (
            id NUMBER(19,0),
            username NVARCHAR2(150),
            first_name NVARCHAR2(150),
            last_name NVARCHAR2(150),
            email NVARCHAR2(254)
        ) ON COMMIT DELETE ROWS';
------------------------------------------------------------------------
--                           ACCOUNT
------------------------------------------------------------------------
    -- Check if the table exists
    SELECT COUNT(*) INTO v_count 
    FROM user_tables 
    WHERE table_name = 'TEMP_STAGE_ACCOUNT';

    -- Drop the table if it exists
    IF v_count > 0 THEN
        EXECUTE IMMEDIATE 'DROP TABLE temp_stage_account';
    END IF;

    -- Create the Global Temporary Table
    EXECUTE IMMEDIATE '
        CREATE GLOBAL TEMPORARY TABLE temp_stage_account (
            id NUMBER(19,0),
            account_nbr VARCHAR2(255),
            account_code VARCHAR2(255),
            account_name VARCHAR2(255)
        ) ON COMMIT DELETE ROWS';
------------------------------------------------------------------------
--                           FACILITY
------------------------------------------------------------------------
    -- Check if the table exists
    SELECT COUNT(*) INTO v_count 
    FROM user_tables 
    WHERE table_name = 'TEMP_STAGE_FACILITY';

    -- Drop the table if it exists
    IF v_count > 0 THEN
        EXECUTE IMMEDIATE 'DROP TABLE temp_stage_facility';
    END IF;

    -- Create the Global Temporary Table
    EXECUTE IMMEDIATE '
        CREATE GLOBAL TEMPORARY TABLE temp_stage_facility (
            id NUMBER(19,0),
            target_account_id NUMBER(19,0),
            account_nbr VARCHAR2(255),
            facility_nbr VARCHAR2(255),
            facility_code VARCHAR2(255),
            facility_name VARCHAR2(255)
        ) ON COMMIT DELETE ROWS';

------------------------------------------------------------------------
--                           ASSET
------------------------------------------------------------------------
    -- Check if the table exists
    SELECT COUNT(*) INTO v_count 
    FROM user_tables 
    WHERE table_name = 'TEMP_STAGE_ASSET';

    -- Drop the table if it exists
    IF v_count > 0 THEN
        EXECUTE IMMEDIATE 'DROP TABLE temp_stage_asset';
    END IF;

    -- Create the Global Temporary Table
    EXECUTE IMMEDIATE '
        CREATE GLOBAL TEMPORARY TABLE temp_stage_asset (
            id NUMBER(19,0),
            facility_id NUMBER(19,0),
            facility_nbr VARCHAR2(255),
            asset_nbr VARCHAR2(255),
            sys_id VARCHAR2(255),
            asset_code VARCHAR2(255),
            status_code VARCHAR2(255)
        ) ON COMMIT DELETE ROWS';
------------------------------------------------------------------------
--                           SERVICE
------------------------------------------------------------------------
    -- Check if the table exists
    SELECT COUNT(*) INTO v_count 
    FROM user_tables 
    WHERE table_name = 'TEMP_STAGE_SERVICE';

    -- Drop the table if it exists
    IF v_count > 0 THEN
        EXECUTE IMMEDIATE 'DROP TABLE temp_stage_service';
    END IF;

    -- Create the Global Temporary Table
    EXECUTE IMMEDIATE '
        CREATE GLOBAL TEMPORARY TABLE temp_stage_service (
            id NUMBER(19,0),
            facility_id NUMBER(19,0),
            target_asset_id NUMBER(19,0),
            service_nbr VARCHAR2(255),
            service_code VARCHAR2(255),
            service_name VARCHAR2(255),
            status_code VARCHAR2(255)
        ) ON COMMIT DELETE ROWS';
------------------------------------------------------------------------
--                           USERFACILITY
------------------------------------------------------------------------
    -- Check if the table exists
    SELECT COUNT(*) INTO v_count 
    FROM user_tables 
    WHERE table_name = 'TEMP_STAGE_USERFACILITY';

    -- Drop the table if it exists
    IF v_count > 0 THEN
        EXECUTE IMMEDIATE 'DROP TABLE temp_stage_userfacility';
    END IF;

    -- Create the Global Temporary Table
    EXECUTE IMMEDIATE '
        CREATE GLOBAL TEMPORARY TABLE temp_stage_userfacility (
            user_id NUMBER(19,0),
            username NVARCHAR2(150),
            facility_nbr VARCHAR2(255),
            facility_id NUMBER(19,0)
        ) ON COMMIT DELETE ROWS';
END;