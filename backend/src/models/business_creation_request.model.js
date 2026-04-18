const mongoose = require("mongoose");

const businessCreationRequestSchema = new mongoose.Schema({
  user: {
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
  source: {
    type: String,
    required: true,
    default: "frontend",
  },
  requestPayload: {
    type: mongoose.Schema.Types.Mixed,
    required: true,
    default: {},
  },
  generatedData: {
    type: mongoose.Schema.Types.Mixed,
    required: true,
    default: {},
  },
}, {
  timestamps: true,
});

module.exports = mongoose.model("BusinessCreationRequest", businessCreationRequestSchema);
