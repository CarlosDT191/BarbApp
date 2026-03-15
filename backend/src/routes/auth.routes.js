const express = require("express");

// Se crea un router de Express
const router = express.Router();

const authController = require("../controllers/auth.controller");
const authMiddleware = require("../middleware/auth.middleware");
const User = require("../models/user.model");

// REGISTRO
router.post("/auth/register", authController.register);

// LOGIN
router.post("/auth/login", authController.login);

// OBTENCIÓN DE USUARIO
router.get("/users/me", authMiddleware, async (req, res) => {
  // Obtiene usuario de la base de datos
  const user = await User.findById(req.user.userId).select("-password");

  res.json(user);

});

module.exports = router;