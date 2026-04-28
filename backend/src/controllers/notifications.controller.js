const Notification = require("../models/notification.model");
const { formatDate } = require('../config/date');


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
    res.status(200).json({ message: "Marcado como leído" });

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