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
    is_active BOOLEAN DEFAULT true
) ENGINE=INNODB;

CREATE TABLE accounts (
    account_id INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
    balance FLOAT DEFAULT 0.0, -- or decimal??
    user_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
) ENGINE=INNODB;

CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
    sender_id INT NOT NULL,
    recipient_email VARCHAR(255) NOT NULL,
    amount FLOAT NOT NULL,
    message TEXT, 
    status ENUM('pending', 'completed', 'failed') DEFAULT 'pending', -- the indian man on youtube said this is ok
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sender_id) REFERENCES users(user_id)
) ENGINE=INNODB;

CREATE TABLE payment_methods (
    payment_method_id INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
    user_id INT NOT NULL,
    type ENUM('card', 'bank_account') NOT NULL,
    last_four VARCHAR(4),
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
) ENGINE=INNODB;