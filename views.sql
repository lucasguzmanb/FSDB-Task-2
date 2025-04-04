CREATE OR REPLACE VIEW my_data AS
SELECT user_id, id_card, name, surname1, surname2, birthdate, town, province, address, email, phone
FROM users
WHERE user_id = USER;



CREATE OR REPLACE VIEW my_loans AS
SELECT 
    l.SIGNATURE,
    l.USER_ID,
    l.STOPDATE,
    l.RETURN,
    p.POST_DATE,
    p.TEXT,
    p.LIKES,
    p.DISLIKES
FROM loans l
LEFT JOIN posts p
    ON l.SIGNATURE = p.SIGNATURE
   AND l.USER_ID = p.USER_ID
   AND l.STOPDATE = p.STOPDATE
WHERE l.USER_ID = USER
  AND l.RETURN IS NOT NULL;




SET LINESIZE 200
SET PAGESIZE 50

COLUMN signature FORMAT A6
COLUMN user_id   FORMAT A10
COLUMN stopdate  FORMAT A12
COLUMN return    FORMAT A12
COLUMN post_date FORMAT A12
COLUMN text      FORMAT A50
COLUMN likes     FORMAT 9999
COLUMN dislikes  FORMAT 9999

SELECT * FROM my_loans;

UPDATE posts
SET text = 'This is a test update.', 
    post_date = SYSDATE
WHERE signature = 'YE049'
  AND user_id = '0501252527'
  AND stopdate = DATE '2024-11-12';



CREATE OR REPLACE VIEW my_reservations AS
SELECT
    l.USER_ID,
    l.SIGNATURE,
    c.ISBN,
    l.STOPDATE AS RESERVATION_DATE,
    l.RETURN AS RETURN_DATE
FROM loans l
JOIN copies c ON l.SIGNATURE = c.SIGNATURE
WHERE l.RETURN IS NULL
  AND l.USER_ID = '0501252527'
WITH CHECK OPTION;


INSERT INTO loans (SIGNATURE, USER_ID, STOPDATE, TOWN, PROVINCE, TYPE, TIME, RETURN)
SELECT SIGNATURE, '0501252527', TO_DATE('2025-04-05', 'YYYY-MM-DD'), 'TestTown', 'TestProvince', 'R', 0, NULL
FROM copies
WHERE ISBN = '978-84-204-8764-9'
  AND SIGNATURE NOT IN (
    SELECT SIGNATURE FROM loans WHERE RETURN IS NULL
)
FETCH FIRST 1 ROWS ONLY;

INSERT INTO loans (SIGNATURE, USER_ID, STOPDATE, TOWN, PROVINCE, TYPE, TIME, RETURN)
  2  SELECT SIGNATURE, '0501252527', TO_DATE('2024-11-23', 'YYYY-MM-DD'),
  3         'Atalaya del Viento', 'Cádiz', 'R', 0, NULL
  4  FROM copies
  5  WHERE ISBN = '978-84-204-8764-9'
  6    AND SIGNATURE NOT IN (
  7      SELECT SIGNATURE FROM loans WHERE RETURN IS NULL
  8  )
  9  FETCH FIRST 1 ROWS ONLY;


SELECT * FROM my_reservations;



DELETE FROM my_reservations
WHERE SIGNATURE = 'XK949';


SELECT * FROM copies
  2  WHERE ISBN = '978-84-204-8764-9'
  3    AND SIGNATURE NOT IN (
  4      SELECT SIGNATURE FROM loans WHERE RETURN IS NULL
  5  );

--0 rows selected since “Allows changing dates (provided that the book, or any other copy of the same ISBN, is available).”
porque no hay otra libre

INSERT INTO copies (SIGNATURE, ISBN, CONDITION)
VALUES ('XZ999', '978-84-204-8764-9', 'G');







