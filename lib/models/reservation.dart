class Reservation {
  final String id;
  final String userId;
  final String ownerId;
  final String businessId;
  final DateTime date;
  final String time; // Formato: "HH:mm" (ej: "14:30")
  final String localName;
  final String serviceName;
  final String serviceType;
  final double? servicePrice;
  final int durationMinutes;
  final String clientName;
  final String clientEmail;
  final DateTime createdAt;
  final DateTime updatedAt;

  Reservation({
    required this.id,
    required this.userId,
    required this.ownerId,
    required this.businessId,
    required this.date,
    required this.time,
    required this.localName,
    required this.serviceName,
    required this.serviceType,
    required this.servicePrice,
    required this.durationMinutes,
    required this.clientName,
    required this.clientEmail,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Obtiene la hora de inicio de la reserva.
  ///
  /// Extrae la parte de horas del formato "HH:mm".
  /// Retorna un `int` con la hora en formato 24 horas (0-23).
  int get startHour {
    return int.parse(time.split(":")[0]);
  }

  /// Obtiene los minutos de inicio de la reserva.
  ///
  /// Extrae la parte de minutos del formato "HH:mm".
  /// Retorna un `int` con los minutos (0-59).
  int get startMinute {
    return int.parse(time.split(":")[1]);
  }

  /// Obtiene la hora de finalización de la reserva.
  ///
  /// Usa la duración real de la reserva en minutos.
  /// Retorna un `int` con la hora de fin en formato 24 horas (0-23).
  int get endHour {
    final totalMinutes = (startHour * 60) + startMinute + durationMinutes;
    return (totalMinutes ~/ 60) % 24;
  }

  /// Obtiene los minutos de finalización de la reserva.
  ///
  /// Son los mismos minutos que el inicio de la reserva.
  /// Retorna un `int` con los minutos de fin (0-59).
  int get endMinute {
    final totalMinutes = (startHour * 60) + startMinute + durationMinutes;
    return totalMinutes % 60;
  }

  /// Calcula la duración total de la reserva en minutos.
  ///
  /// Retorna un `int` con la duración total en minutos.
  String get businessDisplayName {
    return localName.isNotEmpty ? localName : 'Negocio';
  }

  String get serviceDisplayName {
    return serviceName.isNotEmpty ? serviceName : 'Servicio';
  }

  String get clientDisplayName {
    return clientName.isNotEmpty ? clientName : 'Cliente';
  }

  /// Convierte el objeto Reservation a un mapa JSON.
  ///
  /// Útil para enviar datos al backend en solicitudes HTTP.
  /// Retorna un `Map<String, dynamic>` con los datos de la reserva en formato JSON.
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'time': time,
      'local_name': localName,
    };
  }

  /// Factory constructor que crea una instancia de Reservation desde JSON.
  ///
  /// [json] es el mapa de datos JSON obtenido del servidor (`Map<String, dynamic>`).
  ///
  /// Parsea los datos del servidor y los convierte en el formato esperado.
  factory Reservation.fromJson(Map<String, dynamic> json) {
    final service = json['service'] as Map<String, dynamic>?;
    final durationValue = json['durationMinutes'] ?? service?['durationMinutes'];
    final parsedDuration = durationValue is num ? durationValue.toInt() : 60;
    final rawUserId = json['user'];
    final rawOwnerId = json['owner'];
    final rawBusinessId = json['business'] ?? json['businessId'];

    return Reservation(
      id: json['_id'] ?? '',
      userId: rawUserId?.toString() ?? '',
      ownerId: rawOwnerId?.toString() ?? '',
      businessId: rawBusinessId?.toString() ?? '',
      date: DateTime.parse(json['date']),
      time: json['time'] ?? '00:00',
      localName: json['local_name'] ?? 'Sin nombre',
      serviceName: service?['name']?.toString() ?? '',
      serviceType: service?['serviceType']?.toString() ?? '',
      servicePrice: (service?['price'] as num?)?.toDouble(),
      durationMinutes: parsedDuration < 1 ? 60 : parsedDuration,
      clientName: json['clientName']?.toString() ?? '',
      clientEmail: json['clientEmail']?.toString() ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  @override
  String toString() => 'Reservation($id, $localName, $time)';
}
