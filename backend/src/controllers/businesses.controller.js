const Reservation = require("../models/reservation.model");
const Notification = require("../models/notification.model");
const User = require("../models/user.model");
const Business = require("../models/business.model");
const Favorite = require("../models/favorite.model");
const BusinessCreationRequest = require("../models/business_creation_request.model");
const { formatDate } = require('../config/date');
const {
  GOOGLE_PLACES_TEXT_SEARCH_URL,
  GOOGLE_PLACES_ALLOWED_TYPES,
  BUSINESS_SCHEDULE_MODES,
  WEEKDAY_LABELS,
  getGoogleMapsApiKey,
  mapGooglePlacesTextSearchResult,
  normalizeGooglePlacePayload,
  toTrimmedString,
  parseTimeToMinutes,
  parseDateParts,
  normalizeReservationDate,
  getReservationDayRange,
  formatMinutesToTime,
  resolveScheduleForDate,
  buildSlotsForRange,
  buildSlotTimesForSchedule,
  normalizeBusinessOfferPayload,
  normalizeBusinessScheduleDayPayload,
  normalizeBusinessScheduleMode,
} = require('../config/features');

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

/**
 * Lista negocios registrados con busqueda opcional
 * @param string req.query.q Texto de busqueda
 * @return json {businesses: object[]}
 */
exports.listBusinesses = async (req, res) => {
  try {
    let originalIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    if (originalIp.includes(',')) {
      originalIp = originalIp.split(',')[0].trim();
    }

    const ip = originalIp.includes(':') ? originalIp.split(':').pop() : originalIp;
    const date = formatDate();

    const query = toTrimmedString(req.query.q);
    const filter = query
      ? {
          $or: [
            { name: { $regex: query, $options: "i" } },
            { "googlePlace.name": { $regex: query, $options: "i" } },
            { "googlePlace.address": { $regex: query, $options: "i" } },
          ],
        }
      : {};

    const businesses = await Business.find(filter, {
      name: 1,
      googlePlace: 1,
    })
      .sort({ name: 1 })
      .limit(50)
      .lean();

    const payload = businesses.map((business) => ({
      businessId: String(business._id),
      name: toTrimmedString(business.name),
      placeId: toTrimmedString(business.googlePlace?.placeId),
      address: toTrimmedString(business.googlePlace?.address),
    }));

    console.log(`${ip} - - [ ${date} ] "GET /businesses" 200`);
    return res.json({ businesses: payload });
  } catch (err) {
    console.error(err);
    let originalIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    if (originalIp.includes(',')) {
      originalIp = originalIp.split(',')[0].trim();
    }

    const ip = originalIp.includes(':') ? originalIp.split(':').pop() : originalIp;
    const date = formatDate();
    console.log(`${ip} - - [ ${date} ] "GET /businesses" 500`);
    return res.status(500).json({ error: "Error interno del servidor" });
  }
};

/**
 * Obtiene el detalle de un negocio registrado
 * @param string req.params.businessId ID del negocio
 * @return json {object} Detalle del negocio
 */
exports.getBusinessDetails = async (req, res) => {
  try {
    let originalIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    if (originalIp.includes(',')) {
      originalIp = originalIp.split(',')[0].trim();
    }

    const ip = originalIp.includes(':') ? originalIp.split(':').pop() : originalIp;
    const date = formatDate();

    const businessId = toTrimmedString(req.params.businessId);
    if (!businessId) {
      console.log(`${ip} - - [ ${date} ] "GET /businesses/:businessId" 400 (businessId es obligatorio)`);
      return res.status(400).json({ error: "businessId es obligatorio" });
    }

    const business = await Business.findById(businessId).lean();
    if (!business) {
      console.log(`${ip} - - [ ${date} ] "GET /businesses/:businessId" 404 (Negocio no encontrado)`);
      return res.status(404).json({ error: "Negocio no encontrado" });
    }

    console.log(`${ip} - - [ ${date} ] "GET /businesses/:businessId" 200`);
    return res.json({
      businessId: String(business._id),
      name: toTrimmedString(business.name),
      employeeCount: Number(business.employeeCount) || 0,
      offers: Array.isArray(business.offers) ? business.offers : [],
      schedule: Array.isArray(business.schedule) ? business.schedule : [],
      scheduleMode: toTrimmedString(business.scheduleMode) || "single",
      googlePlace: business.googlePlace || {},
    });
  } catch (err) {
    console.error(err);
    let originalIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    if (originalIp.includes(',')) {
      originalIp = originalIp.split(',')[0].trim();
    }

    const ip = originalIp.includes(':') ? originalIp.split(':').pop() : originalIp;
    const date = formatDate();

    if (err?.name === "CastError") {
      console.log(`${ip} - - [ ${date} ] "GET /businesses/:businessId" 400 (businessId invalido)`);
      return res.status(400).json({ error: "businessId invalido" });
    }

    console.log(`${ip} - - [ ${date} ] "GET /businesses/:businessId" 500`);
    return res.status(500).json({ error: "Error interno del servidor" });
  }
};

