// Este archivo consiste en realizar la conexión con la base de datos de MongoDB
const mongoose = require("mongoose");

/**
 * Establece la conexión con la base de datos MongoDB Atlas
 * @param void
 * @return Promise Devuelve una promesa que se resuelve cuando se conecta a la base de datos
 */
const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGOURI);
    console.log("✅ MongoDB Atlas conectado");
  } catch (err) {
    console.error("❌ Error conectando a MongoDB:", err);
    process.exit(1);
  }
};

module.exports = connectDB;