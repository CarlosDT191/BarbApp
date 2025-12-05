// server.js
require('dotenv').config();
const express = require("express");
const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");
const cors = require("cors");

const app = express();

// Middleware
app.use(express.json());
app.use(cors());

// ================================
// 🔹 Conexión a MongoDB Atlas
// ================================
const mongoURI = process.env.MONGOURI;

mongoose.connect(mongoURI)
  .then(() => console.log("✅ MongoDB Atlas conectado"))
  .catch(err => console.error("❌ Error conectando a MongoDB:", err));

// ================================
// 🔹 Modelo de Usuario
// ================================
const User = mongoose.model("User", new mongoose.Schema({
  email: { type: String, unique: true, required: true },
  username: { type: String, required: true },
  password: { type: String, required: true },
  role: { type: Number, required: true }, // 0=Admin, 1=Propietario, 2=Cliente
}));

// ================================
// 🔹 Ruta de registro
// ================================
app.post("/auth/register", async (req, res) => {
  try {
    const { email, username, password, role } = req.body;

    // Validar campos obligatorios
    if (!email || !username || !password || role === undefined) {
      return res.status(400).json({ error: "Todos los campos son obligatorios" });
    }

    // Validar rol
    if (![0, 1, 2].includes(role)) {
      return res.status(400).json({ error: "Rol inválido" });
    }

    // Verificar si el correo ya existe
    const existing = await User.findOne({ email });
    if (existing) {
      return res.status(400).json({ error: "Este correo ya está registrado" });
    }

    // Encriptar contraseña
    const hashedPassword = await bcrypt.hash(password, 10);

    // Crear usuario
    const newUser = await User.create({
      email,
      username,
      password: hashedPassword,
      role,
    });

    return res.status(200).json({
      message: "Usuario registrado exitosamente",
      user: { email: newUser.email, username: newUser.username, role: newUser.role },
    });

  } catch (err) {
    console.error("Error en /auth/register:", err);
    return res.status(500).json({ error: "Error interno del servidor" });
  }
});

// ================================
// 🔹 Inicializar servidor
// ================================
const PORT = process.env.PORT;
app.listen(PORT, () => console.log(`Servidor corriendo en puerto ${PORT}`));
