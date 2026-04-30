const GOOGLE_PLACES_TEXT_SEARCH_URL = "https://maps.googleapis.com/maps/api/place/textsearch/json";
const GOOGLE_PLACES_ALLOWED_TYPES = new Set(["hair_care", "barber_shop"]);

const getGoogleMapsApiKey = () => (
  process.env.GOOGLE_MAPS_API_KEY ||
  process.env.google_maps_api_key ||
  ""
).trim();

const mapGooglePlacesTextSearchResult = (rawResult) => {
  if (!rawResult || typeof rawResult !== "object") {
    return null;
  }

  const placeId = typeof rawResult.place_id === "string" ? rawResult.place_id.trim() : "";
  const name = typeof rawResult.name === "string" ? rawResult.name.trim() : "";
  const addressCandidate = typeof rawResult.formatted_address === "string"
    ? rawResult.formatted_address
    : rawResult.vicinity;
  const address = typeof addressCandidate === "string" ? addressCandidate.trim() : "";

  const geometry = rawResult.geometry;
  const location = geometry && typeof geometry === "object" ? geometry.location : null;
  const lat = Number(location && typeof location === "object" ? location.lat : NaN);
  const lng = Number(location && typeof location === "object" ? location.lng : NaN);

  if (!placeId || !name || !address || !Number.isFinite(lat) || !Number.isFinite(lng)) {
    return null;
  }

  return {
    placeId,
    name,
    address,
    location: {
      lat,
      lng,
    },
  };
};

const normalizeGooglePlacePayload = (rawGooglePlace) => {
  if (!rawGooglePlace || typeof rawGooglePlace !== "object") {
    return null;
  }

  const placeId = typeof rawGooglePlace.placeId === "string" ? rawGooglePlace.placeId.trim() : "";
  const name = typeof rawGooglePlace.name === "string" ? rawGooglePlace.name.trim() : "";
  const address = typeof rawGooglePlace.address === "string" ? rawGooglePlace.address.trim() : "";

  const rawLocation = rawGooglePlace.location;
  const lat = Number(rawLocation && typeof rawLocation === "object" ? rawLocation.lat : NaN);
  const lng = Number(rawLocation && typeof rawLocation === "object" ? rawLocation.lng : NaN);

  if (!placeId || !name || !address || !Number.isFinite(lat) || !Number.isFinite(lng)) {
    return null;
  }

  return {
    placeId,
    name,
    address,
    location: {
      lat,
      lng,
    },
  };
};

const BUSINESS_SCHEDULE_MODES = new Set(["single", "by_day"]);

const toTrimmedString = (value) => (typeof value === "string" ? value.trim() : "");

const parseTimeToMinutes = (rawTime) => {
  const time = toTrimmedString(rawTime);
  if (!/^\d{2}:\d{2}$/.test(time)) {
    return null;
  }

  const [hourRaw, minuteRaw] = time.split(":");
  const hour = Number(hourRaw);
  const minute = Number(minuteRaw);

  if (
    !Number.isInteger(hour) ||
    !Number.isInteger(minute) ||
    hour < 0 ||
    hour > 23 ||
    minute < 0 ||
    minute > 59
  ) {
    return null;
  }

  return (hour * 60) + minute;
};

const WEEKDAY_LABELS = [
  "Domingo",
  "Lunes",
  "Martes",
  "Miercoles",
  "Jueves",
  "Viernes",
  "Sabado",
];

const parseDateParts = (rawDate) => {
  const raw = toTrimmedString(rawDate);
  if (!raw) {
    return null;
  }

  if (/^\d{4}-\d{2}-\d{2}$/.test(raw)) {
    const [yearRaw, monthRaw, dayRaw] = raw.split("-");
    const year = Number(yearRaw);
    const month = Number(monthRaw);
    const day = Number(dayRaw);

    if (!Number.isInteger(year) || !Number.isInteger(month) || !Number.isInteger(day)) {
      return null;
    }

    return { year, month, day };
  }

  const parsed = new Date(raw);
  if (Number.isNaN(parsed.getTime())) {
    return null;
  }

  return {
    year: parsed.getUTCFullYear(),
    month: parsed.getUTCMonth() + 1,
    day: parsed.getUTCDate(),
  };
};

const normalizeReservationDate = (rawDate) => {
  const parts = parseDateParts(rawDate);
  if (!parts) {
    return null;
  }

  return new Date(Date.UTC(parts.year, parts.month - 1, parts.day));
};

const getReservationDayRange = (normalizedDate) => {
  const start = new Date(Date.UTC(
    normalizedDate.getUTCFullYear(),
    normalizedDate.getUTCMonth(),
    normalizedDate.getUTCDate(),
  ));
  const end = new Date(Date.UTC(
    normalizedDate.getUTCFullYear(),
    normalizedDate.getUTCMonth(),
    normalizedDate.getUTCDate() + 1,
  ));

  return { start, end };
};

const formatMinutesToTime = (minutes) => {
  const clamped = Number(minutes);
  if (!Number.isFinite(clamped) || clamped < 0) {
    return "00:00";
  }

  const normalized = clamped % (24 * 60);
  const hours = Math.floor(normalized / 60);
  const mins = normalized % 60;
  return `${String(hours).padStart(2, "0")}:${String(mins).padStart(2, "0")}`;
};

