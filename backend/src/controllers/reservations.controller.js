const Reservation = require("../models/reservation.model");
const Notification = require("../models/notification.model");
const User = require("../models/user.model");
const Business = require("../models/business.model");
const { sendPushToUser } = require("../services/push_notifications");
const { formatDate } = require('../config/date');
const {
  toTrimmedString,
  parseTimeToMinutes,
  normalizeReservationDate,
  getReservationDayRange,
  resolveScheduleForDate,
  buildSlotTimesForSchedule,
} = require('../config/features');

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
    const userRole = Number(req.user.role);
    // No se produce filtrado, se creará otra llamada al endpoint que recoja las citas de un propietario
    const filter = { user: userId, isOwnerAppointment: { $ne: true } };

    const reservations = await Reservation.find(filter)
      .sort({ date: 1, time: 1 });

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
 * Obtiene todas las citas del propietario autenticado
 * Ordena las citas por fecha de forma ascendente
 * @param string req.user.userId ID del usuario autenticado (del token)
 * @return json [objects] Array de objetos de citas del propietario
 */
// 🔹 Obtener citas del propietario logueado
exports.getMyAppointments = async (req, res) => {
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
    const userRole = Number(req.user.role);
    // No se produce filtrado, se creará otra llamada al endpoint que recoja las citas de un propietario
    const filter = { owner: userId };

    const reservations = await Reservation.find(filter)
      .sort({ date: 1, time: 1 });

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
 * @param string req.body.businessId ID del negocio
 * @param number req.body.offerIndex Indice del servicio seleccionado
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

    const { date, time, businessId, offerIndex } = req.body;

    const normalizedBusinessId = toTrimmedString(businessId);
    const normalizedTime = toTrimmedString(time);
    const normalizedDate = normalizeReservationDate(date);
    const normalizedOfferIndex = Number(offerIndex);

    if (
      !normalizedBusinessId ||
      !normalizedTime ||
      normalizedDate === null ||
      !Number.isInteger(normalizedOfferIndex) ||
      normalizedOfferIndex < 0
    ) {
      console.log(`${ip} - - [ ${log_date} ] "POST /reservations" 400 (Campos obligatorios)`);
      return res.status(400).json({ error: "Campos obligatorios" });
    }

    const now = new Date();
    const todayUtc = new Date(Date.UTC(
      now.getUTCFullYear(),
      now.getUTCMonth(),
      now.getUTCDate(),
    ));
    const maxAllowedDate = new Date(Date.UTC(
      todayUtc.getUTCFullYear(),
      todayUtc.getUTCMonth() + 3,
      todayUtc.getUTCDate(),
    ));

    if (normalizedDate >= maxAllowedDate) {
      console.log(`${ip} - - [ ${log_date} ] "POST /reservations" 409 (Fecha fuera del rango permitido)`);
      return res.status(409).json({ error: "Fecha fuera del rango permitido" });
    }

    const timeMinutes = parseTimeToMinutes(normalizedTime);
    if (timeMinutes === null) {
      console.log(`${ip} - - [ ${log_date} ] "POST /reservations" 400 (Hora invalida)`);
      return res.status(400).json({ error: "Hora invalida" });
    }

    const business = await Business.findById(normalizedBusinessId).lean();
    if (!business) {
      console.log(`${ip} - - [ ${log_date} ] "POST /reservations" 404 (Negocio no encontrado)`);
      return res.status(404).json({ error: "Negocio no encontrado" });
    }

    const offers = Array.isArray(business.offers) ? business.offers : [];
    const selectedOffer = offers[normalizedOfferIndex];
    if (!selectedOffer) {
      console.log(`${ip} - - [ ${log_date} ] "POST /reservations" 400 (Servicio invalido)`);
      return res.status(400).json({ error: "Servicio invalido" });
    }

    const scheduleDay = resolveScheduleForDate(business.schedule, normalizedDate);
    const slotTimes = buildSlotTimesForSchedule(scheduleDay, selectedOffer.durationMinutes);

    if (slotTimes.length === 0 || !slotTimes.includes(timeMinutes)) {
      console.log(`${ip} - - [ ${log_date} ] "POST /reservations" 409 (Hora no disponible)`);
      return res.status(409).json({ error: "Hora no disponible" });
    }

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

    const slotEnd = timeMinutes + selectedOffer.durationMinutes;
    const overlappingCount = reservationBlocks.filter((block) => (
      block.start < slotEnd && block.end > timeMinutes
    )).length;

    const capacity = Number.isInteger(business.employeeCount) && business.employeeCount >= 0
      ? business.employeeCount + 1
      : 1;

    if (overlappingCount >= capacity) {
      console.log(`${ip} - - [ ${log_date} ] "POST /reservations" 409 (Cupo no disponible)`);
      return res.status(409).json({ error: "Cupo no disponible" });
    }

    const client = await User.findById(userId, {
      firstname: 1,
      lastname: 1,
      email: 1,
    }).lean();

    const clientName = client
      ? `${toTrimmedString(client.firstname)} ${toTrimmedString(client.lastname)}`.trim()
      : "";

    const serviceSnapshot = {
      name: toTrimmedString(selectedOffer.name),
      serviceType: toTrimmedString(selectedOffer.serviceType),
      price: Number(selectedOffer.price),
      durationMinutes: Number(selectedOffer.durationMinutes),
    };

    const reservation = await Reservation.create({
      user: userId,
      owner: business.owner,
      business: business._id,
      date: normalizedDate,
      time: normalizedTime,
      durationMinutes: serviceSnapshot.durationMinutes,
      local_name: toTrimmedString(business.name),
      service: serviceSnapshot,
      clientName,
      clientEmail: toTrimmedString(client?.email),
      isOwnerAppointment: false,
    });

    const formattedDate = normalizedDate.toLocaleDateString('es-ES', {
      day: 'numeric',
      month: 'long',
      year: 'numeric',
    });

    const businessName = toTrimmedString(business.name);
    const clientLabel = clientName || "Cliente";
    const clientMessage = `Reserva confirmada: Has reservado en ${businessName}, ${serviceSnapshot.name} para el ${formattedDate} a las ${normalizedTime}.`;
    const ownerMessage = `Nueva cita: ${clientLabel} ha reservado ${serviceSnapshot.name} (${businessName}) para el ${formattedDate} a las ${normalizedTime}.`;
    const notifications = [
      {
        user: userId,
        type: "reservation",
        message: clientMessage,
        relatedId: reservation._id,
      },
    ];

    if (String(business.owner) !== String(userId)) {
      notifications.push({
        user: business.owner,
        type: "reservation",
        message: ownerMessage,
        relatedId: reservation._id,
      });
    }

    await Notification.create(notifications);

    if (String(business.owner) !== String(userId)) {
      try {
        await sendPushToUser(business.owner, {
          title: "Nueva reserva",
          body: ownerMessage,
          data: {
            type: "reservation",
            reservationId: reservation._id.toString(),
          },
        });
      } catch (_) {
      }
    }
    
    res.status(201).json(reservation);

    let formated_date = formatDate();
    
    console.log(`${ip} - - [ ${formated_date} ] "POST /reservations" 201`);

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
 * Crea una nueva cita para un negocio del propietario autenticado
 * @param string req.user.userId ID del usuario autenticado (del token)
 * @param Object req.body.date Fecha de la cita (YYYY-MM-DD)
 * @param string req.body.time Hora de la cita (HH:mm)
 * @param string req.body.businessId ID del negocio
 * @param number req.body.offerIndex Indice del servicio seleccionado
 * @param string req.body.clientName Nombre del cliente
 * @return json {object} Objeto con los datos de la cita creada
 */
exports.createAppointment = async (req, res) => {
  try {
    let originalIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    if (originalIp.includes(',')) {
      originalIp = originalIp.split(',')[0].trim();
    }

    const ip = originalIp.includes(':') ? originalIp.split(':').pop() : originalIp;
    const log_date = formatDate();

    const userId = req.user.userId;

    const { date, time, businessId, offerIndex, clientName, clientEmail } = req.body;

    const normalizedBusinessId = toTrimmedString(businessId);
    const normalizedTime = toTrimmedString(time);
    const normalizedDate = normalizeReservationDate(date);
    const normalizedOfferIndex = Number(offerIndex);
    const normalizedClientName = toTrimmedString(clientName);

    if (
      !normalizedBusinessId ||
      !normalizedTime ||
      normalizedDate === null ||
      !Number.isInteger(normalizedOfferIndex) ||
      normalizedOfferIndex < 0 ||
      !normalizedClientName
    ) {
      console.log(`${ip} - - [ ${log_date} ] "POST /appointments" 400 (Campos obligatorios)`);
      return res.status(400).json({ error: "Campos obligatorios" });
    }

    const timeMinutes = parseTimeToMinutes(normalizedTime);
    if (timeMinutes === null) {
      console.log(`${ip} - - [ ${log_date} ] "POST /appointments" 400 (Hora invalida)`);
      return res.status(400).json({ error: "Hora invalida" });
    }

    const business = await Business.findById(normalizedBusinessId).lean();
    if (!business) {
      console.log(`${ip} - - [ ${log_date} ] "POST /appointments" 404 (Negocio no encontrado)`);
      return res.status(404).json({ error: "Negocio no encontrado" });
    }

    if (String(business.owner) !== String(userId)) {
      console.log(`${ip} - - [ ${log_date} ] "POST /appointments" 403 (No autorizado)`);
      return res.status(403).json({ error: "No autorizado" });
    }

    const offers = Array.isArray(business.offers) ? business.offers : [];
    const selectedOffer = offers[normalizedOfferIndex];
    if (!selectedOffer) {
      console.log(`${ip} - - [ ${log_date} ] "POST /appointments" 400 (Servicio invalido)`);
      return res.status(400).json({ error: "Servicio invalido" });
    }

    const scheduleDay = resolveScheduleForDate(business.schedule, normalizedDate);
    const slotTimes = buildSlotTimesForSchedule(scheduleDay, selectedOffer.durationMinutes);

    if (slotTimes.length === 0 || !slotTimes.includes(timeMinutes)) {
      console.log(`${ip} - - [ ${log_date} ] "POST /appointments" 409 (Hora no disponible)`);
      return res.status(409).json({ error: "Hora no disponible" });
    }

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

    const slotEnd = timeMinutes + selectedOffer.durationMinutes;
    const overlappingCount = reservationBlocks.filter((block) => (
      block.start < slotEnd && block.end > timeMinutes
    )).length;

    const capacity = Number.isInteger(business.employeeCount) && business.employeeCount >= 0
      ? business.employeeCount + 1
      : 1;

    if (overlappingCount >= capacity) {
      console.log(`${ip} - - [ ${log_date} ] "POST /appointments" 409 (Cupo no disponible)`);
      return res.status(409).json({ error: "Cupo no disponible" });
    }

    const serviceSnapshot = {
      name: toTrimmedString(selectedOffer.name),
      serviceType: toTrimmedString(selectedOffer.serviceType),
      price: Number(selectedOffer.price),
      durationMinutes: Number(selectedOffer.durationMinutes),
    };

    const reservation = await Reservation.create({
      user: userId,
      owner: business.owner,
      business: business._id,
      date: normalizedDate,
      time: normalizedTime,
      durationMinutes: serviceSnapshot.durationMinutes,
      local_name: toTrimmedString(business.name),
      service: serviceSnapshot,
      clientName: normalizedClientName,
      clientEmail: toTrimmedString(clientEmail),
      isOwnerAppointment: true,
    });

    const formattedDate = normalizedDate.toLocaleDateString('es-ES', {
      day: 'numeric',
      month: 'long',
      year: 'numeric',
    });

    const businessName = toTrimmedString(business.name);
    const username = normalizedClientName;

    const message = `Nueva cita creada para ${username} en ${businessName} el día ${formattedDate} a las ${normalizedTime}`;

    await Notification.create({
      user: userId,
      type: "reservation",
      message,
      relatedId: reservation._id,
    });

    res.status(201).json(reservation);

    const formattedDateLog = formatDate();
    console.log(`${ip} - - [ ${formattedDateLog} ] "POST /appointments" 201`);
  } catch (err) {
    console.error(err);
    let originalIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    if (originalIp.includes(',')) {
      originalIp = originalIp.split(',')[0].trim();
    }

    const ip = originalIp.includes(':') ? originalIp.split(':').pop() : originalIp;
    const log_date = formatDate();
    console.log(`${ip} - - [ ${log_date} ] "POST /appointments" 500`);
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

    const reservation = await Reservation.findOne({
      _id: reservationId,
      $or: [{ user: userId }, { owner: userId }],
    });

    if (!reservation) {
      console.log(`${ip} - - [ ${date} ] "DELETE /reservations/:reservationId" 404 (Reserva no encontrada)`);
      return res.status(404).json({ error: "Reserva no encontrada" });
    }

    const isOwnerCancel = String(reservation.owner) === String(userId);
    const formattedDate = reservation.date.toLocaleDateString('es-ES', {
      day: 'numeric',
      month: 'long',
      year: 'numeric',
    });
    const businessName = toTrimmedString(reservation.local_name) || "el negocio";
    const serviceName = toTrimmedString(reservation?.service?.name);
    const serviceLabel = serviceName ? `${businessName} (${serviceName})` : businessName;
    const timeLabel = toTrimmedString(reservation.time);
    const clientLabel = toTrimmedString(reservation.clientName) || "Cliente";
    const detailsLabel = `${serviceLabel} del ${formattedDate} a las ${timeLabel}`;

    const ownerMessage = isOwnerCancel
      ? `Has cancelado la reserva de ${clientLabel} en ${detailsLabel}`
      : `La reserva de ${clientLabel} en ${detailsLabel} fue cancelada por el cliente.`;
    const clientMessage = isOwnerCancel
      ? `Tu reserva en ${detailsLabel} fue cancelada por el propietario`
      : `Has cancelado tu reserva en ${detailsLabel}.`;

    await reservation.deleteOne();

    const cancelNotifications = [
      {
        user: reservation.user,
        type: "cancel",
        message: clientMessage,
        relatedId: reservation._id,
      },
    ];

    if (String(reservation.owner) !== String(reservation.user)) {
      cancelNotifications.push({
        user: reservation.owner,
        type: "cancel",
        message: ownerMessage,
        relatedId: reservation._id,
      });
    }

    await Notification.create(cancelNotifications);

    const pushTarget = isOwnerCancel ? reservation.user : reservation.owner;
    const pushBody = isOwnerCancel ? clientMessage : ownerMessage;

    if (String(pushTarget) !== String(userId)) {
      try {
        await sendPushToUser(pushTarget, {
          title: "Reserva cancelada",
          body: pushBody,
          data: {
            type: "cancel",
            reservationId: reservation._id.toString(),
          },
        });
      } catch (_) {
      }
    }

    console.log(`${ip} - - [ ${date} ] "DELETE /reservations/:reservationId" 200`);

    return res.json({ removed: true });
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
