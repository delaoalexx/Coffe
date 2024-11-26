require('dotenv').config();
const express = require('express');
const bodyParser = require('body-parser');
const connect = require('./db');

const app = express();

app.use(bodyParser.urlencoded({extended: false}));
app.use(bodyParser.json());


app.get('/', (req, res) => {
    res.json({ message: 'Coffe working properly!' });
});

// SIMPLE USER READ
app.get('/users', async (req, res) => {
    let db;
    try {

        console.log('Intentando conectar a la base de datos');
        db = await connect();
        console.log('Conexión establecida');
        
        const query = "SELECT * FROM users";
        console.log('Ejecutando consulta:', query);
        
        const [rows] = await db.execute(query);
        console.log('Filas obtenidas:', rows);
        db = await connect();

        res.json({
            data: rows,
            status: 200
        });
    } catch(err) {
         console.error('Error:', err);
        res.status(500).json({
            message: 'Error al obtener usuarios',
            error: err.message
        });
    } finally {
        if(db)
            db.end();
    }
});


// SIMPLE USER CREATE
app.post('/users', async (req, res) => {
    let db;
    try {
        const { first_name, last_name, email, password } = req.body;
        
        db = await connect();
        const [result] = await db.execute(
            'CALL SP_CREATE_USER(?, ?, ?, ?)', 
            [first_name, last_name, email, password]
        );
        
        res.status(201).json({
            message: 'Usuario creado exitosamente',
            data: result[0]
        });
    } catch(err) {
        console.error('Error al crear usuario:', err);
        res.status(500).json({
            message: 'Error al crear usuario',
            error: err.message
        });
    }
});

// LOGIN
/*
app.post('/login', async (req, res) => {
    let db;
    try {
        const { email, password } = req.body;
        
        db = await connect();
        const [result] = await db.execute(
            'CALL SP_LOGIN(?, ?)', 
            [email, password]
        );
        
        res.json({
            message: 'Login exitoso',
            user: result[0][0],
            accounts: result[1]
        });
    } catch(err) {
        console.error('Error en login:', err);
        res.status(401).json({
            message: 'Credenciales inválidas',
            error: err.message
        });
    }
});

*/




// <3 to the fronts 

const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
    console.log(`Server connected.... Port: ${PORT}`);
});