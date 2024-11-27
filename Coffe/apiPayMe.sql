DROP DATABASE IF EXISTS apiPayMe;
CREATE DATABASE apiPayMe;
USE apiPayMe;

-- PENDIENTES: poner nombres en ingles, poner comentarios

-- DUDAS: uso del handler en los rollbacks, distribucion de scripts, uso de railway, documentacion de los endpoints, 

-- Ale, remember use english for extra '.'

CREATE TABLE users (
    user_id INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    INDEX idx_email (email)  -- indice que menciono el profe
) ENGINE=INNODB;

CREATE TABLE accounts (
    account_id INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
    balance FLOAT DEFAULT 0.0, -- o decimal??
    user_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
) ENGINE=INNODB;

-- email 
CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
    sender_id INT NOT NULL, -- sender es el usuario que envía la transferencia
    recipient_id INT NOT NULL, -- recipient es el usuaro que recibe la transferencia
    amount FLOAT NOT NULL,
    message TEXT, -- concepto de pago que el usuario puede enviar
    status ENUM('pending', 'completed', 'failed') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sender_id) REFERENCES users(user_id),
    FOREIGN KEY (recipient_id) REFERENCES users(user_id)
) ENGINE=INNODB;

-- errores logs

CREATE TABLE error_logs (
    error_id INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
    procedure_name VARCHAR(100) NOT NULL,
    table_name VARCHAR(100) NOT NULL,
    error_message TEXT NOT NULL,
    user_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
) ENGINE=INNODB;

-- tarjetas 
CREATE TABLE cards (
    card_id INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
    user_id INT NOT NULL,
    card_number VARCHAR(16) NOT NULL,
    card_holder VARCHAR(100) NOT NULL,
    expiration_date DATE NOT NULL,
    card_type ENUM('credit', 'debit') NOT NULL,
    balance FLOAT DEFAULT 0.0,  -- se supone que esto no debe estar pero es solo para ejemplificar el uso de las cards c:
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    INDEX idx_card_number (card_number)
) ENGINE=INNODB;

-- like a SIGN UP 
DROP PROCEDURE IF EXISTS SP_CREATE_USER;
DELIMITER $$
CREATE PROCEDURE SP_CREATE_USER(
    IN p_first_name VARCHAR(100),
    IN p_last_name VARCHAR(100),
    IN p_email VARCHAR(255),
    IN p_password VARCHAR(255)
)
BEGIN

-- v pq es una  variable

    DECLARE v_user_id INT;
    
    IF p_first_name IS NULL OR p_first_name = '' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'First name cannot be empty';
    END IF;
    
    IF p_last_name IS NULL OR p_last_name = '' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Last name cannot be empty';
    END IF;
    
    IF p_email NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid email format';
    END IF;
    
    IF EXISTS (SELECT 1 FROM users WHERE email = p_email) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'E-mail in use';
    END IF;
    
    IF LENGTH(p_password) < 8 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Password must be at least 8 characters long';
    END IF;
    
	START TRANSACTION;
    
    BEGIN
    
        INSERT INTO users (first_name, last_name, email, password_hash)
        VALUES (p_first_name, p_last_name, p_email, p_password);
        
        SET v_user_id = LAST_INSERT_ID();
        
        -- al momento de crear un user se crea por defecto su cuenta bancaria, si bien un user puede tener varias cuentas, no necesariamente estas 
        INSERT INTO accounts (user_id, balance)
        VALUES (v_user_id, 0.0);
        
        COMMIT;
    END;
END$$
DELIMITER ;

-- like a logIN
DELIMITER $$
CREATE PROCEDURE SP_LOGIN(
    IN p_email VARCHAR(255),
    IN p_password VARCHAR(255)
)
BEGIN
    DECLARE v_user_id INT;
    DECLARE v_is_active BOOLEAN;
    
    -- autentucar
    SELECT user_id, is_active 
    INTO v_user_id, v_is_active
    FROM users 
    WHERE email = LOWER(p_email) AND password_hash = p_password
    LIMIT 1;
    
    -- mal pw o email@g.com
    IF v_user_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid email or password';
    END IF;
    
    IF v_is_active = FALSE THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Account is inactive';
    END IF;
    
    
    -- info de user
    SELECT 
        users.user_id,
        users.email,
        users.first_name,
        users.last_name
    FROM users
    WHERE users.user_id = v_user_id;
    
    -- cuentas del user
    SELECT 
        accounts.account_id,
        accounts.balance,
        accounts.created_at,
        accounts.is_active
    FROM accounts
    WHERE accounts.user_id = v_user_id;
    
END$$

DELIMITER ;

-- transfrencia

DELIMITER $$

