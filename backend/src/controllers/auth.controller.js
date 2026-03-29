const User = require("../models/user.model");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const { formatDate } = require('../config/date');


// COMPROBAR CORREO
exports.email = async (req, res) => {
  try {
    // DATOS DE LOGS
    const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
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

// REGISTRO POR Google
exports.google = async (req, res) => {
  try {
    // DATOS DE LOGS
    const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
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

// LÓGICA DE REGISTRO DE CUENTAS
exports.register = async (req, res) => {

  try {
    // DATOS DE LOGS
    const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
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


// LÓGICA DE LOGINS DE USUARIO
exports.login = async (req, res) => {
  try {
    // DATOS DE LOGS
    const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
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
        username: user.username,
        role: user.role
      }
    });

  } catch (err) {
    console.error(err);
    console.log(`${ip} - - [ ${date} ] "POST /auth/login" 500 (Error interno del servidor)`);
    res.status(500).json({ error: "Error interno del servidor" });
  }
};