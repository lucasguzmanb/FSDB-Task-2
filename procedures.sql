CREATE OR REPLACE PACKAGE fondicu AS
    PROCEDURE insert_loan_procedure (p_signature IN CHAR);
    PROCEDURE insert_reservation_procedure (p_isbn IN VARCHAR2, p_date IN DATE);
    PROCEDURE record_book_return (p_signature IN CHAR);
END fondicu;
/

CREATE OR REPLACE PACKAGE BODY fondicu AS
  PROCEDURE insert_loan_procedure (p_signature IN CHAR) IS
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
            WHERE user_id = USER;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20001, 'User not found');
        END;
        
        -- Check if there is a reservation for the given copy and user as of today
        SELECT COUNT(*) INTO v_reservation_count
          FROM loans
          WHERE signature = p_signature
            AND user_id = USER
            AND type = 'R'
            AND stopdate >= TRUNC(SYSDATE);
        
        IF v_reservation_count > 0 THEN
            -- Convert the reservation to a loan by updating the existing record
            UPDATE loans
              SET type = 'L',
                  return = TRUNC(SYSDATE) + 14
            WHERE signature = p_signature
              AND user_id = USER
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
              WHERE user_id = USER
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
                return
            ) VALUES (
                p_signature,
                USER,
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

  PROCEDURE insert_reservation_procedure (p_isbn IN VARCHAR2, p_date IN DATE) IS
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
          WHERE user_id = USER;
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
        WHERE user_id = USER
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
            return
        ) VALUES (
            v_copy_signature,
            USER,
            p_date,
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

  PROCEDURE record_book_return (p_signature IN CHAR) IS
      v_count_users NUMBER;
      v_count_loans NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count_users
        FROM users
        WHERE user_id = USER;

        IF v_count_users = 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'User not found');
        END IF;

        SELECT COUNT(*) INTO v_count_loans
        FROM loans
        WHERE signature = p_signature 
          AND user_id = USER
          AND return IS NULL;

        IF v_count_loans = 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'No loan found with the given signature and user_id');
        END IF;

        UPDATE loans
        SET return = SYSDATE
        WHERE signature = p_signature 
          AND user_id = USER
          AND return IS NULL;
        
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Book return recorded successfully');
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
    END;
END fondicu;
/

-- TESTS

-- insert_loan_procedure

-- Success case
BEGIN
  -- Suponiendo que 'SIG001' es una copia disponible y 'USR001' es un usuario válido sin sanción.
  fondicu.insert_loan_procedure(p_signature => 'SIG001');
  DBMS_OUTPUT.PUT_LINE('Insert loan test passed.');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Unexpected error in insert_loan_procedure: ' || SQLERRM);
END;
/

-- Failure case: User not found
BEGIN
  -- 'USR_NOEXIST' no debe existir en la tabla users.
  fondicu.insert_loan_procedure(p_signature => 'SIG002');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Expected error (user does not exist): ' || SQLERRM);
END;
/

-- Failure case: User is banned
BEGIN
  -- Suponiendo que 'USR_BAN' es un usuario con ban_up2 mayor que SYSDATE.
  fondicu.insert_loan_procedure(p_signature => 'SIG003');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Expected error (user banned): ' || SQLERRM);
END;
/

-- Failure case: User has reached the borrowing limit
BEGIN
  fondicu.insert_loan_procedure(p_signature => 'SIG004');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Expected error (loan limit reached): ' || SQLERRM);
END;
/

-- Failure case: Copy not available for loan
BEGIN
  fondicu.insert_loan_procedure(p_signature => 'SIG_NODISP');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Expected error (copy not available): ' || SQLERRM);
END;
/

-- insert_reservation_procedure

-- Success case
BEGIN
  -- Suponiendo que 'ISBN001' es un ISBN válido y existe copia disponible para reservar,
  -- y 'USR002' es un usuario válido.
  fondicu.insert_reservation_procedure(p_isbn => 'ISBN001', p_date => SYSDATE);
  DBMS_OUTPUT.PUT_LINE('Insert reservation test passed.');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Unexpected error in insert_reservation_procedure: ' || SQLERRM);
END;
/

-- Failure case: User not found
BEGIN
  fondicu.insert_reservation_procedure(p_isbn => 'ISBN002', p_date => SYSDATE);
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Expected error (user does not exist): ' || SQLERRM);
END;
/

-- Failure case: User is banned
BEGIN
  -- Suponiendo que 'USR_BAN2' es un usuario con sanción vigente para la fecha p_date.
  fondicu.insert_reservation_procedure(p_isbn => 'ISBN003', p_date => SYSDATE);
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Expected error (user banned): ' || SQLERRM);
END;
/

-- Failure case: User has reached the borrowing limit
BEGIN
  fondicu.insert_reservation_procedure(p_isbn => 'ISBN004', p_date => SYSDATE);
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Expected error (loan limit reached): ' || SQLERRM);
END;
/

-- Failure case: No available copy for the requested period
BEGIN
  fondicu.insert_reservation_procedure(p_isbn => 'ISBN_NODISP', p_date => SYSDATE);
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Expected error (no copy available): ' || SQLERRM);
END;
/

-- record_book_return

-- Success case
BEGIN
  -- Suponiendo que 'SIG_DEV' es la firma de una copia prestada y 'USR003' es el usuario que tiene el préstamo activo.
  fondicu.record_book_return(p_signature => 'SIG_DEV');
  DBMS_OUTPUT.PUT_LINE('Return record test passed.');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Unexpected error in record_book_return: ' || SQLERRM);
END;
/

-- Failure case: User not found
BEGIN
  fondicu.record_book_return(p_signature => 'SIG_DEV');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Expected error (user does not exist): ' || SQLERRM);
END;
/

-- Failure case: No loan found with the given signature and user_id
BEGIN
  -- Suponiendo que 'SIG_SINLOAN' es una firma para la que no existe un préstamo activo para 'USR003'.
  fondicu.record_book_return(p_signature => 'SIG_SINLOAN');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Expected error (loan not found): ' || SQLERRM);
END;
/