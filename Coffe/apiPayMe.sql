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
        
        INSERT INTO accounts (user_id, balance)
        VALUES (v_user_id, 0.0);
        
        COMMIT;
    END;
END$$
DELIMITER ;


-- este es el usuario de pruebas
CALL SP_CREATE_USER('Arthur', 'Morgan', 'deer@gmail.com', '12345678');

SELECT * FROM users;


-- ver indixes
SHOW INDEXES FROM users;