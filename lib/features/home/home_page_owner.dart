import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/features/calendar/calendar_page.dart';
import 'package:flutter_application_1/features/notifications/notification_page.dart';
import 'package:flutter_application_1/features/profile/profile_page.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_application_1/models/decorations.dart';
import 'package:flutter_application_1/services/user_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomePageOwner extends StatefulWidget {
  const HomePageOwner({super.key});

  @override
  State<HomePageOwner> createState() => _HomePageOwnerState();
}

class _HomePageOwnerState extends State<HomePageOwner> {
  int _selectedIndex = 2;
  int unread = 0;

  /// Obtiene el token JWT almacenado del usuario.
  ///
  /// Retorna un `String` con el token o `null` si no existe en [SharedPreferences].
  /// El token se utiliza para autenticar las solicitudes HTTP al backend.
  Future<String?> getUserToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  /// Obtiene los datos del usuario desde el backend.
  ///
  /// Requiere un token JWT válido almacenado localmente.
  /// Retorna un `Map<String, dynamic>` con los datos del usuario incluyendo
  /// email, nombre, apellido y rol del usuario autenticado.
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

  /// Maneja la navegación cuando se presiona un ícono de la barra inferior.
  ///
  /// [index] es el índice del ícono presionado, del 0 al 4 (`int`).
  ///
  /// Navega a diferentes páginas según el índice seleccionado.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Actualiza el icono seleccionado
    });

    // Aquí puedes poner la acción de cada icono
    switch (index) {
      case 0:
        Navigator.pushReplacement(
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => NotificationPage()),
        );
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );
        break;
    }
  }

  /// Obtiene el rol del usuario desde [SharedPreferences].
  ///
  /// Los roles disponibles son: 0=cliente, 1=propietario, 2=admin.
  /// Retorna un `int` con el rol del usuario o `null` si no existe.
  Future<int?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("role");
  }

  /// Obtiene el número de notificaciones no leídas.
  ///
  /// Lee el contador almacenado en [SharedPreferences].
  /// Retorna un `int` con el número total de notificaciones sin leer.
  Future<int> getUnreadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("unread_notifications") ?? 0;
  }

  @override
  void initState() {
    super.initState();
    initNotifications();
  }

  /// Inicializa y actualiza el listado de notificaciones no leídas.
  ///
  /// Obtiene los datos del servidor mediante [UserService.updateUnreadNotifications]
  /// y actualiza el estado local con el conteo de notificaciones sin leer.
  void initNotifications() async {
    await UserService.updateUnreadNotifications(); // API
    int unread = await getUnreadNotifications(); // local

    setState(() {
      this.unread = unread;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

        // BARRA INFERIOR CON LOS ICONOS
        bottomNavigationBar: InputDecorations.mainBottomNavBar(
          currentIndex: 2,
          owner: false,
          onTap: _onItemTapped,
          unreadNotifications: unread
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
