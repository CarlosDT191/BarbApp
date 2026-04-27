const express = require("express");
const router = express.Router();

const featuresController = require("../controllers/features.controller");
const authMiddleware = require("../middleware/auth.middleware");

/*
* ===========================
*         RESERVAS
* ===========================
*/
// Obtener reservas del usuario
router.get("/reservations/me", authMiddleware, featuresController.getMyReservations);

// Crear reserva
router.post("/reservations", authMiddleware, featuresController.createReservation);

// Eliminar reserva por reservationId
router.delete("/reservations/:reservationId", authMiddleware, featuresController.deleteReservation);

/*
* ===========================
*         NEGOCIOS
* ===========================
*/
// Obtener negocios del usuario
router.get("/businesses/me", authMiddleware, featuresController.getMyBusinesses);

// Buscar locales reales en Google Places para enlazar un negocio
router.get("/businesses/google-places/search", authMiddleware, featuresController.searchGooglePlacesForBusinessLink);

// Consultar locales que ya estan registrados en la app por placeId de Google
router.get("/businesses/registered-by-place-ids", authMiddleware, featuresController.getRegisteredBusinessesByPlaceIds);

// Listar negocios registrados (busqueda opcional)
router.get("/businesses", authMiddleware, featuresController.listBusinesses);

// Obtener detalle de un negocio registrado
router.get("/businesses/:businessId", authMiddleware, featuresController.getBusinessDetails);

// Obtener disponibilidad de un negocio por servicio y fecha
router.get("/businesses/:businessId/availability", authMiddleware, featuresController.getBusinessAvailability);

// Crear negocio
router.post("/businesses", authMiddleware, featuresController.createBusiness);

// Editar negocio propio
router.put("/businesses/:businessId", authMiddleware, featuresController.updateMyBusiness);

// Eliminar negocio propio
router.delete("/businesses/:businessId", authMiddleware, featuresController.deleteMyBusiness);

// Guardar datos generados de la consulta de creación de negocio
router.post("/businesses/creation-data", authMiddleware, featuresController.createBusinessCreationData);

/*
* ===========================
*        FAVORITOS
* ===========================
*/
// Obtener favoritos del usuario
router.get("/favorites", authMiddleware, featuresController.getMyFavorites);

// Crear favorito de un local/negocio
router.post("/favorites", authMiddleware, featuresController.createFavorite);

// Eliminar favorito por businessId/placeId
router.delete("/favorites/:businessId", authMiddleware, featuresController.deleteFavorite);

/*
* ===========================
*      NOTIFICACIONES
* ===========================
*/
// DONDE DEBEN DE IR LAS NOTIFICACIONES
router.get("/notifications", authMiddleware, featuresController.getMyNotifications);

// Marcar como leída
router.patch("/notifications/:id/read", authMiddleware, featuresController.markAsRead);

module.exports = router;