const mongoose = require("mongoose");

const reservationSchema = new mongoose.Schema({
  user: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: "User", 
    required: true 
  },

  owner: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true,
    index: true,
  },

  business: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Business",
    required: true,
    index: true,
  },

  date: { 
    type: Date, 
    required: true 
  },

  time: { 
    type: String, 
    required: true 
  },

  durationMinutes: {
    type: Number,
    required: true,
    min: 1,
  },

  local_name: { 
    type: String, 
    required: true 
  },

  service: {
    name: {
      type: String,
      required: true,
      trim: true,
    },
    serviceType: {
      type: String,
      required: true,
      trim: true,
    },
    price: {
      type: Number,
      required: true,
      min: 0,
    },
    durationMinutes: {
      type: Number,
      required: true,
      min: 1,
    },
  },

  clientName: {
    type: String,
    trim: true,
    default: "",
  },

  clientEmail: {
    type: String,
    trim: true,
    default: "",
  },

}, {
  timestamps: true
});

module.exports = mongoose.model("Reservation", reservationSchema);