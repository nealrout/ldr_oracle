CREATE OR REPLACE PROCEDURE daas_log(p_level VARCHAR2, p_message VARCHAR2, p_file_name VARCHAR2, p_line_number NUMBER)
AS
BEGIN
    INSERT INTO log ("level", message, file_name, line_number, create_ts)
    VALUES (p_level, p_message, p_file_name, p_line_number, SYSDATE);
END;