/**
 * Obtiene las horas disponibles para un negocio y servicio
 * @param string req.params.businessId ID del negocio
 * @param string req.query.date Fecha (YYYY-MM-DD)
 * @param number req.query.offerIndex Indice del servicio
 */
exports.getBusinessAvailability = async (req, res) => {
  try {
    let originalIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    if (originalIp.includes(',')) {
      originalIp = originalIp.split(',')[0].trim();
    }

    const ip = originalIp.includes(':') ? originalIp.split(':').pop() : originalIp;
    const date = formatDate();

    const businessId = toTrimmedString(req.params.businessId);
    const normalizedDate = normalizeReservationDate(req.query.date);
    const normalizedOfferIndex = Number(req.query.offerIndex);

    if (!businessId || normalizedDate === null || !Number.isInteger(normalizedOfferIndex) || normalizedOfferIndex < 0) {
      console.log(`${ip} - - [ ${date} ] "GET /businesses/:businessId/availability" 400 (Parametros invalidos)`);
      return res.status(400).json({ error: "Parametros invalidos" });
    }

    const business = await Business.findById(businessId).lean();
    if (!business) {
      console.log(`${ip} - - [ ${date} ] "GET /businesses/:businessId/availability" 404 (Negocio no encontrado)`);
      return res.status(404).json({ error: "Negocio no encontrado" });
    }

    const offers = Array.isArray(business.offers) ? business.offers : [];
    const selectedOffer = offers[normalizedOfferIndex];
    if (!selectedOffer) {
      console.log(`${ip} - - [ ${date} ] "GET /businesses/:businessId/availability" 400 (Servicio invalido)`);
      return res.status(400).json({ error: "Servicio invalido" });
    }

    const scheduleDay = resolveScheduleForDate(business.schedule, normalizedDate);
    const slotTimes = buildSlotTimesForSchedule(scheduleDay, selectedOffer.durationMinutes);

    const capacity = Number.isInteger(business.employeeCount) && business.employeeCount >= 0
      ? business.employeeCount + 1
      : 1;

    const { start: dayStart, end: dayEnd } = getReservationDayRange(normalizedDate);
    const existingReservations = await Reservation.find({
      business: business._id,
      date: { $gte: dayStart, $lt: dayEnd },
    }).lean();

    const reservationBlocks = existingReservations.map((reservation) => {
      const start = parseTimeToMinutes(reservation?.time) ?? 0;
      const duration = Number(reservation?.durationMinutes)
        || Number(reservation?.service?.durationMinutes)
        || 60;
      return {
        start,
        end: start + duration,
      };
    });

    const slots = slotTimes.map((startMinutes) => {
      const endMinutes = startMinutes + selectedOffer.durationMinutes;
      const overlappingCount = reservationBlocks.filter((block) => (
        block.start < endMinutes && block.end > startMinutes
      )).length;
      const remaining = Math.max(0, capacity - overlappingCount);

      return {
        time: formatMinutesToTime(startMinutes),
        remaining,
        capacity,
      };
    }).filter((slot) => slot.remaining > 0);

    console.log(`${ip} - - [ ${date} ] "GET /businesses/:businessId/availability" 200`);
    return res.json({
      businessId: String(business._id),
      date: normalizedDate.toISOString().slice(0, 10),
      offer: {
        name: toTrimmedString(selectedOffer.name),
        serviceType: toTrimmedString(selectedOffer.serviceType),
        price: Number(selectedOffer.price),
        durationMinutes: Number(selectedOffer.durationMinutes),
      },
      capacity,
      slots,
    });
  } catch (err) {
    console.error(err);
    let originalIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    if (originalIp.includes(',')) {
      originalIp = originalIp.split(',')[0].trim();
    }

    const ip = originalIp.includes(':') ? originalIp.split(':').pop() : originalIp;
    const date = formatDate();

    if (err?.name === "CastError") {
      console.log(`${ip} - - [ ${date} ] "GET /businesses/:businessId/availability" 400 (businessId invalido)`);
      return res.status(400).json({ error: "businessId invalido" });
    }

    console.log(`${ip} - - [ ${date} ] "GET /businesses/:businessId/availability" 500`);
    return res.status(500).json({ error: "Error interno del servidor" });
  }
};