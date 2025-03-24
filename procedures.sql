CREATE OR REPLACE PROCEDURE insert_loan (
    signature IN CHAR(5),
    user_id IN CHAR(10),
) IS
BEGIN

END;
/

CREATE OR REPLACE PROCEDURE record_book_return (
    p_signature IN CHAR,
    p_user_id   IN CHAR
) IS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM loans
    WHERE signature = p_signature 
      AND user_id = p_user_id
      AND return IS NULL;

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'No loan found with the given signature and user_id');
    END IF;

    UPDATE loans
    SET return = SYSDATE
    WHERE signature = p_signature 
      AND user_id = p_user_id
      AND return IS NULL;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Book return recorded successfully');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

-- Check the procedures
INSERT INTO loans (SIGNATURE, USER_ID, STOPDATE, TOWN, PROVINCE, TYPE, TIME, RETURN)
VALUES ('SB927', '8581926542', TO_DATE('2024-11-15', 'YYYY-MM-DD'), 'Villaarbustos', 'Teruel', 'L', 600, NULL);
SELECT * FROM loans WHERE return IS NULL;
EXEC record_book_return('SB927', '8581926542');
SELECT * FROM loans WHERE return IS NULL;
SELECT * FROM loans WHERE user_id = '8581926542';