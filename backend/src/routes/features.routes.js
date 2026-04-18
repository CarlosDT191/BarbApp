const express = require("express");
const router = express.Router();

const featuresController = require("../controllers/features.controller");
const authMiddleware = require("../middleware/auth.middleware");

// Obtener reservas del usuario
router.get("/reservations/me", authMiddleware, featuresController.getMyReservations);

// Crear reserva
router.post("/reservations", authMiddleware, featuresController.createReservation);

// Obtener negocios del usuario
router.get("/businesses/me", authMiddleware, featuresController.getMyBusinesses);

// Crear negocio
router.post("/businesses", authMiddleware, featuresController.createBusiness);

// Guardar datos generados de la consulta de creación de negocio
router.post("/businesses/creation-data", authMiddleware, featuresController.createBusinessCreationData);

// DONDE DEBEN DE IR LAS NOTIFICACIONES
router.get("/notifications", authMiddleware, featuresController.getMyNotifications);

// Marcar como leída
router.patch("/notifications/:id/read", authMiddleware, featuresController.markAsRead);

module.exports = router;