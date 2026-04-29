class BookingBusinessSummary {
  final String id;
  final String name;
  final String address;
  final String placeId;

  BookingBusinessSummary({
    required this.id,
    required this.name,
    required this.address,
    required this.placeId,
  });

  factory BookingBusinessSummary.fromJson(Map<String, dynamic> json) {
    return BookingBusinessSummary(
      id: json['businessId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      placeId: json['placeId']?.toString() ?? '',
    );
  }
}

class BookingBusinessOffer {
  final String name;
  final String serviceType;
  final double price;
  final int durationMinutes;

  BookingBusinessOffer({
    required this.name,
    required this.serviceType,
    required this.price,
    required this.durationMinutes,
  });

  factory BookingBusinessOffer.fromJson(Map<String, dynamic> json) {
    return BookingBusinessOffer(
      name: json['name']?.toString() ?? '',
      serviceType: json['serviceType']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
    );
  }
}

class BookingBusinessDetails {
  final String id;
  final String name;
  final String address;
  final int employeeCount;
  final List<BookingBusinessOffer> offers;

  BookingBusinessDetails({
    required this.id,
    required this.name,
    required this.address,
    required this.employeeCount,
    required this.offers,
  });

  factory BookingBusinessDetails.fromJson(Map<String, dynamic> json) {
    final rawOffers = json['offers'] as List<dynamic>? ?? const <dynamic>[];
    final offers = rawOffers
        .whereType<Map<String, dynamic>>()
        .map((offer) => BookingBusinessOffer.fromJson(offer))
        .toList();

    final googlePlace = json['googlePlace'] as Map<String, dynamic>?;

    return BookingBusinessDetails(
      id: json['businessId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: googlePlace?['address']?.toString() ?? '',
      employeeCount: (json['employeeCount'] as num?)?.toInt() ?? 0,
      offers: offers,
    );
  }
}

class BookingAvailabilitySlot {
  final String time;
  final int remaining;
  final int capacity;

  BookingAvailabilitySlot({
    required this.time,
    required this.remaining,
    required this.capacity,
  });

  factory BookingAvailabilitySlot.fromJson(Map<String, dynamic> json) {
    return BookingAvailabilitySlot(
      time: json['time']?.toString() ?? '00:00',
      remaining: (json['remaining'] as num?)?.toInt() ?? 0,
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
    );
  }
}

class BookingAvailability {
  final String businessId;
  final String date;
  final BookingBusinessOffer offer;
  final int capacity;
  final List<BookingAvailabilitySlot> slots;

  BookingAvailability({
    required this.businessId,
    required this.date,
    required this.offer,
    required this.capacity,
    required this.slots,
  });

  factory BookingAvailability.fromJson(Map<String, dynamic> json) {
    final rawSlots = json['slots'] as List<dynamic>? ?? const <dynamic>[];
    final slots = rawSlots
        .whereType<Map<String, dynamic>>()
        .map((slot) => BookingAvailabilitySlot.fromJson(slot))
        .toList();

    final offerData = json['offer'] as Map<String, dynamic>? ?? const {};

    return BookingAvailability(
      businessId: json['businessId']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      offer: BookingBusinessOffer.fromJson(offerData),
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
      slots: slots,
    );
  }
}
