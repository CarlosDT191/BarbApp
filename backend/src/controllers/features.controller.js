const Reservation = require("../models/reservation.model");
const Notification = require("../models/notification.model");
const User = require("../models/user.model");
const Business = require("../models/business.model");
const Favorite = require("../models/favorite.model");
const BusinessCreationRequest = require("../models/business_creation_request.model");
const { formatDate } = require('../config/date');

const GOOGLE_PLACES_TEXT_SEARCH_URL = "https://maps.googleapis.com/maps/api/place/textsearch/json";
const GOOGLE_PLACES_ALLOWED_TYPES = new Set(["hair_care", "barber_shop"]);

const getGoogleMapsApiKey = () => (
  process.env.GOOGLE_MAPS_API_KEY ||
  process.env.google_maps_api_key ||
  ""
).trim();

const mapGooglePlacesTextSearchResult = (rawResult) => {
  if (!rawResult || typeof rawResult !== "object") {
    return null;
  }

  const placeId = typeof rawResult.place_id === "string" ? rawResult.place_id.trim() : "";
  const name = typeof rawResult.name === "string" ? rawResult.name.trim() : "";
  const addressCandidate = typeof rawResult.formatted_address === "string"
    ? rawResult.formatted_address
    : rawResult.vicinity;
  const address = typeof addressCandidate === "string" ? addressCandidate.trim() : "";

  const geometry = rawResult.geometry;
  const location = geometry && typeof geometry === "object" ? geometry.location : null;
  const lat = Number(location && typeof location === "object" ? location.lat : NaN);
  const lng = Number(location && typeof location === "object" ? location.lng : NaN);

  if (!placeId || !name || !address || !Number.isFinite(lat) || !Number.isFinite(lng)) {
    return null;
  }

  return {
    placeId,
    name,
    address,
    location: {
      lat,
      lng,
    },
  };
};

const normalizeGooglePlacePayload = (rawGooglePlace) => {
  if (!rawGooglePlace || typeof rawGooglePlace !== "object") {
    return null;
  }

  const placeId = typeof rawGooglePlace.placeId === "string" ? rawGooglePlace.placeId.trim() : "";
  const name = typeof rawGooglePlace.name === "string" ? rawGooglePlace.name.trim() : "";
  const address = typeof rawGooglePlace.address === "string" ? rawGooglePlace.address.trim() : "";

  const rawLocation = rawGooglePlace.location;
  const lat = Number(rawLocation && typeof rawLocation === "object" ? rawLocation.lat : NaN);
  const lng = Number(rawLocation && typeof rawLocation === "object" ? rawLocation.lng : NaN);

  if (!placeId || !name || !address || !Number.isFinite(lat) || !Number.isFinite(lng)) {
    return null;
  }

  return {
    placeId,
    name,
    address,
    location: {
      lat,
      lng,
    },
  };
};

const BUSINESS_SCHEDULE_MODES = new Set(["single", "by_day"]);

const toTrimmedString = (value) => (typeof value === "string" ? value.trim() : "");

const parseTimeToMinutes = (rawTime) => {
  const time = toTrimmedString(rawTime);
  if (!/^\d{2}:\d{2}$/.test(time)) {
    return null;
  }

  const [hourRaw, minuteRaw] = time.split(":");
  const hour = Number(hourRaw);
  const minute = Number(minuteRaw);

  if (
    !Number.isInteger(hour) ||
    !Number.isInteger(minute) ||
    hour < 0 ||
    hour > 23 ||
    minute < 0 ||
    minute > 59
  ) {
    return null;
  }

  return (hour * 60) + minute;
};

const normalizeBusinessOfferPayload = (rawOffer) => {
  if (!rawOffer || typeof rawOffer !== "object") {
    return null;
  }

  const name = toTrimmedString(rawOffer.name);
  const serviceType = toTrimmedString(rawOffer.serviceType);
  const price = Number(rawOffer.price);
  const durationMinutes = Number(rawOffer.durationMinutes);

  if (!name || !serviceType || !Number.isFinite(price) || price < 0 || !Number.isInteger(durationMinutes) || durationMinutes <= 0) {
    return null;
  }

  return {
    name,
    serviceType,
    price,
    durationMinutes,
  };
};

