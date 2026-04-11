// Este archivo se encarga de arrancar el Backend

// Se importa la configuración del .env
require("dotenv").config();

// Importa express y conecta con la base de datos
const app = require("./src/app");
const connectDB = require("./src/config/db");

connectDB();

const PORT = process.env.PORT;

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Servidor corriendo en puerto ${PORT}`);
});