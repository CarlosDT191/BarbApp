const jwt = require("jsonwebtoken");
const { formatDate } = require('../config/date');

// Función que protege rutas usando el token
function authMiddleware(req, res, next) {
  
  // DATOS DE LOGS
  const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
  const date = formatDate();
  
  const authHeader = req.headers.authorization;

  if (!authHeader) {
    console.log(`${ip} - - [ ${date} ] "POST /auth/" 401 (Token requerido)`);
    return res.status(401).json({ error: "Token requerido" });
  }

  const token = authHeader.split(" ")[1];

  try {

    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    req.user = decoded;

    next();

  } catch (err) {
    console.log(`${ip} - - [ ${date} ] "POST /auth/" 401 (Token inválido)`);
    return res.status(401).json({ error: "Token inválido" });
  }
}

module.exports = authMiddleware;