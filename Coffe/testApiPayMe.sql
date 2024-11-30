USE apiPayMe;

-- este es user1  de pruebas
CALL SP_CREATE_USER('Arthur', 'Morgan', 'deer@gmail.com', '12345678');

-- update dinero para empezar a practicar
UPDATE accounts SET balance = 1000 WHERE user_id = 1;

-- este es el usuar2 de pruebas
CALL SP_CREATE_USER('John', 'Marston', 'wolf@gmail.com', '87654321');


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

	-- crear cards de prueba
CALL SP_ADD_CARD(2, 1234567890987654, 'Jhon ', '2026-12-31', 'credit');

-- probar pagos con dinero de monedero
CALL SP_MAKE_PAYMENT(1, 20, 'TELMEX', 'internetuh');
CALL SP_MAKE_PAYMENT(1, 400, 'NETFLIX', 'Pago streaming');
    
-- agregar dinero a cuenta 1 desde su tarjeta
CALL SP_ADD_FUNDS_FROM_CARD(2, 1, 1000);

-- general tablas
SELECT * FROM users;
SELECT * FROM accounts;
SELECT * FROM transactions;
SELECT * FROM cards;
SELECT * FROM error_logs;