BEGIN
	EXECUTE IMMEDIATE 'ALTER TABLE LOAD_LOG MODIFY ID NUMBER GENERATED BY DEFAULT AS IDENTITY';
	INSERT INTO LOAD_LOG (ID, STATUS_CODE, START_TS) VALUES (-1,'SUCCESS', SYSTIMESTAMP);
	EXECUTE IMMEDIATE 'ALTER TABLE LOAD_LOG MODIFY ID NUMBER GENERATED ALWAYS AS IDENTITY';
END;