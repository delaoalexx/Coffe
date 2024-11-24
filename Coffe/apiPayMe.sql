DROP DATABASE IF EXISTS apiPayMe;
CREATE DATABASE apiPayMe;
USE apiPayMe;

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
    status ENUM('pending', 'completed', 'failed') DEFAULT 'pending', -- the indian man on youtube said this is ok
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sender_id) REFERENCES users(user_id),
    FOREIGN KEY (recipient_id) REFERENCES users(user_id)
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
        SET MESSAGE_TEXT = 'Formato de correo electronico no valido';
    END IF;
    
    IF EXISTS (SELECT 1 FROM users WHERE email = p_email) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Correo electronico en uso';
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
    
    -- crear handler para rollbacks auto, registrar errores en trsnferencias, crear tabla de errores, poner toodo en ingles
    -- monto positivo
    IF p_amount <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El monto debe ser mayor a 0';
    END IF;
    
    -- get idd con el correo
    SELECT user_id, is_active 
    INTO v_recipient_id, v_recipient_active
    FROM users 
    WHERE email = p_recipient_email;
    
    -- existe recipiente
    IF v_recipient_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Destinatario no encontrado';
    END IF;
    
    -- no autotransfer
    IF p_sender_id = v_recipient_id THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No puedes transferir dinero a tu propia cuenta';
    END IF;
    
    -- ambas activas
    SELECT is_active INTO v_sender_active 
    FROM users WHERE user_id = p_sender_id;
    
    IF v_sender_active = FALSE OR v_recipient_active = FALSE THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Una o ambas cuentas están inactivas';
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
    JOIN users u_recipient ON t.recipient_id = u_recipient.user_id
    WHERE t.transaction_id = v_transaction_id;
    
END$$

DELIMITER ;


-- este es el usuario de pruebas
CALL SP_CREATE_USER('Arthur', 'Morgan', 'deer@gmail.com', '12345678');

-- verificar user de priebas
	-- bien
CALL SP_LOGIN('deer@gmail.com', '12345678');
	-- mal pw
CALL SP_LOGIN('deer@gmail.com', '012345678');
	-- mal @
CALL SP_LOGIN('deere@gmail.com', '12345678');


-- general tablas
SELECT * FROM users;
SELECT * FROM accounts;
SELECT * FROM transactions;

-- ver indixes
SHOW INDEXES FROM users;