const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');

const jwt = require('jsonwebtoken'); 
const authVerify = require('../middleware/authVerify');

require('dotenv').config();

// SIMPLE USER READ
// localhost:3000/users
router.get('/', authVerify, async (req, res) => {
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
        if (connection) connection.release(); 
        // se supone que esto hace que se libere la conexion y asi poder spamear consultas a lo tonto
    }
});

// SIMPLE USER CREATE
// localhost:3000/users
router.post('/', async (req, res) => {
    let pool;
    let connection;
    try {
        const { first_name, last_name, email, password } = req.body;
        iterationJumps = 8;
        const hashedPassword = await new Promise((resolve, reject) => {
            bcrypt.hash(password, iterationJumps, (err, hash) => {
                if (err) {
                    console.error('Error al encriptar la contraseña:', err);
                    reject(new Error('Error interno al procesar la contraseña'));
                } else {
                    resolve(hash);
                }
            });
        });

        pool = req.dbPool;
        connection = await pool.getConnection();

        const [result] = await connection.query(
            'CALL SP_CREATE_USER(?, ?, ?, ?)',
            [first_name, last_name, email, hashedPassword]
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
// localhost:3000/users/login
router.post('/login', async (req, res) => {
    let pool;
    let connection;
    try {
        const { email, password } = req.body;

        pool = req.dbPool;
        connection = await pool.getConnection();

        const [users] = await connection.query(
            'SELECT user_id, password_hash FROM users WHERE email = ?',
            [email]
        );

        if (users.length === 0) {
            return res.status(401).json({
                message: 'Credenciales inválidas'
            });
        }

        const hashedPassword = users[0].password_hash;
        const isPasswordValid = await bcrypt.compare(password, hashedPassword);

        if (!isPasswordValid) {
            return res.status(401).json({
                message: 'Credenciales inválidas'
            });
        }

        // 🥶🥶🥶
        const token = jwt.sign({ user_id: users[0].user_id }, process.env.SECRET, { expiresIn: '1h' });

        res.status(200).json({
            message: 'Login exitoso',
            token: token
        });
    } catch (err) {
        console.error('Error en login:', err);
        res.status(401).json({
            message: 'Credenciales inválidas',
            error: err.message
        });
    } finally {
        if (connection) connection.release();
    }
});

// GET USER NAME
// localhost:3000/users/getName
router.post('/getName', authVerify, async (req, res) => {
    let pool;
    let connection;
    try {
        const user_id = req.user_id;

        pool = req.dbPool; 
        connection = await pool.getConnection();
        
        const [result] = await connection.query(
            'SELECT first_name FROM users WHERE user_id = ?',
            [user_id]
        );
     
        if (result.length === 0) {
            return res.status(404).json({
                message: 'Usuario no encontrado',
                error: 'No se encontró un usuario con IDS '
            });
        }
     
        res.status(200).json({
            user: result[0]
        });
    } catch (err) {
        console.error('Error al obtener nombre de usuario:', err);
        res.status(500).json({
            message: 'Error al obtener nombre de usuario',
            error: err.message
        });
    } finally {
        if (connection) connection.release();
    }
});

module.exports = router;