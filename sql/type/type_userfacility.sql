BEGIN
------------------------------------------------------------------------------------
--                           USERFACILITY
------------------------------------------------------------------------------------
    -- Drop the types if they exist
    BEGIN
        EXECUTE IMMEDIATE 'DROP TYPE userfacility_table';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -4043 THEN
                RAISE;
            END IF;
    END;

    BEGIN
        EXECUTE IMMEDIATE 'DROP TYPE userfacility_record';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -4043 THEN
                RAISE;
            END IF;
    END;

    -- Create the types
    EXECUTE IMMEDIATE '
        CREATE OR REPLACE TYPE userfacility_record AS OBJECT (
            username VARCHAR2(255),
            facility_nbr CLOB
        )';

    EXECUTE IMMEDIATE '
        CREATE OR REPLACE TYPE userfacility_table AS TABLE OF userfacility_record';

------------------------------------------------------------------------------------
--                           USERFACILITY_BY_USER
------------------------------------------------------------------------------------
    -- Drop the types if they exist
    BEGIN
        EXECUTE IMMEDIATE 'DROP TYPE userfacility_by_user_table';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -4043 THEN
                RAISE;
            END IF;
    END;

    BEGIN
        EXECUTE IMMEDIATE 'DROP TYPE userfacility_by_user_record';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -4043 THEN
                RAISE;
            END IF;
    END;

    -- Create the types
    EXECUTE IMMEDIATE '
        CREATE OR REPLACE TYPE userfacility_by_user_record AS OBJECT (
            facility_nbr VARCHAR2(255)
        )';

    EXECUTE IMMEDIATE '
        CREATE OR REPLACE TYPE userfacility_by_user_table AS TABLE OF userfacility_by_user_record';

END;
/

