class Reservation {
  final String id;
  final String userId;
  final DateTime date;
  final String time; // Formato: "HH:mm" (ej: "14:30")
  final String localName;
  final DateTime createdAt;
  final DateTime updatedAt;

  Reservation({
    required this.id,
    required this.userId,
    required this.date,
    required this.time,
    required this.localName,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Obtiene la hora de inicio de la reservación.
  ///
  /// Extrae la parte de horas del formato "HH:mm".
  /// Retorna un `int` con la hora en formato 24 horas (0-23).
  int get startHour {
    return int.parse(time.split(":")[0]);
  }

  /// Obtiene los minutos de inicio de la reservación.
  ///
  /// Extrae la parte de minutos del formato "HH:mm".
  /// Retorna un `int` con los minutos (0-59).
  int get startMinute {
    return int.parse(time.split(":")[1]);
  }

  /// Obtiene la hora de finalización de la reservación.
  ///
  /// Asume una duración fija de 1 hora desde la hora de inicio.
  /// Retorna un `int` con la hora de fin en formato 24 horas (0-23).
  int get endHour {
    final end = startHour + 1;
    return end >= 24 ? 23 : end;
  }

  /// Obtiene los minutos de finalización de la reservación.
  ///
  /// Son los mismos minutos que el inicio de la reservación.
  /// Retorna un `int` con los minutos de fin (0-59).
  int get endMinute {
    return startMinute;
  }

  /// Calcula la duración total de la reservación en minutos.
  ///
  /// Por defecto asume duración de 1 hora (60 minutos).
  /// Retorna un `int` con la duración total en minutos.
  int get durationMinutes {
    if (endHour == 23 && startHour == 23) {
      return 60 - startMinute; // Última hora del día
    }
    return 60; // Duración fija de 1 hora
  }

  /// Convierte el objeto Reservation a un mapa JSON.
  ///
  /// Útil para enviar datos al backend en solicitudes HTTP.
  /// Retorna un `Map<String, dynamic>` con los datos de la reservación en formato JSON.
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
    return Reservation(
      id: json['_id'] ?? '',
      userId: json['user'] ?? '',
      date: DateTime.parse(json['date']),
      time: json['time'] ?? '00:00',
      localName: json['local_name'] ?? 'Sin nombre',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  @override
  String toString() => 'Reservation($id, $localName, $time)';
}
