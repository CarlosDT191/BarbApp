const express = require("express");
const router = express.Router();

const businessesController = require("../controllers/businesses.controller");
const favoritesController = require("../controllers/favorites.controller");
const notificationsController = require("../controllers/notifications.controller");
const reservationsController = require("../controllers/reservations.controller");
const userController = require("../controllers/user.controller");
const authMiddleware = require("../middleware/auth.middleware");

/*
* ===================================
*         RESERVAS / CITAS
* ===================================
*/
// Obtener reservas del usuario
router.get("/reservations/me", authMiddleware, reservationsController.getMyReservations);

// Obtener citas del propietario
router.get("/appointments/me", authMiddleware, reservationsController.getMyAppointments);

// Crear cita del propietario
router.post("/appointments", authMiddleware, reservationsController.createAppointment);

// Crear reserva
router.post("/reservations", authMiddleware, reservationsController.createReservation);

// Eliminar reserva por reservationId
router.delete("/reservations/:reservationId", authMiddleware, reservationsController.deleteReservation);

/*
* ===========================
*         NEGOCIOS
* ===========================
*/
// Obtener negocios del usuario
router.get("/businesses/me", authMiddleware, businessesController.getMyBusinesses);

// Buscar locales reales en Google Places para enlazar un negocio
router.get("/businesses/google-places/search", authMiddleware, businessesController.searchGooglePlacesForBusinessLink);

// Consultar locales que ya estan registrados en la app por placeId de Google
router.get("/businesses/registered-by-place-ids", authMiddleware, businessesController.getRegisteredBusinessesByPlaceIds);

// Listar negocios registrados (busqueda opcional)
router.get("/businesses", authMiddleware, businessesController.listBusinesses);

// Obtener detalle de un negocio registrado
router.get("/businesses/:businessId", authMiddleware, businessesController.getBusinessDetails);

// Obtener disponibilidad de un negocio por servicio y fecha
router.get("/businesses/:businessId/availability", authMiddleware, businessesController.getBusinessAvailability);

// Crear negocio
router.post("/businesses", authMiddleware, businessesController.createBusiness);

// Editar negocio propio
router.put("/businesses/:businessId", authMiddleware, businessesController.updateMyBusiness);

// Eliminar negocio propio
router.delete("/businesses/:businessId", authMiddleware, businessesController.deleteMyBusiness);

// Guardar datos generados de la consulta de creación de negocio
router.post("/businesses/creation-data", authMiddleware, businessesController.createBusinessCreationData);

/*
* ===========================
*        FAVORITOS
* ===========================
*/
// Obtener favoritos del usuario
router.get("/favorites", authMiddleware, favoritesController.getMyFavorites);

// Crear favorito de un local/negocio
router.post("/favorites", authMiddleware, favoritesController.createFavorite);

// Eliminar favorito por businessId/placeId
router.delete("/favorites/:businessId", authMiddleware, favoritesController.deleteFavorite);

/*
* ===========================
*      NOTIFICACIONES
* ===========================
*/
// DONDE DEBEN DE IR LAS NOTIFICACIONES
router.get("/notifications", authMiddleware, notificationsController.getMyNotifications);

// Marcar como leída
router.patch("/notifications/:id/read", authMiddleware, notificationsController.markAsRead);

/*
* ===========================
*         USUARIOS
* ===========================
*/
// OBTENER MÁS INFORMACIÓN DEL USUARIO
router.get("/users/me", authMiddleware, userController.obtainData);

// REGISTRAR TOKEN DE DISPOSITIVO PARA NOTIFICACIONES
router.post("/users/device-token", authMiddleware, userController.registerDeviceToken);

// ACTUALIZAR PERFIL
router.put("/users/profile", authMiddleware, userController.updateProfile);

// CAMBIAR CONTRASEÑA
router.patch("/users/password", authMiddleware, userController.changePassword);

// ELIMINACIÓN DE CUENTA
router.delete("/users/profile", authMiddleware, userController.deleteProfile);

module.exports = router;