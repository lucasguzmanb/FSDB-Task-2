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
