-- Prevent institutional users from creating posts trigger

CREATE OR REPLACE TRIGGER prevent_posts_institutional_trigger
BEFORE INSERT OR UPDATE ON posts
FOR EACH ROW
DECLARE
    v_user_type users.TYPE%TYPE;
BEGIN
    -- Obtain the user type from the users table
    SELECT type
      INTO v_user_type
      FROM users
     WHERE user_id = :new.user_id;
    
    -- If the user type is 'L' (institutional), raise an error
    IF v_user_type = 'L' THEN
        RAISE_APPLICATION_ERROR(-20050, 'Institutional users (libraries) cannot create posts.');
    END IF;
END;
/

-- Derregistration book trigger

CREATE OR REPLACE TRIGGER deregistration_book
BEFORE UPDATE ON COPIES
FOR EACH ROW
BEGIN
  IF :NEW.condition = 'D' THEN
    IF :OLD.deregistered IS NOT NULL THEN
      RAISE_APPLICATION_ERROR(-20001, 'Copy has already been deregistered.');
    ELSE
      :NEW.deregistered := SYSDATE;
    END IF;
  END IF;
END;
/

-- Update book reads trigger

ALTER TABLE books ADD reads NUMBER DEFAULT 0;

CREATE OR REPLACE TRIGGER update_book_reads
AFTER INSERT ON loans
FOR EACH ROW
BEGIN
    UPDATE books
    SET reads = reads + 1
    WHERE title = (SELECT title FROM editions WHERE isbn = (SELECT isbn FROM copies WHERE signature = :NEW.signature));
END;
/