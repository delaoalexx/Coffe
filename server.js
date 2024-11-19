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


// <3 to the fronts and backs  

const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
    console.log(`Server connected.... Port: ${PORT}`);
});