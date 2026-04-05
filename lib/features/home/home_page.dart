import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/features/calendar/calendar_page.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 2;

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
    final apiBaseUrl = getApiBaseUrl();
    final response = await http.get(
      Uri.parse("$apiBaseUrl/users/me"),
      headers: {
        "Authorization": "Bearer $token"
      },
    );

    return jsonDecode(response.body);
  }

  // Controla qué pasa al pulsar cada icono
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Actualiza el icono seleccionado
    });

    // Aquí puedes poner la acción de cada icono
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CalendarPage()),
        );
        break;
      case 1:
        print("Estrella pulsado");
        break;
      case 2:
        print("Mapa pulsado");
        break;
      case 3:
        print("Notificaciones pulsado");
        break;
      case 4:
        logout(context);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

        // BARRA INFERIOR
        bottomNavigationBar: SizedBox(
          height: 125, // 👈 altura total de la barra
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            // 🎨 COLOR DE FONDO
            backgroundColor: Color.fromARGB(255, 23, 23, 23),

            // 🎨 ICONO SELECCIONADO
            selectedItemColor: Color.fromARGB(255, 200, 156, 125),

            // 🎨 ICONOS NO SELECCIONADOS
            unselectedItemColor: Colors.grey,

            currentIndex: 2,
            iconSize: 40,
            onTap: _onItemTapped,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: ""),
              BottomNavigationBarItem(icon: Icon(Icons.star_rate_rounded), label: ""),
              BottomNavigationBarItem(icon: Icon(Icons.map_rounded, size: 65), label: ""),
              BottomNavigationBarItem(icon: Icon(Icons.notifications_rounded), label: ""),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: ""),
            ],
          ),
        ),


        body: Stack(
          children: [

            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(37.8882, -4.7794), // Córdoba
                zoom: 14,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),

            /* 👉 CÓMO OBTENER VALORES DE USUARIO
            Container(
              color: Colors.grey,
              child: Center(
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
                      "Bienvenido ${user["firstname"]} ${user["lastname"]}",
                      style: TextStyle(fontSize: 24, color: Colors.black),
                    );
                  },
                ),
              ),
            ),  */

            // 👉 BARRA DE BÚSQUEDA FLOTANTE
            Positioned(
              top: 50,
              left: 16,
              right: 16,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    )
                  ],
                ),
                child: Row(
                  children: [

                    SizedBox(width: 15),

                    Icon(Icons.search, color: Colors.grey),

                    SizedBox(width: 8),

                    // 👉 INPUT
                    Expanded(
                      child: TextField(
                        style: TextStyle(
                          color: Colors.black, // 👈 color del texto que escribe el usuario
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: "Buscar locales",
                          hintStyle: TextStyle(
                          color: Colors.grey, // 👈 color del placeholder
                        ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    // 👉 ICONO DE FILTROS
                    IconButton(
                      icon: Icon(Icons.tune, color: Colors.grey),
                      onPressed: () {
                        print("Filtros pulsado");
                      },
                    ),

                    SizedBox(width: 1),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }
}
