-- view my_data

CREATE OR REPLACE VIEW my_data AS
SELECT user_id, id_card, name, surname1, surname2, birthdate, town, province, address, email, phone
FROM users
WHERE user_id = USER;

-- view my_loans

CREATE OR REPLACE VIEW my_loans AS
SELECT
  l.signature,
  l.user_id,
  l.stopdate,
  l.town,
  l.province,
  l.type,
  l.time,
  l.return,
  p.text AS post,
  p.post_date,
  p.likes,
  p.dislikes
FROM loans l
LEFT JOIN posts p ON l.signature = p.signature
                 AND l.user_id = p.user_id
                 AND l.stopdate = p.stopdate
WHERE l.user_id = USER
  AND l.stopdate < SYSDATE;


CREATE OR REPLACE TRIGGER trg_update_my_loans
INSTEAD OF UPDATE ON my_loans
FOR EACH ROW
BEGIN
  -- We only allow modification of the post column
  -- and the post_date will be updated automatically
  IF (:NEW.signature <> :OLD.signature)
     OR (:NEW.user_id <> :OLD.user_id)
     OR (:NEW.stopdate <> :OLD.stopdate)
     OR (:NEW.town <> :OLD.town)
     OR (:NEW.province <> :OLD.province)
     OR (:NEW.type <> :OLD.type)
     OR (:NEW.time <> :OLD.time)
     OR (:NEW.return <> :OLD.return)
     OR (:NEW.post_date <> :OLD.post_date)
     OR (:NEW.likes <> :OLD.likes)
     OR (:NEW.dislikes <> :OLD.dislikes) THEN
    RAISE_APPLICATION_ERROR(-20001, 'Only the post column can be modified.');
  END IF;

  IF :OLD.post IS NULL THEN
    INSERT INTO posts (signature, user_id, stopdate, text, post_date, likes, dislikes)
    VALUES (:OLD.signature, :OLD.user_id, :OLD.stopdate, :NEW.post, SYSDATE, 0, 0);
  ELSE
    UPDATE posts
    SET text = :NEW.post,
        post_date = SYSDATE
    WHERE signature = :OLD.signature
      AND user_id = :OLD.user_id
      AND stopdate = :OLD.stopdate;
  END IF;
END;
/






