const User = require("../models/user.model");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");

// LÓGICA DE REGISTRO DE CUENTAS
exports.register = async (req, res) => {

  try {

    const { email, username, password, role } = req.body;

    if (!email || !username || !password || role === undefined) {
      return res.status(400).json({ error: "Todos los campos son obligatorios" });
    }

    if (![0,1,2].includes(role)) {
      return res.status(400).json({ error: "Rol inválido" });
    }

    const existing_email = await User.findOne({ email });

    if (existing_email) {
      return res.status(400).json({ error: "Este correo ya está registrado" });
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

    if (!emailRegex.test(email)) {
      return res.status(400).json({ error: "Formato de correo electrónico inválido" });
    }

    const existing_username = await User.findOne({ username });

    if (existing_username) {
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

    res.status(500).json({ error: "Error interno del servidor" });

  }

};


// LÓGICA DE LOGINS DE USUARIO
exports.login = async (req, res) => {
  try {
    const { username, password } = req.body;

    if (!username || !password) {
      return res.status(400).json({ error: "Todos los campos son obligatorios" });
    }

    let user = await User.findOne({ username });
    if (!user) {
      user = await User.findOne({ email: username });

      if(!user){
        return res.status(401).json({ error: "Correo/nombre de usuario o contraseñas incorrectos" });
      }
    }

    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({ error: "Correo/nombre de usuario o contraseñas incorrectos" });
    }

    const token = jwt.sign(
      { userId: user._id, role: user.role },
      process.env.JWT_SECRET
    );

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
    res.status(500).json({ error: "Error interno del servidor" });
  }
};