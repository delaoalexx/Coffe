require('dotenv').config();
const express = require('express');
const bodyParser = require('body-parser');
const connect = require('./config/db');

const app = express();

const userRoutes = require('./routes/users');
const transactionRoutes = require('./routes/transactions');
const cardRoutes = require('./routes/cards');

app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());

// Middleware to verify the connection with the database
app.use(async (req, res, next) => {
    try {
        const pool = await connect();
        req.dbPool = pool; // Adjuntar la conexión al del req
        next();
    } catch (err) {
        console.error('Error al conectar con la base de datos:', err);
        res.status(500).json({ message: 'Error interno del servidor' });
    }
});

app.use('/users', userRoutes);
app.use('/transactions', transactionRoutes);
app.use('/cards', cardRoutes);

//localhost:3000/
app.get('/', (req, res) => {
    res.json({ message: 'Coffe working properly!' });
});

// if (connection) connection.release(); 

// <3 to the team
const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
    console.log(`Server connected.... Port: ${PORT}`);
    console.log('<3 to the team');
});