const normalizeBusinessScheduleDayPayload = (rawDay) => {
  if (!rawDay || typeof rawDay !== "object") {
    return null;
  }

  const day = toTrimmedString(rawDay.day);
  const isOpen = rawDay.isOpen === true;
  const openTime = toTrimmedString(rawDay.openTime);
  const closeTime = toTrimmedString(rawDay.closeTime);
  const isSplitShift = rawDay.isSplitShift === true;
  const secondOpenTime = toTrimmedString(rawDay.secondOpenTime);
  const secondCloseTime = toTrimmedString(rawDay.secondCloseTime);

  if (!day) {
    return null;
  }

  if (!isOpen) {
    return {
      day,
      isOpen: false,
      openTime: openTime || "00:00",
      closeTime: closeTime || "00:00",
      isSplitShift: false,
      secondOpenTime: "",
      secondCloseTime: "",
    };
  }

  const openMinutes = parseTimeToMinutes(openTime);
  const closeMinutes = parseTimeToMinutes(closeTime);
  if (openMinutes === null || closeMinutes === null || closeMinutes <= openMinutes) {
    return null;
  }

  if (!isSplitShift) {
    return {
      day,
      isOpen: true,
      openTime,
      closeTime,
      isSplitShift: false,
      secondOpenTime: "",
      secondCloseTime: "",
    };
  }

  const secondOpenMinutes = parseTimeToMinutes(secondOpenTime);
  const secondCloseMinutes = parseTimeToMinutes(secondCloseTime);

  if (
    secondOpenMinutes === null ||
    secondCloseMinutes === null ||
    secondCloseMinutes <= secondOpenMinutes ||
    secondOpenMinutes <= closeMinutes
  ) {
    return null;
  }

  return {
    day,
    isOpen: true,
    openTime,
    closeTime,
    isSplitShift: true,
    secondOpenTime,
    secondCloseTime,
  };
};

const normalizeBusinessScheduleMode = (rawScheduleMode) => {
  const scheduleMode = toTrimmedString(rawScheduleMode);
  if (BUSINESS_SCHEDULE_MODES.has(scheduleMode)) {
    return scheduleMode;
  }

  return "single";
};

/**
 * Obtiene todas las reservas del usuario autenticado
 * Ordena las reservas por fecha de forma ascendente
 * @param string req.user.userId ID del usuario autenticado (del token)
 * @return json [objects] Array de objetos de reservas del usuario
 */
// 🔹 Obtener reservas del usuario logueado
exports.getMyReservations = async (req, res) => {
  try {
    // DATOS DE LOGS
    let originalIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    if (originalIp.includes(',')) {
      originalIp = originalIp.split(',')[0].trim();
    }

    // Se extrae solo el IPv4
    const ip = originalIp.includes(':') ? originalIp.split(':').pop() : originalIp;
    const date = formatDate();

    const userId = req.user.userId;

    const reservations = await Reservation.find({ user: userId })
      .sort({ date: 1 });

    res.json(reservations);

    console.log(`${ip} - - [ ${date} ] "GET /reservations/me" 200`);

  } catch (err) {
    console.error(err);
    let originalIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    if (originalIp.includes(',')) {
      originalIp = originalIp.split(',')[0].trim();
    }

    const ip = originalIp.includes(':') ? originalIp.split(':').pop() : originalIp;
    const date = formatDate();
    console.log(`${ip} - - [ ${date} ] "GET /reservations/me" 500`);
    res.status(500).json({ error: "Error interno del servidor" });
  }
};

/**
 * Crea una nueva reserva para el usuario autenticado
 * Genera automáticamente una notificación asociada a la reserva
 * @param string req.user.userId ID del usuario autenticado (del token)
 * @param Object req.body.date Fecha de la reserva (YYYY-MM-DD)
 * @param string req.body.time Hora de la reserva (HH:mm)
 * @param string req.body.local_name Nombre del local/establecimiento para la reserva
 * @return json {object} Objeto con los datos de la reserva creada
 */
// 🔹 Crear reserva (opcional pero recomendable)
exports.createReservation = async (req, res) => {
  try {
    // DATOS DE LOGS
    let originalIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    if (originalIp.includes(',')) {
      originalIp = originalIp.split(',')[0].trim();
    }
    
    // Se extrae solo el IPv4
    const ip = originalIp.includes(':') ? originalIp.split(':').pop() : originalIp;
    const log_date = formatDate();

    const userId = req.user.userId;

    const { date, time, local_name } = req.body;

    if (!date || !time || !local_name) {
      console.log(`${ip} - - [ ${log_date} ] "POST /reservations" 400 (Campos obligatorios)`);
      return res.status(400).json({ error: "Campos obligatorios" });
    }

    const fixedDate = new Date(date);
    fixedDate.setDate(fixedDate.getDate() + 1);

    const reservation = await Reservation.create({
      user: userId,
      date: fixedDate,
      time,
      local_name
    });

    const formattedDate = new Date(fixedDate).toLocaleDateString('es-ES', {
      day: 'numeric',
      month: 'long',
      year: 'numeric',
    });

    await Notification.create({
      user: userId,
      type: "reservation",
      message: `Reserva confirmada en ${local_name} el ${formattedDate} a las ${time}`,
      relatedId: reservation._id
    });
    
    res.json(reservation);

    let formated_date = formatDate();
    
    console.log(`${ip} - - [ ${formated_date} ] "POST /reservations" 200`);

  } catch (err) {
    console.error(err);
    let originalIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    if (originalIp.includes(',')) {
      originalIp = originalIp.split(',')[0].trim();
    }

    const ip = originalIp.includes(':') ? originalIp.split(':').pop() : originalIp;
    const log_date = formatDate();
    console.log(`${ip} - - [ ${log_date} ] "POST /reservations" 500`);
    res.status(500).json({ error: "Error interno del servidor" });
  }
};

