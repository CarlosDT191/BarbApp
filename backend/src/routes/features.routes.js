const express = require("express");
const router = express.Router();

const featuresController = require("../controllers/features.controller");
const authMiddleware = require("../middleware/auth.middleware");

// Obtener reservas del usuario
router.get("/reservations/me", authMiddleware, featuresController.getMyReservations);

// Crear reserva
router.post("/reservations", authMiddleware, featuresController.createReservation);

// DONDE DEBEN DE IR LAS NOTIFICACIONES
router.get("/notifications", authMiddleware, featuresController.getMyNotifications);

// Marcar como leída
router.patch("/notifications/:id/read", authMiddleware, featuresController.markAsRead);

module.exports = router;