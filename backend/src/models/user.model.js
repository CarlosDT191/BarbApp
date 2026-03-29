// Crea la estructuras de las clases que se guardan en la base de datos.

const mongoose = require("mongoose");

const userSchema = new mongoose.Schema({
  email: { type: String, unique: true, required: true },
  firstname: { type: String, required: true },
  lastname: { type: String, required: true },
  auth_provider: { type: String, required: true },
  google_id: { type: String, required: false, default: null },
  password: { type: String, required: false, default: null },
  role: { type: Number, required: true }
});

module.exports = mongoose.model("User", userSchema);