/**
 * Elimina una reserva específica del usuario autenticado
 * @param string req.user.userId ID del usuario autenticado (del token)
 * @param string req.params.reservationId Identificador de la reserva
 * @return json {removed: boolean} Indica si se eliminó la reserva
 */
exports.deleteReservation = async (req, res) => {
  try {
    let originalIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    if (originalIp.includes(',')) {
      originalIp = originalIp.split(',')[0].trim();
    }

    // Se extrae solo el IPv4
    const ip = originalIp.includes(':') ? originalIp.split(':').pop() : originalIp;
    const date = formatDate();

    const userId = req.user.userId;
    const rawReservationId = typeof req.params.reservationId === "string" ? req.params.reservationId : "";
    const reservationId = rawReservationId.trim();

    if (!reservationId) {
      console.log(`${ip} - - [ ${date} ] "DELETE /reservations/:reservationId" 400 (reservationId es obligatorio)`);
      return res.status(400).json({ error: "reservationId es obligatorio" });
    }

    const deleted = await Reservation.findOneAndDelete({ _id: reservationId, user: userId });

    console.log(`${ip} - - [ ${date} ] "DELETE /reservations/:reservationId" 200`);

    return res.json({ removed: Boolean(deleted) });
  } catch (err) {
    console.error(err);
    let originalIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    if (originalIp.includes(',')) {
      originalIp = originalIp.split(',')[0].trim();
    }

    const ip = originalIp.includes(':') ? originalIp.split(':').pop() : originalIp;
    const date = formatDate();
    console.log(`${ip} - - [ ${date} ] "DELETE /reservations/:reservationId" 500`);
    return res.status(500).json({ error: "Error interno del servidor" });
  }
};

/**
 * Obtiene todas las notificaciones del usuario autenticado
 * Ordena las notificaciones por fecha de creación en orden descendente
 * @param string req.user.userId ID del usuario autenticado (del token)
 * @return json [objects] Array de notificaciones del usuario
 */
// 🔹 Obtener notificaciones del usuario
exports.getMyNotifications = async (req, res) => {
  try {
    let originalIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    if (originalIp.includes(',')) {
      originalIp = originalIp.split(',')[0].trim();
    }
    
    // Se extrae solo el IPv4
    const ip = originalIp.includes(':') ? originalIp.split(':').pop() : originalIp;
    const date = formatDate();

    const userId = req.user.userId;

    const notifications = await Notification
      .find({ user: userId })
      .sort({ createdAt: -1 });

    res.json(notifications);

    console.log(`${ip} - - [ ${date} ] "GET /notifications" 200`);

  } catch (err) {
    console.error(err);
    let originalIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    if (originalIp.includes(',')) {
      originalIp = originalIp.split(',')[0].trim();
    }

    const ip = originalIp.includes(':') ? originalIp.split(':').pop() : originalIp;
    const date = formatDate();
    console.log(`${ip} - - [ ${date} ] "GET /notifications" 500`);
    res.status(500).json({ error: "Error interno del servidor" });
  }
};

/**
 * Marca una notificación específica como leída
 * Solo afecta notificaciones que pertenecen al usuario autenticado
 * @param string req.user.userId ID del usuario autenticado (del token)
 * @param string req.params.id ID de la notificación a marcar como leída
 * @return json {message: string} Mensaje confirmando que la notificación se marcó como leída
 */
// 🔹 Marcar notificación como leída
exports.markAsRead = async (req, res) => {
  try {
    const userId = req.user.userId;
    let originalIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    if (originalIp.includes(',')) {
      originalIp = originalIp.split(',')[0].trim();
    }
    
    // Se extrae solo el IPv4
    const ip = originalIp.includes(':') ? originalIp.split(':').pop() : originalIp;
    const date = formatDate();    

    await Notification.findOneAndUpdate(
      { _id: req.params.id, user: userId },
      { read: true }
    );

    console.log(`${ip} - - [ ${date} ] "PATCH /notifications/:id/read" 200`);

  } catch (err) {
    let originalIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    if (originalIp.includes(',')) {
      originalIp = originalIp.split(',')[0].trim();
    }

    const ip = originalIp.includes(':') ? originalIp.split(':').pop() : originalIp;
    const date = formatDate();
    console.log(`${ip} - - [ ${date} ] "PATCH /notifications/:id/read" 500`);
    res.status(500).json({ error: "Error interno del servidor" });
  }
};

