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


SELECT b.TITLE, b.AUTHOR
FROM books b
JOIN editions e ON b.TITLE = e.TITLE AND b.AUTHOR = e.AUTHOR
JOIN copies c ON e.ISBN = c.ISBN
LEFT JOIN loans l ON c.SIGNATURE = l.SIGNATURE
GROUP BY b.TITLE, b.AUTHOR
HAVING COUNT(DISTINCT e.LANGUAGE) >= 3
   AND COUNT(l.SIGNATURE) = 0;


UPDATE editions 
SET language = 'gallego' 
WHERE isbn = '978-84-683-5157-5' 
AND title = 'Ben'; 

SELECT d.fullname,
       FLOOR(MONTHS_BETWEEN(SYSDATE, d.birthdate) / 12) AS age,
       FLOOR(MONTHS_BETWEEN(SYSDATE, d.cont_start) / 12) AS seniority,
       COUNT(DISTINCT EXTRACT(YEAR FROM a.taskdate)) AS active_years,
       COUNT(DISTINCT s.town) / COUNT(DISTINCT EXTRACT(YEAR FROM a.taskdate)) AS stops_per_active_year,
       COUNT(DISTINCT l.signature) / COUNT(DISTINCT EXTRACT(YEAR FROM a.taskdate)) AS loans_per_active_year,
       NVL(
           TRUNC(100 * COUNT(CASE WHEN l.return IS NULL AND l.signature IS NOT NULL THEN 1 END)
           / NULLIF(COUNT(l.signature), 0), 3), 0
       ) || '%' AS percent_unreturned  --We truncate to 3 decimals and add '%'
FROM drivers d
JOIN assign_drv a ON d.passport = a.passport
JOIN stops s ON a.route_id = s.route_id
JOIN services sv ON a.passport = sv.passport
LEFT JOIN loans l ON l.town = sv.town AND sv.taskdate = l.stopdate AND sv.passport = a.passport
GROUP BY d.fullname, d.birthdate, d.cont_start;

INSERT INTO loans (SIGNATURE, USER_ID, STOPDATE, TOWN, PROVINCE, TYPE, TIME, RETURN) 
VALUES ('PD137', '0546923640', TO_DATE('20-NOV-2024', 'DD-MON-YYYY'), 'Sotoverde de Debajo', 'Castellón', 'L', 120, NULL); 

INSERT INTO loans (SIGNATURE, USER_ID, STOPDATE, TOWN, PROVINCE, TYPE, TIME, RETURN) 
VALUES ('NB427', '0546923640', TO_DATE('20-NOV-2024', 'DD-MON-YYYY'), 'Sotoverde de Debajo', 'Castellón', 'L', 120, NULL); 

INSERT INTO loans (SIGNATURE, USER_ID, STOPDATE, TOWN, PROVINCE, TYPE, TIME, RETURN) 
VALUES ('GL007', '0546923640', TO_DATE('20-NOV-2024', 'DD-MON-YYYY'), 'Sotoverde de Debajo', 'Castellón', 'L', 120, NULL); 


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