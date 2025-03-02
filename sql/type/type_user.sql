BEGIN
    -- Drop the types if they exist
    BEGIN
        EXECUTE IMMEDIATE 'DROP TYPE user_table';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -4043 THEN
                RAISE;
            END IF;
    END;

    BEGIN
        EXECUTE IMMEDIATE 'DROP TYPE user_record';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -4043 THEN
                RAISE;
            END IF;
    END;

    -- Create the types
    EXECUTE IMMEDIATE '
        CREATE OR REPLACE TYPE user_record AS OBJECT (
            username VARCHAR2(255),
            first_name VARCHAR2(255),
            last_name VARCHAR2(255),
            email VARCHAR2(255),
            is_staff NUMBER(1),
            is_superuser NUMBER(1),
            is_active NUMBER(1),
            facility_nbr CLOB
        )';

    EXECUTE IMMEDIATE '
        CREATE OR REPLACE TYPE user_table AS TABLE OF user_record';
END;
/
