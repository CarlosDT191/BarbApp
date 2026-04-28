const Favorite = require("../models/favorite.model");
const { formatDate } = require('../config/date');

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