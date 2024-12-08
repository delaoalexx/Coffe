const express = require('express');
const router = express.Router();

const jwt = require('jsonwebtoken'); 
const authVerify = require('../middleware/authVerify');

require('dotenv').config();

// SIMPLE TRANSFER
// localhost:3000/transactions/transfers
router.post('/transfers', authVerify, async (req, res) => {
    let pool;
    let connection;
    try {
        const sender_id = req.user_id;
        const { recipient_email, amount, message } = req.body;

        if (!recipient_email || !amount) {
            return res.status(400).json({
                message: 'Faltan datos obligatorios'
            });
        }

        pool = req.dbPool;
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
// localhost:3000/transactions/payments
router.post('/payments', authVerify, async (req, res) => {
    let pool;
    let connection;
    try {
        const user_id = req.user_id;
        const { amount, institution, payment_concept } = req.body;

        pool = req.dbPool;
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
// localhost:3000/transactions/addFunds
router.post('/addFunds', authVerify, async (req, res) => {
    let pool;
    let connection;
    try {
        const user_id = req.user_id;
        const { card_id, amount } = req.body;

        pool = req.dbPool;
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

// TRANSACTIONS HISTORY
// localhost:3000/transactions/getTransactions
router.post('/getTransactions', authVerify, async (req, res) => {
    let pool;
    let connection;
    try {
        const user_id = req.user_id;

        pool = req.dbPool;
        connection = await pool.getConnection();

        const [result] = await connection.query(
            `SELECT created_at, amount, message, 
                CASE 
                    WHEN sender_id = ? THEN 'Gasto'
                    WHEN recipient_id = ? THEN 'Ingreso'
                END AS transaction_type
            FROM transactions WHERE sender_id = ? OR recipient_id = ? ORDER BY created_at DESC`,
            [user_id, user_id, user_id, user_id]
        );

        res.status(200).json({
            transactions: result
        });
    } catch (err) {
        console.error('Error al obtener historial de transacciones:', err);
        res.status(500).json({
            message: 'Error al obtener historial de transacciones',
            error: err.message
        });
    } finally {
        if (connection) connection.release();
    }
});

module.exports = router;