/**
 * Obtiene todos los negocios del usuario autenticado
 * @param string req.user.userId ID del usuario autenticado (del token)
 * @return json [objects] Array de negocios del usuario
 */
exports.getMyBusinesses = async (req, res) => {
  try {
    let originalIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    if (originalIp.includes(',')) {
      originalIp = originalIp.split(',')[0].trim();
    }

    const ip = originalIp.includes(':') ? originalIp.split(':').pop() : originalIp;
    const date = formatDate();
    const userId = req.user.userId;

    const businesses = await Business.find({ owner: userId }).sort({ createdAt: -1 });

    res.json(businesses);
    console.log(`${ip} - - [ ${date} ] "GET /businesses/me" 200`);
  } catch (err) {
    console.error(err);
    let originalIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    if (originalIp.includes(',')) {
      originalIp = originalIp.split(',')[0].trim();
    }

    const ip = originalIp.includes(':') ? originalIp.split(':').pop() : originalIp;
    const date = formatDate();
    console.log(`${ip} - - [ ${date} ] "GET /businesses/me" 500`);
    res.status(500).json({ error: "Error interno del servidor" });
  }
};

/**
 * Actualiza un negocio del usuario autenticado
 * @param string req.user.userId ID del usuario autenticado (del token)
 * @param string req.params.businessId ID del negocio
 * @param Object req.body Datos editables del negocio
 * @return json {object} Negocio actualizado
 */
exports.updateMyBusiness = async (req, res) => {
  try {
    let originalIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    if (originalIp.includes(',')) {
      originalIp = originalIp.split(',')[0].trim();
    }

    const ip = originalIp.includes(':') ? originalIp.split(':').pop() : originalIp;
    const date = formatDate();

    const userId = req.user.userId;
    const businessId = toTrimmedString(req.params.businessId);

    if (!businessId) {
      console.log(`${ip} - - [ ${date} ] "PUT /businesses/:businessId" 400 (businessId es obligatorio)`);
      return res.status(400).json({ error: "businessId es obligatorio" });
    }

    const {
      name,
      offers,
      schedule,
      scheduleMode,
      employeeCount,
    } = req.body;

    const normalizedName = toTrimmedString(name);
    const normalizedOffersWithValidation = Array.isArray(offers)
      ? offers.map(normalizeBusinessOfferPayload)
      : null;
    const normalizedScheduleWithValidation = Array.isArray(schedule)
      ? schedule.map(normalizeBusinessScheduleDayPayload)
      : null;
    const hasInvalidOffer = normalizedOffersWithValidation !== null &&
      normalizedOffersWithValidation.some((offer) => offer === null);
    const hasInvalidSchedule = normalizedScheduleWithValidation !== null &&
      normalizedScheduleWithValidation.some((day) => day === null);
    const normalizedOffers = normalizedOffersWithValidation
      ? normalizedOffersWithValidation.filter(Boolean)
      : null;
    const normalizedSchedule = normalizedScheduleWithValidation
      ? normalizedScheduleWithValidation.filter(Boolean)
      : null;
    const normalizedScheduleMode = normalizeBusinessScheduleMode(scheduleMode);
    const normalizedEmployeeCount = Number(employeeCount);

    if (
      hasInvalidOffer ||
      hasInvalidSchedule ||
      normalizedOffers === null ||
      normalizedOffers.length === 0 ||
      normalizedSchedule === null ||
      normalizedSchedule.length === 0 ||
      !normalizedSchedule.some((day) => day.isOpen) ||
      !Number.isInteger(normalizedEmployeeCount) ||
      normalizedEmployeeCount < 0
    ) {
      console.log(`${ip} - - [ ${date} ] "PUT /businesses/:businessId" 400 (Campos obligatorios)`);
      return res.status(400).json({ error: "Campos obligatorios" });
    }

    const business = await Business.findOne({ _id: businessId, owner: userId });
    if (!business) {
      console.log(`${ip} - - [ ${date} ] "PUT /businesses/:businessId" 404 (Negocio no encontrado)`);
      return res.status(404).json({ error: "Negocio no encontrado" });
    }

    if (normalizedName) {
      business.name = normalizedName;
    }

    business.offers = normalizedOffers;
    business.schedule = normalizedSchedule;
    business.scheduleMode = normalizedScheduleMode;
    business.employeeCount = normalizedEmployeeCount;

    await business.save();

    console.log(`${ip} - - [ ${date} ] "PUT /businesses/:businessId" 200`);

    return res.json(business);
  } catch (err) {
    let originalIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    if (originalIp.includes(',')) {
      originalIp = originalIp.split(',')[0].trim();
    }

    const ip = originalIp.includes(':') ? originalIp.split(':').pop() : originalIp;
    const date = formatDate();

    if (err?.name === "CastError") {
      console.log(`${ip} - - [ ${date} ] "PUT /businesses/:businessId" 404 (businessId invalido)`);
      return res.status(400).json({ error: "businessId invalido" });
    }

    console.error(err);
    console.log(`${ip} - - [ ${date} ] "PUT /businesses/:businessId" 500`);
    return res.status(500).json({ error: "Error interno del servidor" });
  }
};

