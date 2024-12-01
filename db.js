const mysql = require('mysql2/promise');

let pool;

async function connect() {
    if (!pool) {
        try {
            pool = mysql.createPool({
                host: process.env.DB_HOST,
                port: process.env.DB_PORT,
                user: process.env.DB_USER,
                password: process.env.DB_PASSWORD,
                database: process.env.DB_NAME,
                waitForConnections: true,
                connectionLimit: 10, 
                queueLimit: 0 
            });
            console.log('conexión a la bd establecida');
        } catch (err) {
            console.error('Ocurrió un error:', err);
            throw err;
        }
    }
    return pool;
}

module.exports = connect;
