const User = require("../models/user.model");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const { formatDate } = require('../config/date');

// LÓGICA DE REGISTRO DE CUENTAS
exports.register = async (req, res) => {

  try {
    // DATOS DE LOGS
    const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    const date = formatDate();

    const { email, username, password, role } = req.body;

    if (!email || !username || !password || role === undefined) {
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

    const existing_username = await User.findOne({ username });

    if (existing_username) {
      console.log(`${ip} - - [ ${date} ] "POST /auth/register" 400 (Este nombre de usuario ya está en uso)`);
      return res.status(400).json({ error: "Este nombre de usuario ya está en uso" });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const newUser = await User.create({
      email,
      username,
      password: hashedPassword,
      role
    });

    const token = jwt.sign(
      { userId: newUser._id, role: newUser.role },
      process.env.JWT_SECRET
    );

    console.log(`${ip} - - [ ${date} ] "POST /auth/register" 200 (Usuario registrado exitosamente)`);

    res.json({
      message: "Usuario registrado exitosamente",
      token,
      user: {
        email: newUser.email,
        username: newUser.username,
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

    const { username, password } = req.body;

    if (!username || !password) {
      console.log(`${ip} - - [ ${date} ] "POST /auth/login" 400 (Todos los campos son obligatorios)`);
      return res.status(400).json({ error: "Todos los campos son obligatorios" });
    }

    let user = await User.findOne({ username });
    if (!user) {
      user = await User.findOne({ email: username });

      if(!user){
        console.log(`${ip} - - [ ${date} ] "POST /auth/login" 401 (Correo/nombre de usuario o contraseñas incorrectos)`);
        return res.status(401).json({ error: "Correo/nombre de usuario o contraseñas incorrectos" });
      }
    }

    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      console.log(`${ip} - - [ ${date} ] "POST /auth/login" 401 (Correo/nombre de usuario o contraseñas incorrectos)`);
      return res.status(401).json({ error: "Correo/nombre de usuario o contraseñas incorrectos" });
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