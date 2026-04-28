const User = require("../models/user.model");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const { formatDate } = require('../config/date');


/**
 * Obtiene los datos completos del usuario autenticado
 * Excluye la contraseña de los datos retornados
 * @param string req.user.userId ID del usuario autenticado (del token)
 * @return json {object} Objeto con todos los datos del usuario (sin contraseña)
 */
exports.obtainData = async (req, res) => {
  // DATOS DE LOGS
  let originalIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
  if (originalIp.includes(',')) {
    originalIp = originalIp.split(',')[0].trim();
  }
  
  // Se extrae solo el IPv4
  const ip = originalIp.includes(':') ? originalIp.split(':').pop() : originalIp;
  const date = formatDate();

  // Obtiene usuario de la base de datos
  const user = await User.findById(req.user.userId).select("-password");

  console.log(`${ip} - - [ ${date} ] "GET /users/me" 200 `);

  res.json(user);

};

/**
 * Actualiza el nombre y/o apellido del usuario autenticado
 * Requiere token JWT válido para identificar al usuario
 * @param Object req.body.firstname Nuevo nombre del usuario (opcional)
 * @param string req.body.lastname Nuevo apellido del usuario (opcional)
 * @param string req.user.userId ID del usuario autenticado (del token)
 * @return json {message: string, user: object} Mensaje de éxito y datos del usuario actualizado
 */
exports.updateProfile = async (req, res) => {
  try {
    let originalIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    if (originalIp.includes(',')) {
      originalIp = originalIp.split(',')[0].trim();
    }
    
    // Se extrae solo el IPv4
    const ip = originalIp.includes(':') ? originalIp.split(':').pop() : originalIp;
    const date = formatDate();

    const { firstname, lastname } = req.body;
    const userId = req.user.userId;

    if (!firstname && !lastname) {
      console.log(`${ip} - - [ ${date} ] "PUT /users/profile" 400 (Debe proporcionar al menos un campo)`);
      return res.status(400).json({ error: "Debe proporcionar al menos nombre o apellido para actualizar" });
    }

    const user = await User.findByIdAndUpdate(
      userId,
      {
        ...(firstname && { firstname }),
        ...(lastname && { lastname })
      },
      { new: true }
    ).select("-password");

    if (!user) {
      console.log(`${ip} - - [ ${date} ] "PUT /users/profile" 404 (Usuario no encontrado)`);
      return res.status(404).json({ error: "Usuario no encontrado" });
    }

    console.log(`${ip} - - [ ${date} ] "PUT /users/profile" 200`);

    res.json({
      message: "Perfil actualizado exitosamente",
      user
    });

  } catch (err) {
    console.error(err);
    let originalIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    if (originalIp.includes(',')) {
      originalIp = originalIp.split(',')[0].trim();
    }
    
    // Se extrae solo el IPv4
    const ip = originalIp.includes(':') ? originalIp.split(':').pop() : originalIp;
    const date = formatDate();
    console.log(`${ip} - - [ ${date} ] "PUT /users/profile" 500`);
    res.status(500).json({ error: "Error interno del servidor" });
  }
};

/**
 * Cambia la contraseña del usuario autenticado
 * Valida la contraseña actual y requiere que las nuevas contraseñas coincidan
 * No permite cambiar contraseña en cuentas autenticadas solo por Google
 * @param string req.body.currentPassword Contraseña actual del usuario
 * @param string req.body.newPassword Nueva contraseña deseada
 * @param string req.body.confirmPassword Confirmación de la nueva contraseña
 * @param string req.user.userId ID del usuario autenticado (del token)
 * @return json {message: string} Mensaje confirmando el cambio de contraseña
 */
