const express = require('express');
const router = express.Router();

const jwt = require('jsonwebtoken'); 
const authVerify = require('../middleware/authVerify');

require('dotenv').config();

// SIMPLE ADD CARD
// localhost:3000/cards/addCards
router.post('/addCards', async (req, res) => { 

    let pool;
    let connection;

    const user_id = req.body.user_id;

    const { card_number, card_holder, expiration_date, card_type } = req.body; 
    // esto es mejor en dentro o fuera del try catch??
    if (!card_number || !card_holder || !expiration_date || !card_type) {
        return res.status(400).json({ 
            message: 'Faltan datos obligatorios'
        });
    }

    try {
        pool = req.dbPool;
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
        if (connection) connection.release();
    }

});

// GET ACCOUNTS BALANCE
// localhost:3000/cards/getBalance
router.post('/getBalance', async (req, res) => {
    let pool;
    let connection;
    try {
        const user_id = req.body.user_id;

        pool = req.dbPool;
        connection = await pool.getConnection();

        const [result] = await connection.query(
            `SELECT balance FROM accounts WHERE user_id = ?`,
            [user_id]
        );

        res.status(200).json({
            availableBalance: result[0]
        });
    } catch (err) {
        console.error('Error al obtener el balance disponible:', err);
        res.status(500).json({
            message: 'Error al obtener el balance disponible',
            error: err.message
        });
    } finally {
        if (connection) connection.release();
    }
});

// GET INCOME SUMMARY
// localhost:3000/cards/getIncome
router.post('/getIncome', async (req, res) => {
    let pool;
    let connection;
    try {

        const user_id = req.body.user_id;

        pool = req.dbPool;
        connection = await pool.getConnection();

        const [result] = await connection.query(
            `SELECT income FROM accounts WHERE user_id = ?`,
            [user_id]
        );

        res.status(200).json({
            accountSummary: result[0]
        });
    } catch (err) {
        console.error('Error al obtener resumen de ingresos de la cuenta:', err);
        res.status(500).json({
            message: 'Error al obtener resumen de ingresos de la cuenta',
            error: err.message
        });
    } finally {
        if (connection) connection.release();
    }
});

// GET EXPENSE SUMMARY
// localhost:3000/cards/getExpense
router.post('/getExpense', async (req, res) => {
    let pool;
    let connection;
    try {

        const user_id = req.body.user_id;

        pool = req.dbPool;
        connection = await pool.getConnection();

        const [result] = await connection.query(
            `SELECT expense FROM accounts WHERE user_id = ?`,
            [user_id]
        );

        res.status(200).json({
            accountSummary: result[0]
        });
    } catch (err) {
        console.error('Error al obtener resumen de gastos de la cuenta:', err);
        res.status(500).json({
            message: 'Error al obtener resumende gastos de la cuenta',
            error: err.message
        });
    } finally {
        if (connection) connection.release();
    }
});

// GET USER CARDS
// localhost:3000/cards/getCards
router.post('/getCards', async (req, res) => {
    let pool;
    let connection;
    try {
        const user_id = req.body.user_id;

        pool = req.dbPool;
        connection = await pool.getConnection();

        const [result] = await connection.query(
            `SELECT 
                card_id, 
                CONCAT('', RIGHT(card_number, 4)),
                expiration_date, 
                card_type 
            FROM cards WHERE user_id = ?`,
            [user_id]
        );

        res.status(200).json({
            cards: result
        });
    } catch (err) {
        console.error('Error al obtener las tarjetas del usuario:', err);
        res.status(500).json({
            message: 'Error al obtener las tarjetas del usuario',
            error: err.message
        });
    } finally {
        if (connection) connection.release();
    }
});

module.exports = router;