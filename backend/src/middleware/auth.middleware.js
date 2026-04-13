const jwt = require("jsonwebtoken");
const { formatDate } = require('../config/date');

/**
 * Middleware de autenticación que valida el token JWT en las cabeceras de la solicitud
 * Permite que solo usuarios autenticados accedan a rutas protegidas
 * @param Object req Objeto de solicitud HTTP
 * @param Object res Objeto de respuesta HTTP
 * @param Function next Función para pasar al siguiente middleware
 * @return void Valida el token y permite o deniega el acceso
 */
function authMiddleware(req, res, next) {
  
  // DATOS DE LOGS
  let originalIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
  if (originalIp.includes(',')) {
    originalIp = originalIp.split(',')[0].trim();
  }
    
  // Se extrae solo el IPv4
  const ip = originalIp.includes(':') ? originalIp.split(':').pop() : originalIp;
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