/**
 * Elimina un negocio del usuario autenticado
 * @param string req.user.userId ID del usuario autenticado (del token)
 * @param string req.params.businessId ID del negocio
 * @return json {removed: boolean} Indica si se eliminó el negocio
 */
exports.deleteMyBusiness = async (req, res) => {
  try {
    let originalIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    if (originalIp.includes(',')) {
      originalIp = originalIp.split(',')[0].trim();
    }
  
    const ip = originalIp.includes(':') ? originalIp.split(':').pop() : originalIp;
    const date = formatDate();

    const userId = req.user.userId;
    const businessId = toTrimmedString(req.params.businessId);

    if (!businessId) {
      console.log(`${ip} - - [ ${date} ] "DELETE /businesses/:businessId" 400 (businessId es obligatorio)`);
      return res.status(400).json({ error: "businessId es obligatorio" });
    }

    const deletedBusiness = await Business.findOneAndDelete({ _id: businessId, owner: userId });
    if (!deletedBusiness) {
      console.log(`${ip} - - [ ${date} ] "DELETE /businesses/:businessId" 404 (Negocio no encontrado)`);
      return res.status(404).json({ error: "Negocio no encontrado" });
    }

    const linkedPlaceId = toTrimmedString(deletedBusiness.googlePlace?.placeId);

    const cleanupTasks = [
      User.findByIdAndUpdate(userId, {
        $pull: { businesses: deletedBusiness._id },
      }),
      BusinessCreationRequest.deleteMany({ business: deletedBusiness._id }),
    ];

    if (linkedPlaceId) {
      cleanupTasks.push(Favorite.deleteMany({ businessId: linkedPlaceId }));
    }

    await Promise.all(cleanupTasks);

    console.log(`${ip} - - [ ${date} ] "DELETE /businesses/:businessId" 200`);

    return res.json({ removed: true });
  } catch (err) {
    let originalIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    if (originalIp.includes(',')) {
      originalIp = originalIp.split(',')[0].trim();
    }

    const ip = originalIp.includes(':') ? originalIp.split(':').pop() : originalIp;
    const date = formatDate();
  
    if (err?.name === "CastError") {
      console.log(`${ip} - - [ ${date} ] "DELETE /businesses/:businessId" 404 (businessId invalido)`);
      return res.status(400).json({ error: "businessId invalido" });
    }

    console.error(err);
    console.log(`${ip} - - [ ${date} ] "DELETE /businesses/:businessId" 500`);
    return res.status(500).json({ error: "Error interno del servidor" });
  }
};

/**
 * Obtiene todos los favoritos del usuario autenticado
 * @param string req.user.userId ID del usuario autenticado (del token)
 * @return json [objects] Array con los favoritos del usuario
 */
exports.getMyFavorites = async (req, res) => {
  try {
    let originalIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    if (originalIp.includes(',')) {
      originalIp = originalIp.split(',')[0].trim();
    }

    // Se extrae solo el IPv4
    const ip = originalIp.includes(':') ? originalIp.split(':').pop() : originalIp;
    const date = formatDate();

    const userId = req.user.userId;

    const favorites = await Favorite.find(
      { user: userId },
      { _id: 1, businessId: 1, createdAt: 1 },
    ).sort({ createdAt: -1 });

    console.log(`${ip} - - [ ${date} ] "GET /favorites" 200`);

    return res.json(favorites);
  } catch (err) {
    console.error(err);
    let originalIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    if (originalIp.includes(',')) {
      originalIp = originalIp.split(',')[0].trim();
    }

    const ip = originalIp.includes(':') ? originalIp.split(':').pop() : originalIp;
    const date = formatDate();
    console.log(`${ip} - - [ ${date} ] "GET /favorites" 500`);
    return res.status(500).json({ error: "Error interno del servidor" });
  }
};

/**
 * Crea un favorito para el usuario autenticado
 * @param string req.user.userId ID del usuario autenticado (del token)
 * @param string req.body.businessId Identificador del negocio/local (placeId)
 * @return json {object} Favorito creado o existente
 */
