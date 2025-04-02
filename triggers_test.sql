INSERT INTO users VALUES (
    'LIB001',
    'ID123456789012345',
    'Biblioteca Central',
    'Apellido1',
    'Apellido2',
    DATE '1970-01-01',
    'Valsolana',
    'Madrid',
    'Calle Falsa 123',
    'lib@biblioteca.com',
    123456789,
    'L',
    NULL
);

-- Dummy data for loans table
INSERT INTO loans VALUES (
    'CK239',          
    'LIB001',         
    TRUNC(SYSDATE),   
    'Valsolana',      
    'Madrid',         
    'L',              
    0,
    TRUNC(SYSDATE)+14,
);

-- Try to insert a post with an institutional user
BEGIN
    INSERT INTO posts VALUES (
        'CK239',
        'LIB001',
        TRUNC(SYSDATE), 
        TRUNC(SYSDATE)+1,
        'Posting a comment from an institutional user', 
        0, 
        0
    );
    DBMS_OUTPUT.PUT_LINE('Post inserted successfully (this should not happen).');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Expected error (posts not allowed for institutional users): ' || SQLERRM);
        ROLLBACK;
END;
/
