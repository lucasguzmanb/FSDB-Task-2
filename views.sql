--view my_data

CREATE OR REPLACE VIEW my_data AS
SELECT user_id, id_card, name, surname1, surname2, birthdate, town, province, address, email, phone
FROM users
WHERE user_id = USER;

--

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
WHERE l.user_id = USER ;


CREATE OR REPLACE TRIGGER trg_update_my_loans
INSTEAD OF UPDATE ON my_loans
FOR EACH ROW
BEGIN
  IF :OLD.post IS NULL THEN
    INSERT INTO posts (signature, user_id, stopdate, text, post_date, likes, dislikes)
    VALUES (:OLD.signature, :OLD.user_id, :OLD.stopdate, :NEW.post, SYSTIMESTAMP, 0, 0);
  ELSE
    UPDATE posts
    SET text = :NEW.post,
        post_date = SYSTIMESTAMP
    WHERE signature = :OLD.signature
      AND user_id = :OLD.user_id
      AND stopdate = :OLD.stopdate;
  END IF;
END;
/






