const express = require('express');
const app = express();
const db = require('./db');

app.set('view engine', 'ejs');
app.use(express.urlencoded({ extended: true }));

app.get('/', (req, res) => {
    res.send('Off Campus Connect is running!');
});

app.listen(3000, () => {
    console.log('Server running at http://localhost:3000');
});