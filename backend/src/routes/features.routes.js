const express = require("express");
const router = express.Router();

const featuresController = require("../controllers/features.controller");
const authMiddleware = require("../middleware/auth.middleware");

// Obtener reservas del usuario
router.get("/reservations/me", authMiddleware, featuresController.getMyReservations);

// Crear reserva
router.post("/reservations", authMiddleware, featuresController.createReservation);

// Eliminar reserva por reservationId
router.delete("/reservations/:reservationId", authMiddleware, featuresController.deleteReservation);

// Obtener negocios del usuario
router.get("/businesses/me", authMiddleware, featuresController.getMyBusinesses);

// Obtener favoritos del usuario
router.get("/favorites", authMiddleware, featuresController.getMyFavorites);

// Crear favorito de un local/negocio
router.post("/favorites", authMiddleware, featuresController.createFavorite);

// Eliminar favorito por businessId/placeId
router.delete("/favorites/:businessId", authMiddleware, featuresController.deleteFavorite);

// Buscar locales reales en Google Places para enlazar un negocio
router.get("/businesses/google-places/search", authMiddleware, featuresController.searchGooglePlacesForBusinessLink);

// Consultar locales que ya estan registrados en la app por placeId de Google
router.get("/businesses/registered-by-place-ids", authMiddleware, featuresController.getRegisteredBusinessesByPlaceIds);

// Crear negocio
router.post("/businesses", authMiddleware, featuresController.createBusiness);

// Guardar datos generados de la consulta de creación de negocio
router.post("/businesses/creation-data", authMiddleware, featuresController.createBusinessCreationData);

// DONDE DEBEN DE IR LAS NOTIFICACIONES
router.get("/notifications", authMiddleware, featuresController.getMyNotifications);

// Marcar como leída
router.patch("/notifications/:id/read", authMiddleware, featuresController.markAsRead);

module.exports = router;