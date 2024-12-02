const express = require('express');
const router = express.Router();

// SIMPLE ADD CARD
router.post('/addCards', async (req, res) => { 

    let pool;
    let connection;
    const { user_id, card_number, card_holder, expiration_date, card_type } = req.body; // esto es mejor en dentro o fuera del try catch??

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

module.exports = router;