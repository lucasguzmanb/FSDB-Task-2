-- Testing user
INSERT INTO users  VALUES (USER, 'TESTIDCARD1234567', 'TestName', 'TestSurname1', 'TestSurname2', TO_DATE('27-10-2004', 'DD-MM-YYYY'), 'Valsolana', 'Madrid', 'Test Address', 'test@example.com', 600000000, 'P', NULL);

-- insert_loan_procedure

-- Success case
DELETE FROM loans WHERE USER_ID = USER;
INSERT INTO loans VALUES ('CK239', USER, TO_DATE('23-11-2024', 'DD-MM-YYYY'), 'Valsolana', 'Madrid', 'R', 0, NULL);
BEGIN
  -- Insert a reservation for a user with ID 'FSDB309' (test user) and a copy with signature 'CK239' (valid copy signature)
  -- Although the stopdate is not in the future (need to be assigned to a real route), we treat it as a reservation for the test.
  foundicu.insert_loan_procedure(p_signature => 'CK239');
  DBMS_OUTPUT.PUT_LINE('Insert loan test passed.');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Unexpected error in insert_loan_procedure: ' || SQLERRM);
END;
/

-- Failure case: User not found
BEGIN
  -- We delete the user to simulate the error
  DELETE FROM loans WHERE USER_ID = USER;
  DELETE FROM users WHERE USER_ID = USER;
  foundicu.insert_loan_procedure(p_signature => 'CK239');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Expected error (user does not exist): ' || SQLERRM);
END;
/

-- Failure case: User has reached the borrowing limit
-- We insert 2 loans to reach the limit
DELETE FROM loans WHERE USER_ID = USER;
INSERT INTO loans VALUES ('CK239', USER, TO_DATE('23-11-2024', 'DD-MM-YYYY'), 'Valsolana', 'Madrid', 'L', 0, TRUNC(SYSDATE) + 14);
INSERT INTO loans VALUES ('CK237', USER, TO_DATE('23-11-2024', 'DD-MM-YYYY'), 'Valsolana', 'Madrid', 'L', 0, TRUNC(SYSDATE) + 14);
BEGIN
  foundicu.insert_loan_procedure(p_signature => 'CK238');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Expected error (loan limit reached): ' || SQLERRM);
END;
/

-- insert_reservation_procedure

-- Success case
DELETE FROM loans WHERE USER_ID = USER;
BEGIN
  -- Insert a reservation for a user with ID 'FSDB309' (test user) and a copy with ISBN '978-84-8053-584-7' (valid ISBN)
  foundicu.insert_reservation_procedure(p_isbn => '978-84-8053-584-7', p_date => TO_DATE('23-11-2024', 'DD-MM-YYYY'));
  DBMS_OUTPUT.PUT_LINE('Insert reservation test passed.');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Unexpected error in insert_reservation_procedure: ' || SQLERRM);
END;
/
SELECT signature, user_id, type, return FROM loans WHERE user_id=USER;

-- Failure case: User is banned
BEGIN
  -- We ban the current user to simulate the error
  UPDATE users SET ban_up2 = TRUNC(SYSDATE) + 1 WHERE user_id = USER;
  foundicu.insert_reservation_procedure(p_isbn => '978-84-8053-584-7', p_date => TO_DATE('23-11-2024', 'DD-MM-YYYY'));
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Expected error (user banned): ' || SQLERRM);
END;
/

-- record_book_return

-- Success case
DELETE FROM loans WHERE USER_ID = USER;
INSERT INTO loans VALUES ('CK237', USER, TO_DATE('23-11-2024', 'DD-MM-YYYY'), 'Valsolana', 'Madrid', 'L', 0, NULL);
BEGIN
  foundicu.record_book_return(p_signature => 'CK237');
  DBMS_OUTPUT.PUT_LINE('Return record test passed.');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Unexpected error in record_book_return: ' || SQLERRM);
END;
/
SELECT signature, user_id, type, return FROM loans WHERE user_id=USER;

-- Failure case: No loan found with the given signature and user_id
BEGIN
  -- We use a signature that does not exist in the loans table
  foundicu.record_book_return(p_signature => 'SIG_NON_EXISTING');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Expected error (loan not found): ' || SQLERRM);
END;
/
DELETE FROM loans WHERE USER_ID = USER;
DELETE FROM users WHERE USER_ID = USER;