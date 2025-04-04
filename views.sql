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

-- view my_reservations


-- Crear vista my_reservations para el usuario actual (USER)
CREATE OR REPLACE VIEW my_reservations AS
SELECT
  l.signature,
  l.stopdate AS reservation_date,
  e.title,
  e.author,
  e.isbn
FROM loans l
JOIN copies c ON l.signature = c.signature
JOIN editions e ON c.isbn = e.isbn
WHERE l.user_id = USER
  AND l.type = 'R';

-- Trigger para INSERTAR una reserva si hay una copia disponible del ISBN
CREATE OR REPLACE TRIGGER trg_insert_my_reservations
INSTEAD OF INSERT ON my_reservations
FOR EACH ROW
DECLARE
  v_signature copies.signature%TYPE;
BEGIN
  SELECT c.signature INTO v_signature
  FROM copies c
  WHERE c.isbn = :NEW.isbn
    AND c.signature NOT IN (
      SELECT l.signature
      FROM loans l
      WHERE l.return IS NULL
    )
    AND ROWNUM = 1;

  INSERT INTO loans (
    signature, user_id, stopdate, town, province, type, time, return
  )
  VALUES (
    v_signature, USER, :NEW.reservation_date, 'Madrid', 'Madrid', 'R', 0, NULL
  );
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20001, 'No hay copias disponibles para este ISBN.');
END;
/

-- Trigger para ELIMINAR una reserva
CREATE OR REPLACE TRIGGER trg_delete_my_reservations
INSTEAD OF DELETE ON my_reservations
FOR EACH ROW
BEGIN
  DELETE FROM loans
  WHERE signature = :OLD.signature
    AND user_id = USER
    AND stopdate = :OLD.reservation_date
    AND type = 'R';
END;
/

-- Trigger para ACTUALIZAR la fecha de una reserva si hay disponibilidad
CREATE OR REPLACE TRIGGER trg_update_my_reservations
INSTEAD OF UPDATE ON my_reservations
FOR EACH ROW
DECLARE
  v_signature copies.signature%TYPE;
BEGIN
  SELECT c.signature INTO v_signature
  FROM copies c
  WHERE c.isbn = :OLD.isbn
    AND c.signature = :OLD.signature
    AND NOT EXISTS (
      SELECT 1
      FROM loans l
      WHERE l.signature = c.signature
        AND l.stopdate = :NEW.reservation_date
        AND l.return IS NULL
    )
    AND ROWNUM = 1;

  UPDATE loans
  SET stopdate = :NEW.reservation_date
  WHERE signature = :OLD.signature
    AND user_id = USER
    AND stopdate = :OLD.reservation_date
    AND type = 'R';

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20002, 'No hay disponibilidad para cambiar a esa fecha.');
END;
/







