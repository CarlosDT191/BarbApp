import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/home/home_page_client.dart';
import 'package:flutter_application_1/features/home/home_page_owner.dart';
import 'package:flutter_application_1/features/favorites/favorites.dart';
import 'package:flutter_application_1/features/calendar/calendar_page.dart';
import 'package:flutter_application_1/features/profile/profile_page.dart';
import 'package:flutter_application_1/features/business/owner_business_page.dart';
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
  int? role = 0;

  List<dynamic> notifications = [];
  bool isLoading = true;

  final primaryColor = Color.fromARGB(255, 200, 156, 125);
  final backgroundColor = Color.fromARGB(255, 23, 23, 23);
  final textColor = Colors.white;

  /// Obtiene el rol del usuario desde [SharedPreferences].
  ///
  /// Retorna un `int` con el rol del usuario o `null` si no existe.
  /// Los roles son: 0=cliente, 1=propietario, 2=admin.
  Future<int?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("role");
  }

  int get unreadCount {
    return notifications.where((n) => n["read"] == false).length;
  }

  /// Obtiene todas las notificaciones del usuario desde el backend.
  ///
  /// Realiza una solicitud HTTP al servidor y actualiza el estado
  /// con la lista completa de notificaciones del usuario autenticado.
  Future<void> fetchNotifications() async {
    final token = await getUserToken();
    final apiBaseUrl = getApiBaseUrl();

    final response = await http.get(
      Uri.parse("$apiBaseUrl/notifications"),
      headers: {"Authorization": "Bearer $token"},
    );

    final data = jsonDecode(response.body);

    setState(() {
      notifications = data;
      isLoading = false;
    });
  }

  /// Marca una notificación como leída.
  ///
  /// [id] es el ID único de la notificación a marcar como leída (`String`).
  ///
  /// Realiza una solicitud PATCH al backend y recarga la lista de notificaciones.
  Future<void> markAsRead(String id) async {
    final token = await getUserToken();
    final apiBaseUrl = getApiBaseUrl();

    await http.patch(
      Uri.parse("$apiBaseUrl/notifications/$id/read"),
      headers: {"Authorization": "Bearer $token"},
    );

    fetchNotifications();
  }

  /// Devuelve el icono correspondiente según el tipo de notificación.
  ///
  /// [type] es el tipo de notificación (`String`): "reservation", "cancel", "reminder", "welcome", etc.
  ///
  /// Retorna un `IconData` con el icono representativo del tipo de notificación.
  IconData _getIcon(String type) {
    switch (type) {
      case "reservation":
        return Icons.calendar_today;
      case "cancel":
        return Icons.cancel;
      case "reminder":
        return Icons.notifications;
      case "welcome":
        return Icons.waving_hand_outlined;
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
            SizedBox(width: 3),
            Icon(_getIcon(notif["type"]), color: primaryColor),
            SizedBox(width: 18),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notif["message"],
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    DateFormat(
                      'dd MMM yyyy - HH:mm',
                    ).format(DateTime.parse(notif["createdAt"])),
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

  DateTime? _parseNotificationDate(dynamic notif) {
    final raw = notif["createdAt"];
    if (raw is! String || raw.trim().isEmpty) {
      return null;
    }

    try {
      return DateTime.parse(raw).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _labelForNotificationDate(DateTime createdAt, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final createdDay = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final dayDiff = today.difference(createdDay).inDays;

    if (dayDiff <= 0) {
      return 'Hoy';
    }
    if (dayDiff == 1) {
      return 'Ayer';
    }
    if (dayDiff <= 6) {
      return 'Hace $dayDiff días';
    }
    if (dayDiff <= 13) {
      return 'La semana pasada';
    }
    if (dayDiff <= 20) {
      return 'Hace 2 semanas';
    }
    if (dayDiff <= 27) {
      return 'Hace 3 semanas';
    }

    final monthsDiff =
        (now.year - createdAt.year) * 12 + (now.month - createdAt.month);
    if (monthsDiff <= 0) {
      return 'Hace $dayDiff días';
    }
    if (monthsDiff == 1) {
      return 'Mes pasado';
    }
    if (monthsDiff <= 11) {
      return 'Hace $monthsDiff meses';
    }

    final yearsDiff = (monthsDiff / 12).floor();
    if (yearsDiff == 1) {
      return 'El año pasado';
    }
    return 'Hace $yearsDiff años';
  }

  Widget _buildNotificationGroupHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 18, 25, 6),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  List<dynamic> _sortedNotifications() {
    final items = List<dynamic>.from(notifications);
    items.sort((a, b) {
      final dateA = _parseNotificationDate(a);
      final dateB = _parseNotificationDate(b);

      if (dateA == null && dateB == null) {
        return 0;
      }
      if (dateA == null) {
        return 1;
      }
      if (dateB == null) {
        return -1;
      }

      return dateB.compareTo(dateA);
    });
    return items;
  }

  List<Widget> _buildNotificationListWidgets() {
    final now = DateTime.now();
    final items = _sortedNotifications();
    final widgets = <Widget>[];

    String? currentLabel;
    for (final notif in items) {
      final createdAt = _parseNotificationDate(notif);
      final label = createdAt == null
          ? 'Sin fecha'
          : _labelForNotificationDate(createdAt, now);

      if (label != currentLabel) {
        widgets.add(_buildNotificationGroupHeader(label));
        currentLabel = label;
      }

      widgets.add(_buildNotificationItem(notif));
    }

    return widgets;
  }

  @override
  void initState() {
    super.initState();
    fetchNotifications();
    loadUserRole();
  }

  void loadUserRole() async {
    int? r = await getUserRole();
    setState(() {
      role = r;
    });
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
        if (role == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OwnerBusinessPage()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const FavoritesPage()),
          );
        }
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
        Navigator.pushReplacement(
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
        context: context,
        currentIndex: 3,
        owner: role == 1,
        onTap: _onItemTapped,
        unreadNotifications: unreadCount,
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 90),

          Text(
            'Notificaciones',
            style: TextStyle(
              fontSize: 33,
              color: Color.fromARGB(255, 200, 156, 125),
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Aquí puedes ver tus notificaciones',
            style: TextStyle(
              fontSize: 14,
              color: Color.fromARGB(255, 200, 156, 125),
            ),
          ),

          SizedBox(height: 20),

          Expanded(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: Color.fromARGB(255, 200, 156, 125),
                    ),
                  )
                : notifications.isEmpty
                ? Center(
                    child: Text(
                      "No tienes notificaciones",
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.only(bottom: 16),
                    children: _buildNotificationListWidgets(),
                  ),
          ),
        ],
      ),
    );
  }
}