CREATE PROCEDURE SP_MAKE_TRANSFER(
    IN p_sender_id INT,             
    IN p_recipient_email VARCHAR(255), 
    IN p_amount FLOAT,              
    IN p_message TEXT               
)
BEGIN
    DECLARE v_recipient_id INT;
    DECLARE v_sender_balance FLOAT;
    DECLARE v_transaction_id INT;
    DECLARE v_sender_active BOOLEAN;
    DECLARE v_recipient_active BOOLEAN;
    
    -- crear handler para rollbacks auto, registrar errores en tabla de errores, poner toodo en ingles(tambien comentarios
    
    -- monto positivo
    IF p_amount <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Amount must be greater than 0';
    END IF;
    
    -- get idd con el correo
    SELECT user_id, is_active 
    INTO v_recipient_id, v_recipient_active
    FROM users 
    WHERE email = p_recipient_email;
    
    -- existe recipiente
    IF v_recipient_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Recipient not found';
    END IF;
    
    -- no autotransfer
    IF p_sender_id = v_recipient_id THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'You cannot transfer money to your own account';
    END IF;
    
    -- ambas activas
    SELECT is_active INTO v_sender_active 
    FROM users WHERE user_id = p_sender_id;
    
    IF v_sender_active = FALSE OR v_recipient_active = FALSE THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'One or both accounts are inactive';
    END IF;
    
    -- get dinero del sender
    SELECT balance INTO v_sender_balance
    FROM accounts 
    WHERE user_id = p_sender_id AND is_active = TRUE
    LIMIT 1;
    
    -- checar fondos suficientes
    IF v_sender_balance < p_amount THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Fondos insuficientes';
    END IF;
    
   
    START TRANSACTION;
    INSERT INTO transactions (sender_id, recipient_id, amount, message, status)
    VALUES (p_sender_id, v_recipient_id, p_amount, p_message, 'pending');
    
    SET v_transaction_id = LAST_INSERT_ID();
    
    -- Actualizar dinero
    UPDATE accounts 
    SET balance = balance - p_amount 
    WHERE user_id = p_sender_id AND is_active = TRUE
    LIMIT 1;
    
    UPDATE accounts 
    SET balance = balance + p_amount 
    WHERE user_id = v_recipient_id AND is_active = TRUE
    LIMIT 1;
    
    -- Marcar transaccióon 'completed'
    UPDATE transactions 
    SET status = 'completed' 
    WHERE transaction_id = v_transaction_id;
    
    COMMIT;
    
    -- getinfo 
    SELECT 
        transactions.transaction_id,
        transactions.amount,
        transactions.status,
        transactions.created_at,
        transactions.message,
        u_recipient.email as recipient_email,
        u_recipient.first_name as recipient_name,
        u_recipient.last_name as recipient_lastname
    FROM transactions
    JOIN users u_recipient ON transactions.recipient_id = u_recipient.user_id
    WHERE transactions.transaction_id = v_transaction_id;
    
END$$

DELIMITER ;

-- Agregar una tarjeta, como es imposible que ridiculo que el usuario meta una tarjeta con el monto que tiene pues se le dara un monto random entre 50 y 1000, este monto estara disponible para el usuario solo para practicidad
DELIMITER $$
CREATE PROCEDURE SP_ADD_CARD(
    IN p_user_id INT,
    IN p_card_number VARCHAR(16),
    IN p_card_holder VARCHAR(100),
    IN p_expiration_date DATE,
    IN p_card_type ENUM('credit', 'debit')
)
BEGIN
    DECLARE v_random_balance FLOAT;
    DECLARE v_card_id INT;
    
    -- Validate input parameters
    IF p_user_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'User ID cannot be null';
    END IF;
    
    IF p_card_number IS NULL OR LENGTH(p_card_number) != 16 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid card number';
    END IF;
    
    IF p_card_holder IS NULL OR p_card_holder = '' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Card holder name cannot be empty';
    END IF;
    
    IF p_expiration_date IS NULL OR p_expiration_date <= CURRENT_DATE THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid expiration date';
    END IF;
    

    SET v_random_balance = FLOOR(50 + (RAND() * 950));
    
    
    START TRANSACTION;
    
    INSERT INTO cards ( user_id, card_number, card_holder, expiration_date, card_type, balance) 
    VALUES (p_user_id, p_card_number, p_card_holder, p_expiration_date, p_card_type, v_random_balance);
    
    SET v_card_id = LAST_INSERT_ID();
    
    COMMIT;
    
    SELECT card_id, user_id, card_number, card_holder, expiration_date, card_type, balance, is_active, created_at
    FROM cards WHERE card_id = v_card_id;
END$$
DELIMITER ;

-- HACER PAGOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOS (CFE, TELMEX, SERVICIOS...)
DELIMITER $$
CREATE PROCEDURE SP_MAKE_PAYMENT(
    IN p_user_id INT,             
    IN p_amount FLOAT,  
    IN p_institution VARCHAR(100), 
    IN p_payment_concept VARCHAR(255) 
)
BEGIN
    DECLARE v_user_balance FLOAT;
    DECLARE v_payment_id INT;
    DECLARE v_user_active BOOLEAN;
    
    IF p_amount <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Payment amount must be greater than 0';
    END IF;
    
    IF p_institution IS NULL OR p_institution = '' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Payment institution cannot be empty';
    END IF;
    
    
    
    
    SELECT is_active INTO v_user_active 
    FROM users 
    WHERE user_id = p_user_id;
    
    IF v_user_active = FALSE THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'User account is inactive';
    END IF;
    
    SELECT balance INTO v_user_balance
    FROM accounts 
    WHERE user_id = p_user_id AND is_active = TRUE
    LIMIT 1;
    
    IF v_user_balance < p_amount THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Insufficient funds';
    END IF;
    
    
    START TRANSACTION;
    
    
    INSERT INTO transactions (sender_id, recipient_id, amount, message, status) 
    VALUES (p_user_id, p_user_id, p_amount, CONCAT(p_institution, ': ', p_payment_concept), 'completed');
    
    SET v_payment_id = LAST_INSERT_ID();
    
    
    UPDATE accounts 
    SET balance = balance - p_amount 
    WHERE user_id = p_user_id AND is_active = TRUE
    LIMIT 1;
    
    COMMIT;
    
    SELECT transactions.transaction_id, transactions.amount, SUBSTRING_INDEX(transactions.message, ': ', 1) AS payment_institution, SUBSTRING_INDEX(transactions.message, ': ', -1) AS payment_concept, transactions.status, transactions.created_at, accounts.balance AS remaining_balance
    FROM transactions JOIN accounts ON transactions.sender_id = accounts.user_id WHERE transactions.transaction_id = v_payment_id;
    
END$$
DELIMITER ;

-- este es user1  de pruebas
CALL SP_CREATE_USER('Arthur', 'Morgan', 'deer@gmail.com', '12345678');

-- update dinero para empezar a practicar
UPDATE accounts SET balance = 1000 WHERE user_id = 1;

-- este es el usuar2 de pruebas
CALL SP_CREATE_USER('John', 'Marston', 'wolf@gmail.com', '87654321');

/*
-- verificar user de priebas
	-- bien
CALL SP_LOGIN('deer@gmail.com', '12345678');
	-- mal pw
CALL SP_LOGIN('deer@gmail.com', '012345678');
	-- mal @
CALL SP_LOGIN('deere@gmail.com', '12345678');


-- TRANSFERENCIAS DEPRUEBA 

	-- trasnf de prueba u1 a u2
CALL SP_MAKE_TRANSFER(1, 'wolf@gmail.com', 10, 'concepto de pago');
-- trasnf de prueba u1 a u2 con null en message
CALL SP_MAKE_TRANSFER(1, 'wolf@gmail.com', 10, null);
	-- trasnf de prueba u1 a u2 fallida por mucho dinero
CALL SP_MAKE_TRANSFER(1, 'wolf@gmail.com', 10000, 'concepto de pago');
	-- trasnf de prueba u1 a u2 fallida por mal correp
CALL SP_MAKE_TRANSFER(1, 'wolfs@gmail.com', 10000, 'concepto de pago');
	-- trasnf de prueba u1 a u2 fallida por numero negativo
CALL SP_MAKE_TRANSFER(1, 'wolf@gmail.com', -11, 'concepto de pago');
	-- trasnf de prueba u1 a u2 fallida por autotransaccion
CALL SP_MAKE_TRANSFER(1, 'deer@gmail.com', 10, 'concepto de pago');

	-- trasnf de prueba u2 a u1
CALL SP_MAKE_TRANSFER(2, 'deer@gmail.com', 10, 'concepto de pago');
	-- trasnf de prueba u2 a u1 fallida por mucho dinero
CALL SP_MAKE_TRANSFER(2, 'deer@gmail.com', 10000, 'concepto de pago');
	-- trasnf de prueba u2 a u1 fallida por mal correp
CALL SP_MAKE_TRANSFER(2, 'deerr@gmail.com', 10000, 'concepto de pago');
	-- trasnf de prueba u2 a u1 fallida por numero negativo
CALL SP_MAKE_TRANSFER(2, 'deer@gmail.com', -11, 'concepto de pago');
	-- trasnf de prueba u2 a u1 fallida por autotransaccion
CALL SP_MAKE_TRANSFER(2, 'wolf@gmail.com', 10, 'concepto de pago');


*/

	-- crear cards de prueba


CALL SP_ADD_CARD(1, 1234567890987654, 'Arthur Morgan', '2026-12-31', 'credit');


-- probar pagos con dinero de monedero

CALL SP_MAKE_PAYMENT(1, 50, 'CFE', 'Pago de luz - Noviembre');
CALL SP_MAKE_PAYMENT(1, 400, 'NETFLIX', 'Pago streaming');
    
-- general tablas

SELECT * FROM users;
SELECT * FROM accounts;
SELECT * FROM transactions;
SELECT * FROM cards;
SELECT * FROM erro_logs;


