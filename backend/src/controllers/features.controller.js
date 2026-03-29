const Reservation = require("../models/reservation.model");
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

    res.json(reservation);

    console.log(`${ip} - - [ ${date} ] "POST /reservations" 200`);

  } catch (err) {
    console.error(err);
    console.log(`${ip} - - [ ${log_date} ] "POST /reservations" 500 (Error interno del servidor)`);
    res.status(500).json({ error: "Error interno del servidor" });
  }
};