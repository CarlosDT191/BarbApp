const mongoose = require("mongoose");

const businessOfferSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true,
  },
  price: {
    type: Number,
    required: true,
    min: 0,
  },
}, { _id: false });

const businessDayScheduleSchema = new mongoose.Schema({
  day: {
    type: String,
    required: true,
    trim: true,
  },
  isOpen: {
    type: Boolean,
    required: true,
  },
  openTime: {
    type: String,
    required: true,
  },
  closeTime: {
    type: String,
    required: true,
  },
}, { _id: false });

const businessSchema = new mongoose.Schema({
  owner: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true,
    index: true,
  },
  name: {
    type: String,
    required: true,
    trim: true,
  },
  offers: {
    type: [businessOfferSchema],
    default: [],
  },
  schedule: {
    type: [businessDayScheduleSchema],
    default: [],
  },
  employeeCount: {
    type: Number,
    required: true,
    min: 0,
    default: 0,
  },
}, {
  timestamps: true,
});

module.exports = mongoose.model("Business", businessSchema);
