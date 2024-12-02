const express = require('express');
const router = express.Router();

// SIMPLE USER READ
router.get('/', async (req, res) => {
    let pool;
    let connection;
    try {
        pool = req.dbPool;
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
router.post('/', async (req, res) => {
    let pool;
    let connection;
    try {
        const { first_name, last_name, email, password } = req.body;

        pool = req.dbPool;
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
router.post('/login', async (req, res) => {
    let pool;
    let connection;
    try {
        const { email, password } = req.body;

        pool = req.dbPool;
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

module.exports = router;