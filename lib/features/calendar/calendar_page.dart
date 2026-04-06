import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/home/home_page_client.dart';
import 'package:flutter_application_1/features/home/home_page_owner.dart';
import 'package:flutter_application_1/features/notifications/notification_page.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/models/decorations.dart';
import 'package:intl/intl.dart';
import 'package:intl/intl_standalone.dart';
import 'package:intl/date_symbol_data_local.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  int _selectedIndex = 0;
  int role = 0;

  Map<DateTime, List<dynamic>> reservations = {};

  final primaryColor = Color.fromARGB(255, 200, 156, 125);
  final backgroundColor = Color.fromARGB(255, 23, 23, 23);
  final textColor = Colors.white;

  Future<int?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("role");
  }

  @override
  void initState() {
    super.initState();
    fetchReservations();
  }

  Future<String?> getUserToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  Future<void> fetchReservations() async {
    final token = await getUserToken();
    final apiBaseUrl = getApiBaseUrl();

    final response = await http.get(
      Uri.parse("$apiBaseUrl/reservations/me"),
      headers: {
        "Authorization": "Bearer $token"
      },
    );

    final data = jsonDecode(response.body);

    Map<DateTime, List<dynamic>> loaded = {};

    for (var res in data) {
      DateTime date = DateTime.parse(res["date"]);

      DateTime normalized = DateTime(date.year, date.month, date.day);

      if (loaded[normalized] == null) {
        loaded[normalized] = [];
      }

      loaded[normalized]!.add(res);
    }

    setState(() {
      reservations = loaded;
    });
  }

  List<dynamic> _getReservationsForDay(DateTime day) {
    return reservations[DateTime(day.year, day.month, day.day)] ?? [];
  }

  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    // Elimina los datos de la sesión
    await prefs.clear();

    Navigator.pushReplacementNamed(context, "/login");
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
        print("Calendario pulsado");
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => NotificationPage()),
        );
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
      bottomNavigationBar: InputDecorations.mainBottomNavBar(
        currentIndex: 0,
        owner: false,
        onTap: _onItemTapped,
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          
          SizedBox(height: 90,),

          Text('Mis reservas', style: TextStyle( fontSize: 33, color: Color.fromARGB(255, 200, 156, 125), fontWeight: FontWeight.bold)),
          Text('Revisa tus reservas ya creadas o solicita alguna nueva', style: TextStyle( fontSize: 14, color: Color.fromARGB(255, 200, 156, 125))),

          SizedBox(height: 70,),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 30, 30, 30), // ligeramente distinto del fondo
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: TableCalendar(
                daysOfWeekHeight: 40,
                locale: 'es_ES',
                startingDayOfWeek: StartingDayOfWeek.monday,

                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,

                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },

                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },

                eventLoader: (day) {
                  return _getReservationsForDay(day);
                },

                // 🎨 HEADER (mes + flechas)
                headerStyle: HeaderStyle(
                  titleCentered: true,
                  titleTextStyle: TextStyle(color: textColor, fontSize: 18),
                  formatButtonVisible: false,
                  leftChevronIcon: Icon(Icons.chevron_left, color: primaryColor),
                  rightChevronIcon: Icon(Icons.chevron_right, color: primaryColor),
                ),

                // 🎨 DÍAS DE LA SEMANA (L M X J V S D)
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(color: textColor),
                  weekendStyle: TextStyle(color: primaryColor),
                ),

                // 🎨 CALENDARIO (días)
                calendarStyle: CalendarStyle(
                  defaultTextStyle: TextStyle(color: textColor),
                  weekendTextStyle: TextStyle(color: primaryColor),

                  todayDecoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),

                  selectedDecoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                  ),

                  markerDecoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                  ),

                  outsideTextStyle: TextStyle(color: Colors.grey),
                ),
                )
            ),
          ),
        ],
      ),
    );
  }
}