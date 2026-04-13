const User = require("../models/user.model");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const { formatDate } = require('../config/date');


/**
 * Verifica si un correo electrónico ya está registrado en la base de datos
 * Valida el formato del correo y el rol del usuario
 * @param Object req.body.email Correo electrónico a verificar
 * @param int req.body.role Rol del usuario (0=cliente, 1=propietario, 2=admin)
 * @return json {message: string} Indica si el correo está registrado o no
 */
// COMPROBAR CORREO
exports.email = async (req, res) => {
  try {
    // DATOS DE LOGS
    let originalIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    if (originalIp.includes(',')) {
      originalIp = originalIp.split(',')[0].trim();
    }
    
    // Se extrae solo el IPv4
    const ip = originalIp.includes(':') ? originalIp.split(':').pop() : originalIp;
    const date = formatDate();

    const { email, role } = req.body;

    if (!email || role === undefined) {
      console.log(`${ip} - - [ ${date} ] "POST /auth/email" 400 (Todos los campos son obligatorios)`);
      return res.status(400).json({ error: "Todos los campos son obligatorios" });
    }

    if (![0,1,2].includes(role)) {
      console.log(`${ip} - - [ ${date} ] "POST /auth/email" 400 (Rol inválido)`);
      return res.status(400).json({ error: "Rol inválido" });
    }

    const existing_email = await User.findOne({ email });

    if (existing_email) {
      console.log(`${ip} - - [ ${date} ] "POST /auth/email" 400 (Este correo ya está registrado)`);
      return res.status(400).json({ error: "Este correo ya está registrado" });
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

    if (!emailRegex.test(email)) {
      console.log(`${ip} - - [ ${date} ] "POST /auth/email" 400 (Formato de correo electrónico inválido)`);
      return res.status(400).json({ error: "Formato de correo electrónico inválido" });
    }

    console.log(`${ip} - - [ ${date} ] "POST /auth/email" 200 (Intento de registro con email no registrado)`);

    res.json({
      message: "Email no registrado",
    });

  } catch (err) {

    console.error(err);
    console.log(`${ip} - - [ ${date} ] "POST /auth/email" 500 (Error interno del servidor)`);
    res.status(500).json({ error: "Error interno del servidor" });

  }
};

/**
 * Registra un nuevo usuario autenticado con Google
 * Si el email ya existe, agrega el ID de Google a la cuenta existente
 * @param Object req.body.email Correo electrónico del usuario
 * @param string req.body.token Token de Google ID
 * @param string req.body.firstname Nombre del usuario
 * @param string req.body.lastname Apellido del usuario
 * @param int req.body.role Rol del usuario (0=cliente, 1=propietario, 2=admin)
 * @return json {message: string, token: string, user: object} Token JWT y datos del usuario
 */
// REGISTRO POR Google
exports.google = async (req, res) => {
  try {
    // DATOS DE LOGS
    let originalIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    if (originalIp.includes(',')) {
      originalIp = originalIp.split(',')[0].trim();
    }
    
    // Se extrae solo el IPv4
    const ip = originalIp.includes(':') ? originalIp.split(':').pop() : originalIp;
    const date = formatDate();
    let provider= "google";

    const { email, token, firstname, lastname, role } = req.body;

    if (!email || !firstname || !lastname || !token || role === undefined) {
      console.log(`${ip} - - [ ${date} ] "POST /auth/google" 400 (Todos los campos son obligatorios)`);
      return res.status(400).json({ error: "Todos los campos son obligatorios" });
    }

    if (![0,1,2].includes(role)) {
      console.log(`${ip} - - [ ${date} ] "POST /auth/google" 400 (Rol inválido)`);
      return res.status(400).json({ error: "Rol inválido" });
    }

    const existing_email = await User.findOne({ email });

    if (existing_email) {
      // Lo registra con el token de google id si la cuenta ya existe con la otra configuración
      if (!existing_email.google_id) {
        provider= "both";

        // Modifica la fila con el email obtenido
        existing_email.firstname = firstname ?? existing_email.firstname;
        existing_email.lastname = lastname ?? existing_email.lastname;
        existing_email.auth_provider = provider;
        existing_email.google_id = token;

        await existing_email.save();
      }

      // Permitir el inicio de sesión?
      else{
        console.log(`${ip} - - [ ${date} ] "POST /auth/google" 400 (Este correo ya está registrado)`);
        return res.status(400).json({ error: "Este correo ya está registrado" });
      }
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

    if (!emailRegex.test(email)) {
      console.log(`${ip} - - [ ${date} ] "POST /auth/google" 400 (Formato de correo electrónico inválido)`);
      return res.status(400).json({ error: "Formato de correo electrónico inválido" });
    }

    const newUser = await User.create({
      email,
      firstname,
      lastname,
      auth_provider: provider,
      google_id: token,
      role
    });

    const session_token = jwt.sign(
      { userId: newUser._id, role: newUser.role },
      process.env.JWT_SECRET
    );

    console.log(`${ip} - - [ ${date} ] "POST /auth/register" 200 (Usuario registrado exitosamente)`);

    // Devuelve estos campos en el JSON de respuesta
    res.json({
      message: "Usuario registrado exitosamente",
      token: session_token,
      user: {
        email: newUser.email,
        firstname: newUser.firstname,
        lastname: newUser.lastname,
        role: newUser.role
      }
    });

  } catch (err) {

    console.error(err);
    console.log(`${ip} - - [ ${date} ] "POST /auth/register" 500 (Error interno del servidor)`);
    res.status(500).json({ error: "Error interno del servidor" });

  }
};

/**
 * Registra un nuevo usuario con correo y contraseña en la plataforma
 * Valida que el correo no exista y cumple con el formato requerido
 * @param Object req.body.email Correo electrónico del usuario
 * @param string req.body.firstname Nombre del usuario
 * @param string req.body.lastname Apellido del usuario
 * @param string req.body.password Contraseña en texto plano (será hasheada)
 * @param int req.body.role Rol del usuario (0=cliente, 1=propietario, 2=admin)
 * @return json {message: string, token: string, user: object} Token JWT y datos del usuario registrado
 */
// LÓGICA DE REGISTRO DE CUENTAS
exports.register = async (req, res) => {

  try {
    // DATOS DE LOGS
    let originalIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    if (originalIp.includes(',')) {
      originalIp = originalIp.split(',')[0].trim();
    }
    
    // Se extrae solo el IPv4
    const ip = originalIp.includes(':') ? originalIp.split(':').pop() : originalIp;
    const date = formatDate();

    const { email, firstname, lastname, password, role } = req.body;

    if (!email || !firstname || !lastname || !password || role === undefined) {
      console.log(`${ip} - - [ ${date} ] "POST /auth/register" 400 (Todos los campos son obligatorios)`);
      return res.status(400).json({ error: "Todos los campos son obligatorios" });
    }

    if (![0,1,2].includes(role)) {
      console.log(`${ip} - - [ ${date} ] "POST /auth/register" 400 (Rol inválido)`);
      return res.status(400).json({ error: "Rol inválido" });
    }

    const existing_email = await User.findOne({ email });

    if (existing_email) {
      console.log(`${ip} - - [ ${date} ] "POST /auth/register" 400 (Este correo ya está registrado)`);
      return res.status(400).json({ error: "Este correo ya está registrado" });
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

    if (!emailRegex.test(email)) {
      console.log(`${ip} - - [ ${date} ] "POST /auth/register" 400 (Formato de correo electrónico inválido)`);
      return res.status(400).json({ error: "Formato de correo electrónico inválido" });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const newUser = await User.create({
      email,
      firstname,
      lastname,
      auth_provider: "barbapp",
      password: hashedPassword,
      role
    });

    const token = jwt.sign(
      { userId: newUser._id, role: newUser.role },
      process.env.JWT_SECRET
    );

    console.log(`${ip} - - [ ${date} ] "POST /auth/register" 200 (Usuario registrado exitosamente)`);

    // Devuelve estos campos en el JSON de respuesta
    res.json({
      message: "Usuario registrado exitosamente",
      token,
      user: {
        email: newUser.email,
        firstname: newUser.firstname,
        lastname: newUser.lastname,
        role: newUser.role
      }
    });

  } catch (err) {

    console.error(err);
    console.log(`${ip} - - [ ${date} ] "POST /auth/register" 500 (Error interno del servidor)`);
    res.status(500).json({ error: "Error interno del servidor" });

  }

};


/**
 * Autentica a un usuario con correo y contraseña
 * Valida las credenciales contra la base de datos y genera un token JWT
 * @param Object req.body.email Correo electrónico del usuario
 * @param string req.body.password Contraseña del usuario
 * @return json {message: string, token: string, user: object} Token JWT y datos del usuario autenticado
 */
// LÓGICA DE LOGINS DE USUARIO
exports.login = async (req, res) => {
  try {
    // DATOS DE LOGS
    let originalIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    if (originalIp.includes(',')) {
      originalIp = originalIp.split(',')[0].trim();
    }
    
    // Se extrae solo el IPv4
    const ip = originalIp.includes(':') ? originalIp.split(':').pop() : originalIp;
    const date = formatDate();

    const { email, password } = req.body;

    if (!email || !password) {
      console.log(`${ip} - - [ ${date} ] "POST /auth/login" 400 (Todos los campos son obligatorios)`);
      return res.status(400).json({ error: "Todos los campos son obligatorios" });
    }

    let user = await User.findOne({ email });
    if (!user) {
      console.log(`${ip} - - [ ${date} ] "POST /auth/login" 401 (Correo electrónico o contraseñas incorrectos)`);
      return res.status(401).json({ error: "Correo electrónico o contraseñas incorrectos" });
    }

    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      console.log(`${ip} - - [ ${date} ] "POST /auth/login" 401 (Correo electrónico o contraseñas incorrectos)`);
      return res.status(401).json({ error: "Correo electrónico o contraseñas incorrectos" });
    }

    const token = jwt.sign(
      { userId: user._id, role: user.role },
      process.env.JWT_SECRET
    );

    console.log(`${ip} - - [ ${date} ] "POST /auth/login" 200 (Inicio de sesión exitoso)`);

    res.json({
      message: "Inicio de sesión exitoso",
      token,
      user: {
        email: user.email,
        firstname: user.firstname,
        lastname: user.lastname,
        role: user.role
      }
    });

  } catch (err) {
    console.error(err);
    console.log(`${ip} - - [ ${date} ] "POST /auth/login" 500 (Error interno del servidor)`);
    res.status(500).json({ error: "Error interno del servidor" });
  }
};

/**
 * Actualiza el nombre y/o apellido del usuario autenticado
 * Requiere token JWT válido para identificar al usuario
 * @param Object req.body.firstname Nuevo nombre del usuario (opcional)
 * @param string req.body.lastname Nuevo apellido del usuario (opcional)
 * @param string req.user.userId ID del usuario autenticado (del token)
 * @return json {message: string, user: object} Mensaje de éxito y datos del usuario actualizado
 */
// ACTUALIZAR PERFIL DE USUARIO
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

    console.log(`${ip} - - [ ${date} ] "PUT /users/profile" 200 (Perfil actualizado exitosamente)`);

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
    console.log(`${ip} - - [ ${date} ] "PUT /users/profile" 500 (Error interno del servidor)`);
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
// CAMBIAR CONTRASEÑA
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

    console.log(`${ip} - - [ ${date} ] "PATCH /users/password" 200 (Contraseña actualizada exitosamente)`);

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
    console.log(`${ip} - - [ ${date} ] "PATCH /users/password" 500 (Error interno del servidor)`);
    res.status(500).json({ error: "Error interno del servidor" });
  }
};

/**
 * Elimina permanentemente la cuenta del usuario autenticado
 * Requiere token JWT válido y elimina todos los datos asociados del usuario
 * @param string req.user.userId ID del usuario autenticado (del token)
 * @return json {message: string} Mensaje confirmando la eliminación de la cuenta
 */
// ELIMINAR PERFIL DE USUARIO
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

    console.log(`${ip} - - [ ${date} ] "DELETE /users/profile" 200 (Usuario eliminado exitosamente)`);

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

    console.log(`${ip} - - [ ${date} ] "DELETE /users/profile" 500 (Error interno del servidor)`);

    res.status(500).json({ error: "Error interno del servidor" });
  }
};