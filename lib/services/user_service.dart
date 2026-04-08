import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/config/api_config.dart';

class UserService {
  static final apiBaseUrl = getApiBaseUrl();

  // Obtener datos del usuario actual
  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        throw Exception("No token found");
      }

      final response = await http.get(
        Uri.parse("$apiBaseUrl/users/me"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception("Error: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error fetching user: $e");
    }
  }

  // Actualizar perfil del usuario
  static Future<Map<String, dynamic>> updateProfile({
    required String firstname,
    required String lastname,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        throw Exception("No token found");
      }

      final response = await http.put(
        Uri.parse("$apiBaseUrl/users/profile"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: json.encode({
          "firstname": firstname,
          "lastname": lastname,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Guardar datos en SharedPreferences
        await prefs.setString("firstname", firstname);
        await prefs.setString("lastname", lastname);
        return data;
      } else {
        final data = json.decode(response.body);
        String errorMessage = data["error"] ?? "Error desconocido";
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception("Error actualizando perfil: $e");
    }
  }

  // Cambiar contraseña
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        throw Exception("No token found");
      }

      final response = await http.patch(
        Uri.parse("$apiBaseUrl/users/password"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: json.encode({
          "currentPassword": currentPassword,
          "newPassword": newPassword,
          "confirmPassword": confirmPassword,
        }),
      );

      if (response.statusCode != 200) {
        final data = json.decode(response.body);
        String errorMessage = data["error"] ?? "Error desconocido";
        throw Exception(errorMessage);
      }
      else{
        final data = json.decode(response.body);
        return data;
      }
    } catch (e) {
      throw Exception("$e");
    }
  }
}
