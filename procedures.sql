CREATE OR REPLACE PROCEDURE insert_loan_procedure (
    p_signature IN CHAR(5),
    p_user_id  IN CHAR(10)
) IS
    v_user_type   CHAR(1);
    v_ban         DATE;
    v_town        VARCHAR2(50);
    v_province    VARCHAR2(22);
    v_active_loans NUMBER;
    v_allowed_loans NUMBER;
    v_population    NUMBER;
    v_reservation_count NUMBER;
    v_dummy copies.signature%TYPE;
BEGIN
    -- Check if the user exists
    BEGIN
        SELECT type, ban_up2, town, province
          INTO v_user_type, v_ban, v_town, v_province
        FROM users
        WHERE user_id = p_user_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001, 'User not found');
    END;
    
    -- Check if there is a reservation for the given copy and user as of today
    SELECT COUNT(*) INTO v_reservation_count
      FROM loans
      WHERE signature = p_signature
        AND user_id = p_user_id
        AND type = 'R'
        AND stopdate >= TRUNC(SYSDATE);
    
    IF v_reservation_count > 0 THEN
        -- Convert the reservation to a loan by updating the existing record
        UPDATE loans
           SET type = 'L',
               return = TRUNC(SYSDATE) + 14
         WHERE signature = p_signature
           AND user_id = p_user_id
           AND type = 'R'
           AND stopdate >= TRUNC(SYSDATE);
           
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Reservation converted to loan successfully');
    ELSE
        -- If there is no reservation, proceed to insert a new loan
        
        -- Verify that the user is not banned
        IF v_ban IS NOT NULL AND TRUNC(SYSDATE) < v_ban THEN
            RAISE_APPLICATION_ERROR(-20002, 'User is currently sanctioned');
        END IF;
        
        -- Check active loans (we count those that have not been returned or return date is after today)
        SELECT COUNT(*)
          INTO v_active_loans
          FROM loans
          WHERE user_id = p_user_id
            AND return > TRUNC(SYSDATE);
            
        IF v_user_type <> 'P' THEN
            v_allowed_loans := 2;
        ELSE
            -- For library users, we need to check the population of the town
            BEGIN
                SELECT population
                  INTO v_population
                FROM municipalities
                WHERE town = v_town
                  AND province = v_province;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    RAISE_APPLICATION_ERROR(-20003, 'Municipality info not found');
            END;
            v_allowed_loans := CEIL(v_population / 10) * 2;
        END IF;
        
        IF v_active_loans >= v_allowed_loans THEN
            RAISE_APPLICATION_ERROR(-20004, 'User has reached the borrowing limit');
        END IF;
        
        -- Verify that the copy is available for loan (not deregistered, available for loan) and has no active loans
        BEGIN
            SELECT c.signature
              INTO v_dummy
            FROM copies c
            WHERE c.signature = p_signature
              AND c.deregistered IS NULL
              AND NOT EXISTS (
                    SELECT 1 
                      FROM loans l 
                     WHERE l.signature = c.signature
                       AND (l.return IS NULL OR l.return > TRUNC(SYSDATE))
              )
              AND ROWNUM = 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20005, 'Copy not available for loan');
        END;
        
        -- Insert the new loan
        INSERT INTO loans (
            signature,
            user_id,
            stopdate,
            town,
            province,
            type,
            time,
            RETURN
        ) VALUES (
            p_signature,
            p_user_id,
            TRUNC(SYSDATE),
            v_town,
            v_province,
            'L',
            0,
            TRUNC(SYSDATE) + 14
        );
        
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Loan inserted successfully');
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/


CREATE OR REPLACE PROCEDURE insert_reservation_procedure (
    p_isbn IN VARCHAR2,
    p_date IN DATE,
    p_user_id IN CHAR
) IS
    v_user_type   CHAR(1);
    v_ban         DATE;
    v_town        VARCHAR2(50);
    v_province    VARCHAR2(22);
    v_count_users NUMBER;
    v_active_loans NUMBER;
    v_allowed_loans NUMBER;
    v_population    NUMBER;
    v_copy_signature CHAR(5);
BEGIN
    -- Check if the user exists
    BEGIN
      SELECT type, ban_up2, town, province
        INTO v_user_type, v_ban, v_town, v_province
      FROM users
      WHERE user_id = p_user_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20001, 'User not found');
    END;

    -- Check if the user is banned
    IF v_ban IS NOT NULL AND p_date < v_ban THEN
        RAISE_APPLICATION_ERROR(-20002, 'User is currently sanctioned');
    END IF;

    -- Check active loans (we count those that have not been returned or return date is after p_date)
    SELECT COUNT(*)
      INTO v_active_loans
    FROM loans
    WHERE user_id = p_user_id
      AND (return IS NULL OR return > p_date);
    
    IF v_user_type <> 'P' THEN
        v_allowed_loans := 2;
    ELSE
        -- For library users, we need to check the population of the town
        BEGIN
            SELECT population
              INTO v_population
            FROM municipalities
            WHERE town = v_town
              AND province = v_province;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20003, 'Municipality info not found');
        END;
        -- We calculate the maximum loans: 2 copies per 10 inhabitants
        v_allowed_loans := CEIL(v_population / 10) * 2;
    END IF;
    
    IF v_active_loans >= v_allowed_loans THEN
        RAISE_APPLICATION_ERROR(-20004, 'User has reached the borrowing limit');
    END IF;

    -- Verify if the copy is available for the requested period
    -- We look for a copy that is not deregistered and has no active loans during the period
    BEGIN
      SELECT c.signature
        INTO v_copy_signature
      FROM copies c
      WHERE c.isbn = p_isbn
        AND c.deregistered IS NULL
        AND NOT EXISTS (
              SELECT 1
              FROM loans l
              WHERE l.signature = c.signature
                AND l.return IS NULL
                -- if the copy has a loan that starts before p_date and ends after p_date it is not available
                AND l.stopdate < p_date + 14
                AND l.stopdate > p_date
        )
      AND ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
         RAISE_APPLICATION_ERROR(-20005, 'No available copy for the requested period');
    END;
    
    -- Insert the reservation in the loans table
    INSERT INTO loans (
         signature,
         user_id,
         stopdate,
         town,
         province,
         type,
         time,
         RETURN
    ) VALUES (
         v_copy_signature,
         p_user_id,
         p_date
         v_town,
         v_province,
         'R',
         0,
         NULL
    );
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Reservation inserted successfully');
    
EXCEPTION
    WHEN OTHERS THEN
       ROLLBACK;
       RAISE;
END;
/

CREATE OR REPLACE PROCEDURE record_book_return (
    p_signature IN CHAR,
    p_user_id   IN CHAR
) IS
    v_count_users NUMBER;
    v_count_loans NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count_users
    FROM users
    WHERE user_id = p_user_id;

    IF v_count_users = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'User not found');
    END IF;

    SELECT COUNT(*) INTO v_count_loans
    FROM loans
    WHERE signature = p_signature 
      AND user_id = p_user_id
      AND return IS NULL;

    IF v_count_loans = 0 THEN
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