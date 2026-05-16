import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/models/booking_models.dart';

class BusinessService {
  static final String _apiBaseUrl = getApiBaseUrl();

  static Future<String> _getRequiredToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception('No se encontro token de sesion');
    }

    return token;
  }

  static Future<List<Map<String, dynamic>>> getMyBusinesses() async {
    final token = await _getRequiredToken();

    final response = await http.get(
      Uri.parse('$_apiBaseUrl/businesses/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Error al obtener negocios: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded.map((item) => item as Map<String, dynamic>).toList();
  }

  static Future<List<Map<String, dynamic>>> searchGooglePlacesForBusinessLink({
    required String query,
    String type = 'hair_care',
  }) async {
    final token = await _getRequiredToken();
    final normalizedQuery = query.trim();

    if (normalizedQuery.length < 2) {
      return const [];
    }

    final uri = Uri.parse(
      '$_apiBaseUrl/businesses/google-places/search',
    ).replace(queryParameters: {'query': normalizedQuery, 'type': type});

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Error al buscar locales de Google: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final places = decoded['places'] as List<dynamic>? ?? const <dynamic>[];

    return places.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  static Future<Map<String, Map<String, dynamic>>>
  getRegisteredBusinessesByPlaceIds(List<String> placeIds) async {
    final token = await _getRequiredToken();
    final normalizedPlaceIds = placeIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (normalizedPlaceIds.isEmpty) {
      return const {};
    }

    final uri = Uri.parse(
      '$_apiBaseUrl/businesses/registered-by-place-ids',
    ).replace(queryParameters: {'placeIds': normalizedPlaceIds.join(',')});

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Error al consultar locales registrados: ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final registered =
        decoded['registered'] as List<dynamic>? ?? const <dynamic>[];

    final byPlaceId = <String, Map<String, dynamic>>{};
    for (final rawItem in registered) {
      if (rawItem is! Map<String, dynamic>) {
        continue;
      }
      final placeId = rawItem['placeId']?.toString().trim();
      if (placeId == null || placeId.isEmpty) {
        continue;
      }
      byPlaceId[placeId] = rawItem;
    }

    return byPlaceId;
  }

  static Future<bool> getRegisteredBusinessesByPlaceId(String placeId) async {
    final token = await _getRequiredToken();
    final normalizedPlaceId = placeId.trim();

    if (normalizedPlaceId.isEmpty) {
      return false;
    }

    final uri = Uri.parse(
      '$_apiBaseUrl/businesses/registered-by-place-ids',
    ).replace(queryParameters: {'placeIds': normalizedPlaceId});

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Error al consultar locales registrados: ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final registered =
        decoded['registered'] as List<dynamic>? ?? const <dynamic>[];

    return registered.isNotEmpty;
  }

  static Future<Map<String, dynamic>> createBusiness({
    required Map<String, dynamic> payload,
  }) async {
    final token = await _getRequiredToken();

    final response = await http.post(
      Uri.parse('$_apiBaseUrl/businesses'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode != 201) {
      throw Exception('Error al crear negocio: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateBusiness({
    required String businessId,
    required Map<String, dynamic> payload,
  }) async {
    final token = await _getRequiredToken();

    final response = await http.put(
      Uri.parse('$_apiBaseUrl/businesses/$businessId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al actualizar negocio: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<BookingBusinessDetails> getBusinessDetails({
    required String businessId,
  }) async {
    final token = await _getRequiredToken();

    final response = await http.get(
      Uri.parse('$_apiBaseUrl/businesses/$businessId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Error al obtener negocio: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return BookingBusinessDetails.fromJson(decoded);
  }

  static Future<Map<String, dynamic>> getBusinessDetailsPayload({
    required String businessId,
  }) async {
    final token = await _getRequiredToken();

    final response = await http.get(
      Uri.parse('$_apiBaseUrl/businesses/$businessId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Error al obtener negocio: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getBusinessRevenue({
    required String businessId,
  }) async {
    final token = await _getRequiredToken();

    final response = await http.get(
      Uri.parse('$_apiBaseUrl/businesses/$businessId/revenue'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Error al obtener ingresos: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<List<String>> updateBusinessVacationDays({
    required String businessId,
    required List<String> vacationDays,
  }) async {
    final token = await _getRequiredToken();

    final response = await http.put(
      Uri.parse('$_apiBaseUrl/businesses/$businessId/vacations'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'vacationDays': vacationDays,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Error al actualizar vacaciones: ${response.body}',
      );
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final rawDays = payload['vacationDays'] as List<dynamic>? ?? const [];
    return rawDays.map((day) => day.toString()).toList();
  }

  static Future<void> deleteBusiness({required String businessId}) async {
    final token = await _getRequiredToken();

    final response = await http.delete(
      Uri.parse('$_apiBaseUrl/businesses/$businessId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Error al eliminar negocio: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> saveBusinessCreationData({
    required String businessId,
    required Map<String, dynamic> requestPayload,
    required Map<String, dynamic> generatedData,
  }) async {
    final token = await _getRequiredToken();

    final response = await http.post(
      Uri.parse('$_apiBaseUrl/businesses/creation-data'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'businessId': businessId,
        'requestPayload': requestPayload,
        'generatedData': generatedData,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Error al guardar datos de creacion: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<List<BookingBusinessSummary>> listRegisteredBusinesses({
    String query = '',
  }) async {
    final token = await _getRequiredToken();
    final normalizedQuery = query.trim();

    final uri = Uri.parse('$_apiBaseUrl/businesses').replace(
      queryParameters:
          normalizedQuery.isEmpty ? null : {'q': normalizedQuery},
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Error al obtener negocios: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final rawBusinesses =
        decoded['businesses'] as List<dynamic>? ?? const <dynamic>[];

    return rawBusinesses
        .whereType<Map<String, dynamic>>()
        .map((item) => BookingBusinessSummary.fromJson(item))
        .toList(growable: false);
  }

  static Future<BookingAvailability> getBusinessAvailability({
    required String businessId,
    required String date,
    required int offerIndex,
  }) async {
    final token = await _getRequiredToken();
    final normalizedId = businessId.trim();
    final normalizedDate = date.trim();

    if (normalizedId.isEmpty || normalizedDate.isEmpty) {
      throw Exception('Parametros invalidos para disponibilidad');
    }

    final uri = Uri.parse('$_apiBaseUrl/businesses/$normalizedId/availability')
        .replace(queryParameters: {
      'date': normalizedDate,
      'offerIndex': offerIndex.toString(),
    });

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Error al obtener disponibilidad: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return BookingAvailability.fromJson(decoded);
  }
}