exports.createFavorite = async (req, res) => {
  try {
    let originalIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    if (originalIp.includes(',')) {
      originalIp = originalIp.split(',')[0].trim();
    }

    // Se extrae solo el IPv4
    const ip = originalIp.includes(':') ? originalIp.split(':').pop() : originalIp;
    const date = formatDate();

    const userId = req.user.userId;
    const rawBusinessId = typeof req.body.businessId === "string" ? req.body.businessId : "";
    const businessId = rawBusinessId.trim();


    if (!businessId) {
      console.log(`${ip} - - [ ${date} ] "POST /favorites" 400 (businessId es obligatorio)`);
      return res.status(400).json({ error: "businessId es obligatorio" });
    }

    const existingFavorite = await Favorite.findOne({ user: userId, businessId });
    if (existingFavorite) {
      return res.json(existingFavorite);
    }

    const favorite = await Favorite.create({ user: userId, businessId });

    console.log(`${ip} - - [ ${date} ] "POST /favorites" 201`);

    return res.status(201).json(favorite);
  } catch (err) {
    let originalIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    if (originalIp.includes(',')) {
      originalIp = originalIp.split(',')[0].trim();
    }

    const ip = originalIp.includes(':') ? originalIp.split(':').pop() : originalIp;
    const date = formatDate();

    if (err && err.code === 11000) {
      const existingFavorite = await Favorite.findOne({
        user: req.user.userId,
        businessId: (typeof req.body.businessId === "string" ? req.body.businessId : "").trim(),
      });

      if (existingFavorite) {
        return res.json(existingFavorite);
      }
    }

    console.error(err);
    console.log(`${ip} - - [ ${date} ] "POST /favorites" 500`);
    return res.status(500).json({ error: "Error interno del servidor" });
  }
};

/**
 * Elimina un favorito del usuario autenticado
 * @param string req.user.userId ID del usuario autenticado (del token)
 * @param string req.params.businessId Identificador del negocio/local (placeId)
 * @return json {removed: boolean} Indica si se eliminó el favorito
 */
exports.deleteFavorite = async (req, res) => {
  try {
    let originalIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    if (originalIp.includes(',')) {
      originalIp = originalIp.split(',')[0].trim();
    }

    // Se extrae solo el IPv4
    const ip = originalIp.includes(':') ? originalIp.split(':').pop() : originalIp;
    const date = formatDate();

    const userId = req.user.userId;
    const rawBusinessId = typeof req.params.businessId === "string" ? req.params.businessId : "";
    const businessId = rawBusinessId.trim();

    if (!businessId) {
      console.log(`${ip} - - [ ${date} ] "DELETE /favorites" 400 (businessId es obligatorio)`);
      return res.status(400).json({ error: "businessId es obligatorio" });
    }

    const deleted = await Favorite.findOneAndDelete({ user: userId, businessId });

    console.log(`${ip} - - [ ${date} ] "DELETE /favorites" 200`);

    return res.json({ removed: Boolean(deleted) });
  } catch (err) {
    console.error(err);
    let originalIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    if (originalIp.includes(',')) {
      originalIp = originalIp.split(',')[0].trim();
    }

    const ip = originalIp.includes(':') ? originalIp.split(':').pop() : originalIp;
    const date = formatDate();

    console.log(`${ip} - - [ ${date} ] "DELETE /favorites" 500`);
    return res.status(500).json({ error: "Error interno del servidor" });
  }
};

/**
 * Busca peluquerías/barberías en Google Places para vincular un negocio
 * @param string req.user.userId ID del usuario autenticado (del token)
 * @param string req.query.query Texto de búsqueda
 * @return json {places: object[]} Lista de resultados simplificada
 */
