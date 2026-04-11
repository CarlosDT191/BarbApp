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

  /// Obtiene el token del usuario desde SharedPreferences
  Future<String?> _getUserToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  /// Obtiene todas las reservaciones del usuario actual
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
        throw Exception("Error al obtener reservaciones: ${response.statusCode}");
      }

      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Reservation.fromJson(json)).toList();
    } catch (e) {
      throw Exception("Error en getMyReservations: $e");
    }
  }

  /// Obtiene las reservaciones de un día específico
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
      throw Exception("Error al obtener reservaciones del día: $e");
    }
  }

  /// Crea una nueva reservación
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

  /// Elimina una reservación por ID
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

  /// Agrupa las reservaciones por día
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
