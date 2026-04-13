import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/models/reservation.dart';

class ReservationService {
  static final ReservationService _instance = ReservationService._internal();

  factory ReservationService() {
    return _instance;
  }

  ReservationService._internal();

  /// Obtiene el token JWT almacenado del usuario desde [SharedPreferences].
  ///
  /// Se utiliza para autenticar las solicitudes HTTP al backend.
  /// Retorna un token (`String`) o `null` si no se encuentra almacenado.
  Future<String?> _getUserToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  /// Obtiene todas las reservas del usuario autenticado.
  ///
  /// Retorna una `List<Reservation>` ordenada de todas las reservas registradas
  /// del usuario actual. Si no hay reservas, devuelve una lista vacía.
  Future<List<Reservation>> getMyReservations() async {
    try {
      final token = await _getUserToken();
      if (token == null) throw Exception("No hay token disponible");

      final apiBaseUrl = getApiBaseUrl();
      final response = await http.get(
        Uri.parse("$apiBaseUrl/reservations/me"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode != 200) {
        throw Exception("Error al obtener reservas: ${response.statusCode}");
      }

      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Reservation.fromJson(json)).toList();
    } catch (e) {
      throw Exception("Error en getMyReservations: $e");
    }
  }

  /// Obtiene las reservas de un día específico.
  ///
  /// [date] es la fecha para la cual se desean obtener las reservas (`DateTime`).
  ///
  /// Filtra y ordena las reservas por hora de inicio. Retorna un `List<Reservation>`
  /// con las reservas de ese día ordenadas cronológicamente.
  Future<List<Reservation>> getReservationsForDay(DateTime date) async {
    try {
      final allReservations = await getMyReservations();

      // Normalizar fecha (solo año, mes, día)
      final normalizedDate = DateTime(date.year, date.month, date.day);

      // Filtrar por día
      final dayReservations = allReservations.where((res) {
        final resDate = DateTime(res.date.year, res.date.month, res.date.day);
        return resDate == normalizedDate;
      }).toList();

      // Ordenar por hora
      dayReservations.sort((a, b) => a.startHour.compareTo(b.startHour));

      return dayReservations;
    } catch (e) {
      throw Exception("Error al obtener reservas del día: $e");
    }
  }

  /// Crea una nueva reservación para el usuario autenticado.
  ///
  /// [date] es la fecha deseada para la reservación (`DateTime`).
  /// [time] es la hora deseada en formato HH:mm, como "14:30" (`String`).
  /// [localName] es el nombre del establecimiento para la reservación (`String`).
  ///
  /// Envía los datos al backend y retorna un objeto `Reservation` con los datos
  /// de la nueva reserva creada.
  Future<Reservation> createReservation({
    required DateTime date,
    required String time, // Formato: "HH:mm"
    required String localName,
  }) async {
    try {
      final token = await _getUserToken();
      if (token == null) throw Exception("No hay token disponible");

      final apiBaseUrl = getApiBaseUrl();

      final body = jsonEncode({
        'date': date.toIso8601String(),
        'time': time,
        'local_name': localName,
      });

      final response = await http.post(
        Uri.parse("$apiBaseUrl/reservations"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: body,
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? "Error al crear reservación");
      }

      final jsonData = jsonDecode(response.body);
      return Reservation.fromJson(jsonData);
    } catch (e) {
      throw Exception("Error en createReservation: $e");
    }
  }

  /// Elimina una reservación existente del usuario.
  ///
  /// [reservationId] es el ID único de la reservación a eliminar (`String`).
  ///
  /// Solo puede eliminar sus propias reservas. Realiza una solicitud DELETE al backend
  /// para eliminar la reservación de forma permanente.
  Future<void> deleteReservation(String reservationId) async {
    try {
      final token = await _getUserToken();
      if (token == null) throw Exception("No hay token disponible");

      final apiBaseUrl = getApiBaseUrl();

      final response = await http.delete(
        Uri.parse("$apiBaseUrl/reservations/$reservationId"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception("Error al eliminar reservación: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error en deleteReservation: $e");
    }
  }

  /// Agrupa todas las reservas del usuario por fecha.
  ///
  /// Útil para mostrar las reservas organizadas por día en la interfaz de usuario.
  /// Retorna un `Map<DateTime, List<Reservation>>` donde cada clave es una fecha
  /// y el valor es una lista de reservas de ese día, ordenadas por hora.
  Future<Map<DateTime, List<Reservation>>> getReservationsGroupedByDay() async {
    try {
      final allReservations = await getMyReservations();
      final Map<DateTime, List<Reservation>> grouped = {};

      for (var reservation in allReservations) {
        final date = DateTime(
          reservation.date.year,
          reservation.date.month,
          reservation.date.day,
        );

        if (grouped[date] == null) {
          grouped[date] = [];
        }
        grouped[date]!.add(reservation);
      }

      // Ordenar eventos dentro de cada día
      grouped.forEach((date, reservations) {
        reservations.sort((a, b) => a.startHour.compareTo(b.startHour));
      });

      return grouped;
    } catch (e) {
      throw Exception("Error en getReservationsGroupedByDay: $e");
    }
  }
}
