const Reservation = require("../models/reservation.model");
const Notification = require("../models/notification.model");
const { formatDate } = require('../config/date');

// 🔹 Obtener reservas del usuario logueado
exports.getMyReservations = async (req, res) => {
  try {
    // DATOS DE LOGS
    const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
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

// 🔹 Crear reserva (opcional pero recomendable)
exports.createReservation = async (req, res) => {
  try {
    // DATOS DE LOGS
    const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
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


// 🔹 Obtener notificaciones del usuario
exports.getMyNotifications = async (req, res) => {
  try {
    const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
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

// 🔹 Marcar notificación como leída
exports.markAsRead = async (req, res) => {
  try {
    const userId = req.user.userId;

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