BEGIN
    -- Drop the types if they exist
    BEGIN
        EXECUTE IMMEDIATE 'DROP TYPE service_table';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -4043 THEN
                RAISE;
            END IF;
    END;

    BEGIN
        EXECUTE IMMEDIATE 'DROP TYPE service_record';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -4043 THEN
                RAISE;
            END IF;
    END;

    -- Create the types
    EXECUTE IMMEDIATE '
        CREATE OR REPLACE TYPE service_record AS OBJECT (
            account_nbr VARCHAR2(255),
            facility_nbr VARCHAR2(255),
            asset_nbr VARCHAR2(255),
            sys_id VARCHAR2(255),
            service_nbr VARCHAR2(255),
            service_code VARCHAR2(255),
            service_name VARCHAR2(255),
            status_code VARCHAR2(255),
            create_ts TIMESTAMP WITH TIME ZONE,
            update_ts TIMESTAMP WITH TIME ZONE
        )';

    EXECUTE IMMEDIATE '
        CREATE OR REPLACE TYPE service_table AS TABLE OF service_record';
END;
/

