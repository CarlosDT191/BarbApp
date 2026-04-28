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

module.exports = router;