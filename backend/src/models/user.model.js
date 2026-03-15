// Crea la estructuras de las clases que se guardan en la base de datos.

const mongoose = require("mongoose");

const userSchema = new mongoose.Schema({
  email: { type: String, unique: true, required: true },
  username: { type: String, required: true },
  password: { type: String, required: true },
  role: { type: Number, required: true }
});

module.exports = mongoose.model("User", userSchema);