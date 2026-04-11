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

  /// Obtiene la hora de inicio (ej: 14)
  int get startHour {
    return int.parse(time.split(":")[0]);
  }

  /// Obtiene los minutos de inicio (ej: 30)
  int get startMinute {
    return int.parse(time.split(":")[1]);
  }

  /// Obtiene la hora de fin (asume duración de 1 hora)
  int get endHour {
    final end = startHour + 1;
    return end >= 24 ? 23 : end;
  }

  /// Obtiene los minutos de fin (mismo minuto que inicio)
  int get endMinute {
    return startMinute;
  }

  /// Calcula la duración en minutos (asume 60 minutos por defecto)
  int get durationMinutes {
    if (endHour == 23 && startHour == 23) {
      return 60 - startMinute; // Última hora del día
    }
    return 60; // Duración fija de 1 hora
  }

  /// Convierte a JSON para enviar al backend
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'time': time,
      'local_name': localName,
    };
  }

  /// Factory para crear desde JSON del backend
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
