
// Importa las llamadas APIs de Node.js y las activa
const express = require("express");
const cors = require("cors");
const authRoutes = require("./routes/auth.routes");
const reservationRoutes = require("./routes/reservation.routes");

const app = express();

app.use(express.json());
app.use(cors());

// Monta los endpoints correspondientes
app.use(authRoutes);
app.use(reservationRoutes);

module.exports = app;