const resolveScheduleForDate = (schedule, normalizedDate) => {
  if (!Array.isArray(schedule)) {
    return null;
  }

  const dayLabel = WEEKDAY_LABELS[normalizedDate.getUTCDay()];
  if (!dayLabel) {
    return null;
  }

  const target = dayLabel.toLowerCase();
  return schedule.find((day) => toTrimmedString(day?.day).toLowerCase() === target) || null;
};

const buildSlotsForRange = (startMinutes, endMinutes, durationMinutes) => {
  if (!Number.isInteger(startMinutes) || !Number.isInteger(endMinutes)) {
    return [];
  }

  if (!Number.isInteger(durationMinutes) || durationMinutes <= 0) {
    return [];
  }

  const slots = [];
  for (let time = startMinutes; time + durationMinutes <= endMinutes; time += durationMinutes) {
    slots.push(time);
  }

  return slots;
};

const buildSlotTimesForSchedule = (scheduleDay, durationMinutes) => {
  if (!scheduleDay || scheduleDay.isOpen !== true) {
    return [];
  }

  const openMinutes = parseTimeToMinutes(scheduleDay.openTime);
  const closeMinutes = parseTimeToMinutes(scheduleDay.closeTime);
  if (openMinutes === null || closeMinutes === null || closeMinutes <= openMinutes) {
    return [];
  }

  const slots = [...buildSlotsForRange(openMinutes, closeMinutes, durationMinutes)];

  if (scheduleDay.isSplitShift) {
    const secondOpenMinutes = parseTimeToMinutes(scheduleDay.secondOpenTime);
    const secondCloseMinutes = parseTimeToMinutes(scheduleDay.secondCloseTime);
    if (secondOpenMinutes !== null && secondCloseMinutes !== null && secondCloseMinutes > secondOpenMinutes) {
      slots.push(...buildSlotsForRange(secondOpenMinutes, secondCloseMinutes, durationMinutes));
    }
  }

  return slots;
};

const normalizeBusinessOfferPayload = (rawOffer) => {
  if (!rawOffer || typeof rawOffer !== "object") {
    return null;
  }

  const name = toTrimmedString(rawOffer.name);
  const serviceType = toTrimmedString(rawOffer.serviceType);
  const price = Number(rawOffer.price);
  const durationMinutes = Number(rawOffer.durationMinutes);

  if (!name || !serviceType || !Number.isFinite(price) || price < 0 || !Number.isInteger(durationMinutes) || durationMinutes <= 0) {
    return null;
  }

  return {
    name,
    serviceType,
    price,
    durationMinutes,
  };
};

const normalizeBusinessScheduleDayPayload = (rawDay) => {
  if (!rawDay || typeof rawDay !== "object") {
    return null;
  }

  const day = toTrimmedString(rawDay.day);
  const isOpen = rawDay.isOpen === true;
  const openTime = toTrimmedString(rawDay.openTime);
  const closeTime = toTrimmedString(rawDay.closeTime);
  const isSplitShift = rawDay.isSplitShift === true;
  const secondOpenTime = toTrimmedString(rawDay.secondOpenTime);
  const secondCloseTime = toTrimmedString(rawDay.secondCloseTime);

  if (!day) {
    return null;
  }

  if (!isOpen) {
    return {
      day,
      isOpen: false,
      openTime: openTime || "00:00",
      closeTime: closeTime || "00:00",
      isSplitShift: false,
      secondOpenTime: "",
      secondCloseTime: "",
    };
  }

  const openMinutes = parseTimeToMinutes(openTime);
  const closeMinutes = parseTimeToMinutes(closeTime);
  if (openMinutes === null || closeMinutes === null || closeMinutes <= openMinutes) {
    return null;
  }

  if (!isSplitShift) {
    return {
      day,
      isOpen: true,
      openTime,
      closeTime,
      isSplitShift: false,
      secondOpenTime: "",
      secondCloseTime: "",
    };
  }

  const secondOpenMinutes = parseTimeToMinutes(secondOpenTime);
  const secondCloseMinutes = parseTimeToMinutes(secondCloseTime);

  if (
    secondOpenMinutes === null ||
    secondCloseMinutes === null ||
    secondCloseMinutes <= secondOpenMinutes ||
    secondOpenMinutes <= closeMinutes
  ) {
    return null;
  }

  return {
    day,
    isOpen: true,
    openTime,
    closeTime,
    isSplitShift: true,
    secondOpenTime,
    secondCloseTime,
  };
};

const normalizeBusinessScheduleMode = (rawScheduleMode) => {
  const scheduleMode = toTrimmedString(rawScheduleMode);
  if (BUSINESS_SCHEDULE_MODES.has(scheduleMode)) {
    return scheduleMode;
  }

  return "single";
};

// Exportar todas las funciones y constantes
module.exports = {
  GOOGLE_PLACES_TEXT_SEARCH_URL,
  GOOGLE_PLACES_ALLOWED_TYPES,
  BUSINESS_SCHEDULE_MODES,
  WEEKDAY_LABELS,
  getGoogleMapsApiKey,
  mapGooglePlacesTextSearchResult,
  normalizeGooglePlacePayload,
  toTrimmedString,
  parseTimeToMinutes,
  parseDateParts,
  normalizeReservationDate,
  getReservationDayRange,
  formatMinutesToTime,
  resolveScheduleForDate,
  buildSlotsForRange,
  buildSlotTimesForSchedule,
  normalizeBusinessOfferPayload,
  normalizeBusinessScheduleDayPayload,
  normalizeBusinessScheduleMode,
};
