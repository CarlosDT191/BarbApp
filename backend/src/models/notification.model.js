const mongoose = require("mongoose");

const notificationSchema = new mongoose.Schema({
  user: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: "User", 
    required: true 
  },

  type: { 
    type: String, 
    enum: ["reservation", "cancel", "reminder", "system"], 
    required: true 
  },

  message: { 
    type: String, 
    required: true 
  },

  read: { 
    type: Boolean, 
    default: false 
  },

  // opcional: referencia a otra entidad (ej: reserva)
  relatedId: { 
    type: mongoose.Schema.Types.ObjectId, 
    required: false 
  }

}, {
  timestamps: true // crea createdAt y updatedAt automáticamente
});

module.exports = mongoose.model("Notification", notificationSchema);