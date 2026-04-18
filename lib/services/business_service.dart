import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/config/api_config.dart';

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
}
