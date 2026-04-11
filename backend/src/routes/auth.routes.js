const express = require("express");

// Se crea un router de Express
const router = express.Router();

const authController = require("../controllers/auth.controller");
const authMiddleware = require("../middleware/auth.middleware");
const User = require("../models/user.model");
const { formatDate } = require('../config/date');

// COMPROBAR EMAIL
router.post("/auth/email", authController.email);

// REGISTRO CON Google
router.post("/auth/google", authController.google);

// REGISTRO
router.post("/auth/register", authController.register);

// LOGIN
router.post("/auth/login", authController.login);


// OBTENCIÓN DE USUARIO
router.get("/users/me", authMiddleware, async (req, res) => {
  // DATOS DE LOGS
  let originalIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
  if (originalIp.includes(',')) {
    originalIp = originalIp.split(',')[0].trim();
  }
  
  // Se extrae solo el IPv4
  const ip = originalIp.includes(':') ? originalIp.split(':').pop() : originalIp;
  const date = formatDate();

  // Obtiene usuario de la base de datos
  const user = await User.findById(req.user.userId).select("-password");

  console.log(`${ip} - - [ ${date} ] "GET /users/me" 200 `);

  res.json(user);

});

// ACTUALIZAR PERFIL
router.put("/users/profile", authMiddleware, authController.updateProfile);

// CAMBIAR CONTRASEÑA
router.patch("/users/password", authMiddleware, authController.changePassword);

// ELIMINACIÓN DE CUENTA
router.delete("/users/profile", authMiddleware, authController.deleteProfile);

module.exports = router;