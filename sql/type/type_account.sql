BEGIN
    -- Drop the types if they exist
    BEGIN
        EXECUTE IMMEDIATE 'DROP TYPE account_table';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -4043 THEN
                RAISE;
            END IF;
    END;

    BEGIN
        EXECUTE IMMEDIATE 'DROP TYPE account_record';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -4043 THEN
                RAISE;
            END IF;
    END;

    -- Create the types
    EXECUTE IMMEDIATE '
        CREATE OR REPLACE TYPE account_record AS OBJECT (
            account_nbr VARCHAR2(255),
            account_code VARCHAR2(255),
            account_name VARCHAR2(255),
            facility_nbr CLOB
        )';

    EXECUTE IMMEDIATE '
        CREATE OR REPLACE TYPE account_table AS TABLE OF account_record';
END;
/
