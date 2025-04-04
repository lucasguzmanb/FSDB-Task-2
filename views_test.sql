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

CREATE OR REPLACE VIEW my_reservations AS
SELECT
  signature,
  stopdate AS reservation_date,
  town,
  province
FROM loans
WHERE user_id = '9994309848'
  AND type = 'R';


CREATE OR REPLACE TRIGGER trg_insert_my_reservations
INSTEAD OF INSERT ON my_reservations
FOR EACH ROW
BEGIN
  INSERT INTO loans (
    signature,
    user_id,
    stopdate,
    town,
    province,
    type,
    time,
    return
  )
  VALUES (
    :NEW.signature,
    '9994309848',
    :NEW.reservation_date,
    :NEW.town,
    :NEW.province,
    'R',
    0,
    NULL
  );
END;
/


CREATE OR REPLACE TRIGGER trg_delete_my_reservations
INSTEAD OF DELETE ON my_reservations
FOR EACH ROW
BEGIN
  DELETE FROM loans
  WHERE signature = :OLD.signature
    AND user_id = '9994309848'
    AND stopdate = :OLD.reservation_date
    AND type = 'R';
END;
/


CREATE OR REPLACE TRIGGER trg_update_my_reservations
INSTEAD OF UPDATE ON my_reservations
FOR EACH ROW
BEGIN
  UPDATE loans
  SET stopdate = :NEW.reservation_date
  WHERE signature = :OLD.signature
    AND user_id = '9994309848'
    AND stopdate = :OLD.reservation_date
    AND type = 'R';
END;
/

DELETE FROM posts WHERE USER_ID = USER;
DELETE FROM loans WHERE USER_ID = USER;
DELETE FROM users WHERE USER_ID = USER;