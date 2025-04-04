-- Testing user
INSERT INTO users  VALUES (USER, 'TESTIDCARD1234567', 'TestName', 'TestSurname1', 'TestSurname2', TO_DATE('27-10-2004', 'DD-MM-YYYY'), 'Valsolana', 'Madrid', 'Test Address', 'test@example.com', 600000000, 'P', NULL);

-- Test my_data
SELECT user_id, name, birthdate FROM my_data;

-- Test my_loans
-- We insert a few loans and a comment to test the view and then select from it
DELETE FROM posts WHERE USER_ID = USER;
DELETE FROM loans WHERE USER_ID = USER;
INSERT INTO loans VALUES ('CK239', USER, TO_DATE('23-11-2024', 'DD-MM-YYYY'), 'Valsolana', 'Madrid', 'L', 0, TRUNC(SYSDATE) + 14);
INSERT INTO loans VALUES ('CK237', USER, TO_DATE('23-11-2024', 'DD-MM-YYYY'), 'Valsolana', 'Madrid', 'L', 0, TRUNC(SYSDATE) + 14);
INSERT INTO posts VALUES ('CK239', USER, TO_DATE('23-11-2024', 'DD-MM-YYYY'), TO_DATE('25-12-2024', 'DD-MM-YYYY'), 'Testing comment 1', 15, 2);
SELECT signature, stopdate, post_date, likes, dislikes, post FROM my_loans;

-- Now we try to update the post and check if the post_date is updated automatically
UPDATE my_loans SET post = 'Updated comment' WHERE signature = 'CK239' AND stopdate = TO_DATE('23-11-2024', 'DD-MM-YYYY');
SELECT signature, stopdate, post_date, likes, dislikes, post FROM my_loans;

-- Now we try to update any other field and check if it raises an error
UPDATE my_loans SET stopdate = TO_DATE('24-11-2024', 'DD-MM-YYYY') WHERE signature = 'CK239' AND stopdate = TO_DATE('23-11-2024', 'DD-MM-YYYY');

-- Test my_reservations


INSERT INTO assign_drv (passport, taskdate, route_id)
VALUES (
  'ESP>>101010101010',
  TO_DATE('01-12-2024', 'DD-MM-YYYY'),
  'MA-03'
);
INSERT INTO assign_bus (plate, taskdate, route_id)
VALUES (
  'BUS-011',
  TO_DATE('01-12-2024', 'DD-MM-YYYY'),
  'MA-03'
);
INSERT INTO services (town, province, bus, taskdate, passport)
VALUES (
  'Valsolana',
  'Madrid',
  'BUS-011',
  TO_DATE('01-12-2024', 'DD-MM-YYYY'),
  'ESP>>101010101010'
);
INSERT INTO users VALUES (
  USER,
  'TESTIDCARD1234567',
  'TestName',
  'TestSurname1',
  'TestSurname2',
  TO_DATE('27-10-2004', 'DD-MM-YYYY'),
  'Valsolana',
  'Madrid',
  'Test Address',
  'test@example.com',
  600000000,
  'P',
  NULL
);
DELETE FROM loans WHERE signature = 'PD137' AND user_id = USER;
INSERT INTO loans VALUES (
  'PD137',
  USER,
  TO_DATE('01-12-2024', 'DD-MM-YYYY'),
  'Valsolana',
  'Madrid',
  'R',
  0,
  NULL
);
SELECT * FROM my_reservations;

UPDATE my_reservations
SET reservation_date = TO_DATE('10-12-2024', 'DD-MM-YYYY')
WHERE signature = 'PD137'
  AND isbn = '84-283-2141-8';

SELECT * FROM my_reservations WHERE signature = 'PD137';

DELETE FROM my_reservations WHERE signature = 'PD137'
  AND reservation_date = TO_DATE('10-12-2024', 'DD-MM-YYYY')
  AND isbn = '84-283-2141-8';

SELECT * FROM my_reservations WHERE signature = 'PD137';
