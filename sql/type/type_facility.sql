BEGIN
    -- Drop the types if they exist
    BEGIN
        EXECUTE IMMEDIATE 'DROP TYPE facility_table';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -4043 THEN
                RAISE;
            END IF;
    END;

    BEGIN
        EXECUTE IMMEDIATE 'DROP TYPE facility_record';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -4043 THEN
                RAISE;
            END IF;
    END;

    -- Create the types
    EXECUTE IMMEDIATE '
        CREATE OR REPLACE TYPE facility_record AS OBJECT (
            account_nbr VARCHAR2(255),
            facility_nbr VARCHAR2(255),
            facility_code VARCHAR2(255),
            facility_name VARCHAR2(255),
            create_ts TIMESTAMP WITH TIME ZONE,
            update_ts TIMESTAMP WITH TIME ZONE
        )';

    EXECUTE IMMEDIATE '
        CREATE OR REPLACE TYPE facility_table AS TABLE OF facility_record';
END;
/