exports.searchGooglePlacesForBusinessLink = async (req, res) => {
  try {
    let originalIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    if (originalIp.includes(',')) {
      originalIp = originalIp.split(',')[0].trim();
    }

    // Se extrae solo el IPv4
    const ip = originalIp.includes(':') ? originalIp.split(':').pop() : originalIp;
    const date = formatDate();

    const rawQuery = typeof req.query.query === "string" ? req.query.query.trim() : "";
    if (rawQuery.length < 2) {
      console.log(`${ip} - - [ ${date} ] "GET /businesses/google-places/search" 400 (La busqueda debe tener al menos 2 caracteres)`);
      return res.status(400).json({ error: "La busqueda debe tener al menos 2 caracteres" });
    }

    const requestedType = typeof req.query.type === "string" ? req.query.type.trim() : "hair_care";
    const placeType = GOOGLE_PLACES_ALLOWED_TYPES.has(requestedType) ? requestedType : "hair_care";
    const apiKey = getGoogleMapsApiKey();

    if (!apiKey) {
      console.log(`${ip} - - [ ${date} ] "GET /businesses/google-places/search" 500 (GOOGLE_MAPS_API_KEY no configurada en backend)`);
      return res.status(500).json({ error: "GOOGLE_MAPS_API_KEY no configurada en backend" });
    }

    const url = new URL(GOOGLE_PLACES_TEXT_SEARCH_URL);
    url.searchParams.set("query", `${rawQuery} peluqueria barberia`);
    url.searchParams.set("type", placeType);
    url.searchParams.set("language", "es");
    url.searchParams.set("key", apiKey);

    const googleResponse = await fetch(url.toString());
    if (!googleResponse.ok) {
      console.log(`${ip} - - [ ${date} ] "GET /businesses/google-places/search" 502 (No se pudo consultar Google Places)`);
      return res.status(502).json({ error: "No se pudo consultar Google Places" });
    }

    const payload = await googleResponse.json();
    const status = payload && typeof payload === "object"
      ? String(payload.status || "UNKNOWN_ERROR")
      : "UNKNOWN_ERROR";

    if (status !== "OK" && status !== "ZERO_RESULTS") {
      return res.status(502).json({
        error: `Google Places retorno estado ${status}`,
      });
    }

    const rawResults = payload && typeof payload === "object" && Array.isArray(payload.results)
      ? payload.results
      : [];

    const places = rawResults
      .map(mapGooglePlacesTextSearchResult)
      .filter(Boolean)
      .slice(0, 10);

    console.log(`${ip} - - [ ${date} ] "GET /businesses/google-places/search" 200`);

    return res.json({ places });
  } catch (err) {
    console.error(err);

    let originalIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    if (originalIp.includes(',')) {
      originalIp = originalIp.split(',')[0].trim();
    }

    const ip = originalIp.includes(':') ? originalIp.split(':').pop() : originalIp;
    const date = formatDate();

    console.log(`${ip} - - [ ${date} ] "GET /businesses/google-places/search" 500`);
    return res.status(500).json({ error: "Error interno del servidor" });
  }
};

/**
 * Devuelve qué placeIds de Google ya están registrados como negocio en la app
 * @param string|array req.query.placeIds Lista CSV o array de placeIds
 * @return json {registered: object[]} Negocios registrados por placeId
 */
exports.getRegisteredBusinessesByPlaceIds = async (req, res) => {
  try {
    let originalIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    if (originalIp.includes(',')) {
      originalIp = originalIp.split(',')[0].trim();
    }

    // Se extrae solo el IPv4
    const ip = originalIp.includes(':') ? originalIp.split(':').pop() : originalIp;
    const date = formatDate();

    const rawQueryPlaceIds = req.query.placeIds;
    const rawPlaceIds = Array.isArray(rawQueryPlaceIds)
      ? rawQueryPlaceIds.join(",")
      : (typeof rawQueryPlaceIds === "string" ? rawQueryPlaceIds : "");

    const normalizedPlaceIds = [...new Set(
      rawPlaceIds
        .split(",")
        .map((value) => value.trim())
        .filter(Boolean),
    )].slice(0, 80);

    if (normalizedPlaceIds.length === 0) {
      return res.json({ registered: [] });
    }

    const businesses = await Business.find(
      { "googlePlace.placeId": { $in: normalizedPlaceIds } },
      { _id: 1, name: 1, googlePlace: 1 },
    ).lean();

    const registered = businesses
      .map((business) => {
        const placeId = business?.googlePlace?.placeId;
        if (typeof placeId !== "string" || !placeId.trim()) {
          return null;
        }

        return {
          businessId: String(business._id),
          placeId: placeId.trim(),
          name: typeof business.name === "string" ? business.name.trim() : "",
        };
      })
      .filter(Boolean);

    console.log(`${ip} - - [ ${date} ] "GET /businesses/registered-by-place-ids" 200`);
    
    return res.json({ registered });
  } catch (err) {
    console.error(err);

    let originalIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    if (originalIp.includes(',')) {
      originalIp = originalIp.split(',')[0].trim();
    }

    const ip = originalIp.includes(':') ? originalIp.split(':').pop() : originalIp;
    const date = formatDate();

    console.log(`${ip} - - [ ${date} ] "GET /businesses/registered-by-place-ids" 500`);
    return res.status(500).json({ error: "Error interno del servidor" });
  }
};

/**
 * Crea un negocio para el usuario autenticado
 * Guarda también un registro de los datos enviados desde el frontend
 * @param string req.user.userId ID del usuario autenticado (del token)
 * @param Object req.body Datos del negocio
 * @return json {object} Negocio creado
 */
