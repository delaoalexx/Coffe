const express = require('express');
const router = express.Router();

// SIMPLE TRANSFER
router.post('/transfers', async (req, res) => {
    let pool;
    let connection;
    try {
        const { sender_id, recipient_email, amount, message } = req.body;

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
router.post('/payments', async (req, res) => {
    let pool;
    let connection;
    try {
        const { user_id, amount, institution, payment_concept } = req.body;

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
router.post('/addFunds', async (req, res) => {
    let pool;
    let connection;
    try {
        const { user_id, card_id, amount } = req.body;

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

module.exports = router;