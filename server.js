require('dotenv').config();
const express = require('express');
const bodyParser = require('body-parser');
const connect = require('./db');

const app = express();

app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());

app.get('/', (req, res) => {
    res.json({ message: 'Coffe working properly!' });
});

// if (connection) connection.release(); 

// SIMPLE USER READ
app.get('/users', async (req, res) => {
    let pool;
    let connection;
    try {
        pool = await connect();
        connection = await pool.getConnection();
        console.log('Conexión establecida con el pool');

        const query = "SELECT * FROM users";
        console.log('Ejecutando consulta:', query);

        const [rows] = await connection.query(query);
        console.log('Filas obtenidas:', rows);

        res.json({
            data: rows,
            status: 200
        });
    } catch (err) {
        console.error('Error:', err);
        res.status(500).json({
            message: 'Error al obtener usuarios',
            error: err.message
        });
    } finally {
        if (connection) connection.release(); // se supone que esto hace que se libere la conexion y asi poder spamear consultas a lo tonto
    }
});

// SIMPLE USER CREATE
app.post('/users', async (req, res) => {
    let pool;
    let connection;
    try {
        const { first_name, last_name, email, password } = req.body;

        pool = await connect();
        connection = await pool.getConnection();

        const [result] = await connection.query(
            'CALL SP_CREATE_USER(?, ?, ?, ?)',
            [first_name, last_name, email, password]
        );

        res.status(201).json({
            message: 'Usuario creado exitosamente',
            data: result[0]
        });
    } catch (err) {
        console.error('Error al crear usuario:', err);
        res.status(500).json({
            message: 'Error al crear usuario',
            error: err.message
        });
    } finally {
        if (connection) connection.release();
        // conexion.release();
    }
});

// LOGIN
app.post('/login', async (req, res) => {
    let pool;
    let connection;
    try {
        const { email, password } = req.body;

        pool = await connect();
        connection = await pool.getConnection();

        const [result] = await connection.query(
            'CALL SP_LOGIN(?, ?)',
            [email, password]
        );

        res.json({
            message: 'Login exitoso'
        });
    } catch (err) {
        console.error('Error en login:', err);
        res.status(401).json({
            message: 'Credeniales inválidas',
            error: err.message
        });
    } finally {
        if (connection) connection.release();
    }
});

// SIMPLE TRANSFER
app.post('/transfers', async (req, res) => {
    let pool;
    let connection;
    try {
        const { sender_id, recipient_email, amount, message } = req.body;

        pool = await connect();
        connection = await pool.getConnection();

        const [result] = await connection.query(
            'CALL SP_MAKE_TRANSFER(?, ?, ?, ?)',
            [sender_id, recipient_email, amount, message || null]
        );

        res.status(201).json({
            message: 'Transferencia realizada exitosamente',
            transfer: result[0][0]
        });
    } catch (err) {
        console.error('Error en transferencia:', err);
        res.status(500).json({
            message: 'Error al realizar transferencia',
            error: err.message
        });
    } finally {
        if (connection) connection.release();
    }
});  


// SIMPLE MAKE PAYMENT
app.post('/payments', async (req, res) => {
    let pool;
    let connection;
    try {
        const { user_id, amount, institution, payment_concept } = req.body;

        pool = await connect();
        connection = await pool.getConnection();
        
        const [result] = await connection.query(
            'CALL SP_MAKE_PAYMENT(?, ?, ?, ?)',
            [
                user_id, 
                amount, 
                institution, 
                payment_concept
            ]
        );

        res.status(201).json({
            message: 'Pago realizado exitosamente',
            payment: result[0][0]
        });
    } catch (err) {
        console.error('Error al realizar pago:', err);
        res.status(500).json({
            message: 'Error al realizar pago',
            error: err.message
        });
    } finally {
        if (connection) connection.release();
    }
});

// SIMPLE ADD FUUNDAS
app.post('/addFunds', async (req, res) => {
    let pool;
    let connection;
    try {
        const { user_id, card_id, amount } = req.body;

        pool = await connect();
        connection = await pool.getConnection();
        const [result] = await connection.query(
            'CALL SP_ADD_FUNDS_FROM_CARD(?, ?, ?)',
            [
                user_id, 
                card_id, 
                amount
            ]
        );

        res.status(201).json({
            message: 'Fondos agregados exitosamente',
            transaction: result[0][0]
        });
    } catch (err) {
        console.error('Error al agregar fondos:', err);
        res.status(500).json({
            message: 'Error al agregar fondos',
            error: err.message
        });
    } finally {
        if (connection) connection.release();
    }
});

// SIMPLE ADD CARD

app.post('/addCards', async (req, res) => { 

    let pool;
    let connection;

    const { user_id, card_number, card_holder, expiration_date, card_type } = req.body;

    try {

        pool = await connect();
        connection = await pool.getConnection();
        console.log('Conexión establecida con el pool');
        
        const query = 'CALL SP_ADD_CARD(?, ?, ?, ?, ?)';
        const values = [user_id, card_number, card_holder, expiration_date, card_type];
        console.log('Ejecutando procedimiento almacenado:', query, 'con valores:', values);
        const [rows] = await connection.query(query, values);
        
        res.json({
            data: rows[0],
            status: 200
        });

    } catch (err) {
        console.error('Error:', err);
        res.status(500).json({
            message: 'Error al agregar la tarjeta',
            error: err.message
        });
    } finally {
        if (connection) connection.release(); // Liberar la conexión
    }

});

// <3 to the team
const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
    console.log(`Server connected.... Port: ${PORT}`);
    console.log('<3 to the team');
});
