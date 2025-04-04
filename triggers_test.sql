INSERT INTO users VALUES ('LIB001', 'ID123456789012345', 'Testing library', 'Sur1', 'Sur2', DATE '1970-01-01', 'Valsolana', 'Madrid', 'Fakestreet 123', 'lib@library.com', 123456789, 'L', NULL);

-- Dummy data for loans table
INSERT INTO loans VALUES ('CK239', 'LIB001', TRUNC(SYSDATE), 'Valsolana', 'Madrid', 'L', 0, TRUNC(SYSDATE)+14);

-- Try to insert a post with an institutional user
BEGIN
    INSERT INTO posts VALUES ('CK239', 'LIB001', TRUNC(SYSDATE), TRUNC(SYSDATE)+1, 'Posting a comment from an institutional user', 0, 0);
    DBMS_OUTPUT.PUT_LINE('Post inserted successfully (this should not happen).');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Expected error (posts not allowed for institutional users): ' || SQLERRM);
        ROLLBACK;
END;
/

UPDATE copies  
SET CONDITION = 'D'  
WHERE SIGNATURE IN ('CH068', 'IA676', 'AL204'); 

UPDATE copies 
SET CONDITION = 'D'
WHERE SIGNATURE = 'CH068';

UPDATE copies 
SET CONDITION = 'D'
WHERE SIGNATURE = 'XX777';

INSERT INTO loans (SIGNATURE, USER_ID, STOPDATE, TOWN, PROVINCE, TYPE, TIME, RETURN) 
VALUES ('PD137', '0546923640', TO_DATE('20-NOV-2024', 'DD-MON-YYYY'), 'Sotoverde de Debajo', 'Castellón', 'L', 120, NULL);

INSERT INTO loans (SIGNATURE, USER_ID, STOPDATE, TOWN, PROVINCE, TYPE, TIME, RETURN) 
VALUES ('XX777', '0546923640', TO_DATE('20-NOV-2024', 'DD-MON-YYYY'), 'Sotoverde de Debajo', 'Castellón', 'L', 120, NULL);