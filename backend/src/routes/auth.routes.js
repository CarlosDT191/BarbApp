const express = require("express");

// Se crea un router de Express
const router = express.Router();

const authController = require("../controllers/auth.controller");
const authMiddleware = require("../middleware/auth.middleware");
const User = require("../models/user.model");
const { formatDate } = require('../config/date');

// COMPROBAR EMAIL
router.post("/auth/email", authController.email);

// LOGIN
router.post("/auth/login", authController.login);

// REGISTRO
router.post("/auth/register", authController.register);

// OBTENCIÓN DE USUARIO
router.get("/users/me", authMiddleware, async (req, res) => {
  // DATOS DE LOGS
  const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
  const date = formatDate();

  // Obtiene usuario de la base de datos
  const user = await User.findById(req.user.userId).select("-password");

  console.log(`${ip} - - [ ${date} ] "GET /auth/me" 200 `);

  res.json(user);

});

module.exports = router;