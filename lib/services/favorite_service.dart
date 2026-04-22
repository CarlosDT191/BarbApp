import 'dart:convert';

import 'package:flutter_application_1/config/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteService {
  static final String _apiBaseUrl = getApiBaseUrl();

  static Future<String> _getRequiredToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception('No se encontro token de sesion');
    }

    return token;
  }

  static Future<Set<String>> getFavoriteBusinessIds() async {
    final token = await _getRequiredToken();

    final response = await http.get(
      Uri.parse('$_apiBaseUrl/favorites'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Error al obtener favoritos: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;

    return decoded
        .whereType<Map<String, dynamic>>()
        .map((item) => item['businessId']?.toString().trim() ?? '')
        .where((businessId) => businessId.isNotEmpty)
        .toSet();
  }

  static Future<void> addFavoriteBusiness(String businessId) async {
    final normalized = businessId.trim();
    if (normalized.isEmpty) {
      return;
    }

    final token = await _getRequiredToken();

    final response = await http.post(
      Uri.parse('$_apiBaseUrl/favorites'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'businessId': normalized}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error al guardar favorito: ${response.body}');
    }
  }

  static Future<void> removeFavoriteBusiness(String businessId) async {
    final normalized = businessId.trim();
    if (normalized.isEmpty) {
      return;
    }

    final token = await _getRequiredToken();
    final encodedBusinessId = Uri.encodeComponent(normalized);

    final response = await http.delete(
      Uri.parse('$_apiBaseUrl/favorites/$encodedBusinessId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Error al eliminar favorito: ${response.body}');
    }
  }
}