exports.changePassword = async (req, res) => {
  try {
    let originalIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    if (originalIp.includes(',')) {
      originalIp = originalIp.split(',')[0].trim();
    }
    
    // Se extrae solo el IPv4
    const ip = originalIp.includes(':') ? originalIp.split(':').pop() : originalIp;
    const date = formatDate();

    const { currentPassword, newPassword, confirmPassword } = req.body;
    const userId = req.user.userId;

    if (!currentPassword || !newPassword || !confirmPassword) {
      console.log(`${ip} - - [ ${date} ] "PATCH /users/password" 400 (Todos los campos son obligatorios)`);
      return res.status(400).json({ error: "Todos los campos son obligatorios" });
    }

    if (newPassword !== confirmPassword) {
      console.log(`${ip} - - [ ${date} ] "PATCH /users/password" 400 (Las contraseñas no coinciden)`);
      return res.status(400).json({ error: "Las contraseñas nuevas no coinciden" });
    }

    const user = await User.findById(userId);

    if (!user) {
      console.log(`${ip} - - [ ${date} ] "PATCH /users/password" 404 (Usuario no encontrado)`);
      return res.status(404).json({ error: "Usuario no encontrado" });
    }

    // Los usuarios de Google no pueden cambiar contraseña por este método
    if (!user.password) {
      console.log(`${ip} - - [ ${date} ] "PATCH /users/password" 403 (Usuario autenticado por Google)`);
      return res.status(403).json({ error: "No puedes cambiar contraseña. Tu cuenta está autenticada por Google" });
    }

    const isPasswordValid = await bcrypt.compare(currentPassword, user.password);

    if (!isPasswordValid) {
      console.log(`${ip} - - [ ${date} ] "PATCH /users/password" 401 (Contraseña actual incorrecta)`);
      return res.status(401).json({ error: "La contraseña actual es incorrecta" });
    }

    const isPasswordSame = await bcrypt.compare(newPassword, user.password);

    if (isPasswordSame) {
      console.log(`${ip} - - [ ${date} ] "PATCH /users/password" 400 (La nueva contraseña es la misma que la actual)`);
      return res.status(400).json({ error: "La nueva contraseña no puede ser la misma que la actual" });
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);
    user.password = hashedPassword;
    await user.save();

    console.log(`${ip} - - [ ${date} ] "PATCH /users/password" 200`);

    res.json({
      message: "Contraseña actualizada exitosamente"
    });

  } catch (err) {
    console.error(err);
    let originalIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    if (originalIp.includes(',')) {
      originalIp = originalIp.split(',')[0].trim();
    }
    
    // Se extrae solo el IPv4
    const ip = originalIp.includes(':') ? originalIp.split(':').pop() : originalIp;
    const date = formatDate();
    console.log(`${ip} - - [ ${date} ] "PATCH /users/password" 500`);
    res.status(500).json({ error: "Error interno del servidor" });
  }
};

/**
 * Elimina permanentemente la cuenta del usuario autenticado
 * Requiere token JWT válido y elimina todos los datos asociados del usuario
 * @param string req.user.userId ID del usuario autenticado (del token)
 * @return json {message: string} Mensaje confirmando la eliminación de la cuenta
 */
exports.deleteProfile = async (req, res) => {
  try {
    let originalIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;

    if (originalIp.includes(',')) {
      originalIp = originalIp.split(',')[0].trim();
    }

    const ip = originalIp.includes(':')
      ? originalIp.split(':').pop()
      : originalIp;

    const date = formatDate();

    const userId = req.user.userId;

    const user = await User.findByIdAndDelete(userId);

    if (!user) {
      console.log(`${ip} - - [ ${date} ] "DELETE /users/profile" 404 (Usuario no encontrado)`);
      return res.status(404).json({ error: "Usuario no encontrado" });
    }

    console.log(`${ip} - - [ ${date} ] "DELETE /users/profile" 200`);

    res.json({
      message: "Usuario eliminado exitosamente"
    });

  } catch (err) {
    console.error(err);

    let originalIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;

    if (originalIp.includes(',')) {
      originalIp = originalIp.split(',')[0].trim();
    }

    const ip = originalIp.includes(':')
      ? originalIp.split(':').pop()
      : originalIp;

    const date = formatDate();

    console.log(`${ip} - - [ ${date} ] "DELETE /users/profile" 500`);

    res.status(500).json({ error: "Error interno del servidor" });
  }
};