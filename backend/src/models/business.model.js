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
  durationMinutes: {
    type: Number,
    required: true,
    min: 1,
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
  isSplitShift: {
    type: Boolean,
    required: true,
    default: false,
  },
  secondOpenTime: {
    type: String,
    default: "",
  },
  secondCloseTime: {
    type: String,
    default: "",
  },
}, { _id: false });

const businessGooglePlaceSchema = new mongoose.Schema({
  placeId: {
    type: String,
    required: true,
    trim: true,
  },
  name: {
    type: String,
    required: true,
    trim: true,
  },
  address: {
    type: String,
    required: true,
    trim: true,
  },
  location: {
    lat: {
      type: Number,
      required: true,
    },
    lng: {
      type: Number,
      required: true,
    },
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
  scheduleMode: {
    type: String,
    enum: ["single", "by_day"],
    default: "single",
  },
  employeeCount: {
    type: Number,
    required: true,
    min: 0,
    default: 0,
  },
  googlePlace: {
    type: businessGooglePlaceSchema,
    required: true,
  },
}, {
  timestamps: true,
});

businessSchema.index(
  { owner: 1, "googlePlace.placeId": 1 },
  {
    unique: true,
    partialFilterExpression: {
      "googlePlace.placeId": { $exists: true, $type: "string" },
    },
  },
);

module.exports = mongoose.model("Business", businessSchema);
