import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomePage extends StatelessWidget {

  const HomePage({super.key});

  // Función que contiene la lógica de cierre de sesión
  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    // Elimina los datos de la sesión
    await prefs.clear();

    Navigator.pushReplacementNamed(context, "/login");
  }


  // Función que recoge el token del usuario
  Future<String?> getUserToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  // Función que recoge los datos del usuario desde el backend
  Future<Map<String, dynamic>> getUserData() async {

    final token = await getUserToken();

    final response = await http.get(
      Uri.parse("http://10.0.2.2:3000/users/me"),
      headers: {
        "Authorization": "Bearer $token"
      },
    );

    return jsonDecode(response.body);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Página Principal"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              logout(context);
            },
          )
        ],
      ),
      body: Center(
        child: FutureBuilder(
          future: getUserData(),
          builder: (context, snapshot) {

            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            }

            if (snapshot.hasError) {
              return Text("Error: ${snapshot.error}");
            }

            if (!snapshot.hasData) {
              return Text("No hay datos");
            }

            final user = snapshot.data as Map<String, dynamic>;

            return Text(
              "Bienvenido ${user["username"]}",
              style: TextStyle(fontSize: 24),
            );
          },
        ),
      ),
    );
  }
}