exports.createBusiness = async (req, res) => {
  try {
    let originalIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    if (originalIp.includes(',')) {
      originalIp = originalIp.split(',')[0].trim();
    }

    const ip = originalIp.includes(':') ? originalIp.split(':').pop() : originalIp;
    const date = formatDate();
    const userId = req.user.userId;

    const {
      offers,
      schedule,
      scheduleMode,
      employeeCount,
      googlePlace,
    } = req.body;

    const normalizedGooglePlace = normalizeGooglePlacePayload(googlePlace);
    const normalizedOffersWithValidation = Array.isArray(offers)
      ? offers.map(normalizeBusinessOfferPayload)
      : null;
    const normalizedScheduleWithValidation = Array.isArray(schedule)
      ? schedule.map(normalizeBusinessScheduleDayPayload)
      : null;
    const hasInvalidOffer = normalizedOffersWithValidation !== null &&
      normalizedOffersWithValidation.some((offer) => offer === null);
    const hasInvalidSchedule = normalizedScheduleWithValidation !== null &&
      normalizedScheduleWithValidation.some((day) => day === null);
    const normalizedOffers = normalizedOffersWithValidation
      ? normalizedOffersWithValidation.filter(Boolean)
      : null;
    const normalizedSchedule = normalizedScheduleWithValidation
      ? normalizedScheduleWithValidation.filter(Boolean)
      : null;
    const normalizedScheduleMode = normalizeBusinessScheduleMode(scheduleMode);
    const normalizedEmployeeCount = Number(employeeCount);

    if (
      hasInvalidOffer ||
      hasInvalidSchedule ||
      normalizedOffers === null ||
      normalizedOffers.length === 0 ||
      normalizedSchedule === null ||
      normalizedSchedule.length === 0 ||
      !normalizedSchedule.some((day) => day.isOpen) ||
      !Number.isInteger(normalizedEmployeeCount) ||
      normalizedEmployeeCount < 0 ||
      normalizedGooglePlace === null
    ) {
      console.log(`${ip} - - [ ${date} ] "POST /businesses" 400 (Campos obligatorios)`);
      return res.status(400).json({ error: "Campos obligatorios" });
    }

    const existingLinkedBusiness = await Business.findOne({
      owner: userId,
      "googlePlace.placeId": normalizedGooglePlace.placeId,
    });

    if (existingLinkedBusiness) {
      console.log(`${ip} - - [ ${date} ] "POST /businesses" 409 (Ya existe un negocio enlazado con este local de Google Maps)`);
      return res.status(409).json({
        error: "Ya existe un negocio enlazado con este local de Google Maps",
      });
    }

    const business = await Business.create({
      owner: userId,
      name: normalizedGooglePlace.name,
      offers: normalizedOffers,
      schedule: normalizedSchedule,
      scheduleMode: normalizedScheduleMode,
      employeeCount: normalizedEmployeeCount,
      googlePlace: normalizedGooglePlace,
    });

    await User.findByIdAndUpdate(userId, {
      $addToSet: { businesses: business._id },
    });

    res.status(201).json(business);
    console.log(`${ip} - - [ ${date} ] "POST /businesses" 201`);
  } catch (err) {
    console.error(err);

    let originalIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    if (originalIp.includes(',')) {
      originalIp = originalIp.split(',')[0].trim();
    }

    const ip = originalIp.includes(':') ? originalIp.split(':').pop() : originalIp;
    const date = formatDate();

    console.log(`${ip} - - [ ${date} ] "POST /businesses" 500`);
    res.status(500).json({ error: "Error interno del servidor" });
  }
};

/**
 * Guarda los datos generados por la consulta de creación de negocio desde frontend
 * @param string req.user.userId ID del usuario autenticado (del token)
 * @param Object req.body Datos de consulta de creación
 * @return json {object} Registro de creación guardado
 */
exports.createBusinessCreationData = async (req, res) => {
  try {
    let originalIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    if (originalIp.includes(',')) {
      originalIp = originalIp.split(',')[0].trim();
    }

    const ip = originalIp.includes(':') ? originalIp.split(':').pop() : originalIp;
    const date = formatDate();
    const userId = req.user.userId;
    const { businessId, requestPayload, generatedData } = req.body;

    if (!businessId || !requestPayload || !generatedData) {
      console.log(`${ip} - - [ ${date} ] "POST /businesses/creation-data" 400 (Campos obligatorios)`);
      return res.status(400).json({ error: "Campos obligatorios" });
    }

    const existingBusiness = await Business.findOne({ _id: businessId, owner: userId });
    if (!existingBusiness) {
      console.log(`${ip} - - [ ${date} ] "POST /businesses/creation-data" 404 (Negocio no encontrado)`);
      return res.status(404).json({ error: "Negocio no encontrado" });
    }

    const creationData = await BusinessCreationRequest.create({
      user: userId,
      business: businessId,
      source: "frontend",
      requestPayload,
      generatedData,
    });

    res.status(201).json(creationData);
    console.log(`${ip} - - [ ${date} ] "POST /businesses/creation-data" 201`);
  } catch (err) {
    console.error(err);
    
    let originalIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    if (originalIp.includes(',')) {
      originalIp = originalIp.split(',')[0].trim();
    }

    const ip = originalIp.includes(':') ? originalIp.split(':').pop() : originalIp;
    const date = formatDate();

    console.log(`${ip} - - [ ${date} ] "POST /businesses/creation-data" 500`);
    res.status(500).json({ error: "Error interno del servidor" });
  }
};