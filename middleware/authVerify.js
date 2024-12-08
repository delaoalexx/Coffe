const jwt = require("jsonwebtoken");

require('dotenv').config();

function authVerify(req, res, next) {
    const token = req.header('Authorization');
   
    if (!token)
        return res.status(401).json({'error': 'You do not have permission to access'});
   
    const bearer = token.split(' ')[1];
   
    try {
        const decoded = jwt.verify(bearer, process.env.SECRET);
        req.user_id = decoded.user_id;

        next();
    } catch(err) {
        return res.status(401).json({'error': 'An error occurred: ' + err});
    }
}

module.exports = authVerify