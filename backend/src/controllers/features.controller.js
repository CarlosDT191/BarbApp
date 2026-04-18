const Reservation = require("../models/reservation.model");
const Notification = require("../models/notification.model");
const User = require("../models/user.model");
const Business = require("../models/business.model");
const BusinessCreationRequest = require("../models/business_creation_request.model");
const { formatDate } = require('../config/date');

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

    console.log(`${ip} - - [ ${date} ] "POST /reservations/me" 200`);

  } catch (err) {
    console.error(err);
    console.log(`${ip} - - [ ${date} ] "POST /reservations/me" 500 (Error interno del servidor)`);
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
      return res.status(400).json({ error: "Campos obligatorios" });
    }

    const reservation = await Reservation.create({
      user: userId,
      date,
      time,
      local_name
    });

    
    // CREAR NOTIFICACIÓN
    await Notification.create({
      user: userId,
      type: "reservation",
      message: `Reserva confirmada en ${local_name} el ${date} a las ${time}`,
      relatedId: reservation._id
    });
    
    res.json(reservation);
    
    console.log(`${ip} - - [ ${date} ] "POST /reservations" 200`);

  } catch (err) {
    console.error(err);
    console.log(`${ip} - - [ ${log_date} ] "POST /reservations" 500 (Error interno del servidor)`);
    res.status(500).json({ error: "Error interno del servidor" });
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

    await Notification.findOneAndUpdate(
      { _id: req.params.id, user: userId },
      { read: true }
    );

    res.json({ message: "Notificación marcada como leída" });

    console.log(`${ip} - - [ ${date} ] "PATCH /notifications/:id/read" 200`);

  } catch (err) {
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
    res.status(500).json({ error: "Error interno del servidor" });
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

    const { name, offers, schedule, employeeCount } = req.body;

    if (!name || !Array.isArray(offers) || !Array.isArray(schedule) || employeeCount === undefined) {
      return res.status(400).json({ error: "Campos obligatorios" });
    }

    const business = await Business.create({
      owner: userId,
      name,
      offers,
      schedule,
      employeeCount,
    });

    await User.findByIdAndUpdate(userId, {
      $addToSet: { businesses: business._id },
    });

    res.status(201).json(business);
    console.log(`${ip} - - [ ${date} ] "POST /businesses" 201`);
  } catch (err) {
    console.error(err);
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
      return res.status(400).json({ error: "Campos obligatorios" });
    }

    const existingBusiness = await Business.findOne({ _id: businessId, owner: userId });
    if (!existingBusiness) {
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
    res.status(500).json({ error: "Error interno del servidor" });
  }
};