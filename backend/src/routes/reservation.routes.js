const express = require("express");
const router = express.Router();

const reservationController = require("../controllers/features.controller");
const authMiddleware = require("../middleware/auth.middleware");

// Obtener reservas del usuario
router.get("/reservations/me", authMiddleware, reservationController.getMyReservations);

// Crear reserva
router.post("/reservations", authMiddleware, reservationController.createReservation);

module.exports = router;