const mongoose = require("mongoose");

const reservationSchema = new mongoose.Schema({
  user: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: "User", 
    required: true 
  },

  date: { 
    type: Date, 
    required: true 
  },

  time: { 
    type: String, 
    required: true 
  },

  local_name: { 
    type: String, 
    required: true 
  }

}, {
  timestamps: true
});

module.exports = mongoose.model("Reservation", reservationSchema);