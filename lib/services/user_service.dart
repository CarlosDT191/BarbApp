import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/config/api_config.dart';

class UserService {
  static final apiBaseUrl = getApiBaseUrl();

  /// Obtiene los datos del usuario actualmente autenticado.
  ///
  /// Requiere un token JWT válido almacenado en [SharedPreferences].
  /// Retorna un mapa con los datos del usuario incluyendo email, nombre, apellido y rol.
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

  /// Actualiza el nombre y apellido del usuario autenticado.
  ///
  /// [firstname] es el nuevo nombre del usuario (`String`).
  /// [lastname] es el nuevo apellido del usuario (`String`).
  ///
  /// También guarda los cambios en [SharedPreferences] para acceso local.
  /// Retorna un mapa con la respuesta del servidor con datos actualizados.
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

  /// Cambia la contraseña del usuario autenticado.
  ///
  /// [currentPassword] es la contraseña actual del usuario (`String`).
  /// [newPassword] es la nueva contraseña deseada (`String`).
  /// [confirmPassword] es la confirmación de la nueva contraseña (`String`).
  ///
  /// Valida que la contraseña actual sea correcta y que las nuevas coincidan.
  /// Retorna un mapa con la respuesta del servidor confirmando el cambio.
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

  /// Obtiene las notificaciones del usuario y calcula cuántas no han sido leídas.
  ///
  /// [token] es el token JWT del usuario (`String`).
  ///
  /// Almacena el número de notificaciones no leídas en [SharedPreferences]
  /// para acceso rápido desde la interfaz.
  static Future<void> fetchAndStoreNotifications(String token) async {
    final apiBaseUrl = getApiBaseUrl();

    final response = await http.get(
      Uri.parse("$apiBaseUrl/notifications"),
      headers: {
        "Authorization": "Bearer $token"
      },
    );

    final data = jsonDecode(response.body);

    // Calcular no leídas
    int unread = data.where((n) => n["read"] == false).length;

    // Guardar en local
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("unread_notifications", unread);
  }

  /// Actualiza el número de notificaciones no leídas.
  ///
  /// Obtiene el token del almacenamiento local y actualiza el conteo
  /// de notificaciones sin leer llamando a [fetchAndStoreNotifications].
  static Future<void> updateUnreadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null) return;

    await fetchAndStoreNotifications(token);
  }

  /// Elimina permanentemente la cuenta del usuario autenticado.
  ///
  /// Esta acción es irreversible y elimina todos los datos asociados al usuario
  /// de la base de datos. Retorna un mapa con el mensaje de confirmación del servidor.
  static Future<Map<String, dynamic>> deleteProfile() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null) {
      throw Exception("No token found");
    }

    final response = await http.delete(
      Uri.parse("$apiBaseUrl/users/profile"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final data = json.decode(response.body);
      throw Exception(data["error"] ?? "Error eliminando usuario");
    }
  } catch (e) {
    throw Exception("Error eliminando cuenta: $e");
  }
}
}
