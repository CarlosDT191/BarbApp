import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/home/home_page_client.dart';
import 'package:flutter_application_1/features/home/home_page_owner.dart';
import 'package:flutter_application_1/features/calendar/calendar_page.dart';
import 'package:flutter_application_1/features/profile/profile_page.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/models/decorations.dart';
import 'package:intl/intl.dart';
import 'package:intl/intl_standalone.dart';
import 'package:intl/date_symbol_data_local.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  int _selectedIndex = 0;
  int role = 0;

  List<dynamic> notifications = [];
  bool isLoading = true;

  final primaryColor = Color.fromARGB(255, 200, 156, 125);
  final backgroundColor = Color.fromARGB(255, 23, 23, 23);
  final textColor = Colors.white;

  Future<int?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("role");
  }

  Future<void> fetchNotifications() async {
    final token = await getUserToken();
    final apiBaseUrl = getApiBaseUrl();

    final response = await http.get(
      Uri.parse("$apiBaseUrl/notifications"),
      headers: {
        "Authorization": "Bearer $token"
      },
    );

    final data = jsonDecode(response.body);

    setState(() {
      notifications = data;
      isLoading = false;
    });
  }

  Future<void> markAsRead(String id) async {
    final token = await getUserToken();
    final apiBaseUrl = getApiBaseUrl();

    await http.patch(
      Uri.parse("$apiBaseUrl/notifications/$id/read"),
      headers: {
        "Authorization": "Bearer $token"
      },
    );

    fetchNotifications();
  }

  IconData _getIcon(String type) {
    switch (type) {
      case "reservation":
        return Icons.calendar_today;
      case "cancel":
        return Icons.cancel;
      case "reminder":
        return Icons.notifications;
      default:
        return Icons.info;
    }
  }

  Widget _buildNotificationItem(dynamic notif) {
    final bool isRead = notif["read"] ?? false;

    return GestureDetector(
      onTap: () => markAsRead(notif["_id"]),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead
              ? Color.fromARGB(255, 40, 40, 40)
              : Color.fromARGB(255, 60, 50, 40),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(
              _getIcon(notif["type"]),
              color: primaryColor,
            ),
            SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notif["message"],
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight:
                          isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    DateFormat('dd MMM yyyy - HH:mm')
                        .format(DateTime.parse(notif["createdAt"])),
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<String?> getUserToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  // Controla qué pasa al pulsar cada icono
  void _onItemTapped(int index) async {
    setState(() {
      _selectedIndex = index; // Actualiza el icono seleccionado
    });

    int role = await getUserRole() ?? 0;

    // Aquí puedes poner la acción de cada icono
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CalendarPage()),
        );
        break;
      case 1:
        print("Estrella pulsada: $role");
        break;
      case 2:
        // PROPIETARIO
        if (role == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePageOwner()),
          );
        } 
        // CLIENTE
        else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
        break;
      case 3:
        print("Notificaciones pulsado");
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );
        break;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(

      // BARRA INFERIOR
      bottomNavigationBar: InputDecorations.mainBottomNavBar(
        currentIndex: 3,
        owner: false,
        onTap: _onItemTapped,
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          
          SizedBox(height: 90,),

          Text('Notificaciones', style: TextStyle( fontSize: 33, color: Color.fromARGB(255, 200, 156, 125), fontWeight: FontWeight.bold)),
          Text('Aquí puedes ver tus notificaciones', style: TextStyle( fontSize: 14, color: Color.fromARGB(255, 200, 156, 125))),

          SizedBox(height: 20,),

          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : notifications.isEmpty
                    ? Center(
                        child: Text(
                          "No tienes notificaciones",
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : ListView.builder(
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final notif = notifications[index];
                          return _buildNotificationItem(notif);
                        },
                      ),
          )
        ],
      ),
    );
  }
}