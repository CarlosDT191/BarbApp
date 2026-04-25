import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/home/home_page_client.dart';
import 'package:flutter_application_1/features/home/home_page_owner.dart';
import 'package:flutter_application_1/features/favorites/favorites.dart';
import 'package:flutter_application_1/features/notifications/notification_page.dart';
import 'package:flutter_application_1/features/profile/profile_page.dart';
import 'package:flutter_application_1/features/business/owner_business_page.dart';
import 'package:flutter_application_1/features/calendar/pages/day_detail_page.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_application_1/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/models/decorations.dart';
import 'package:flutter_application_1/services/reservation_service.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  int unread = 0;
  int? role = 0;

  Map<DateTime, List<dynamic>> reservations = {};
  final ReservationService _reservationService = ReservationService();

  final primaryColor = Color.fromARGB(255, 200, 156, 125);
  final backgroundColor = Color.fromARGB(255, 23, 23, 23);
  final textColor = Colors.white;

  /// Obtiene el rol del usuario desde [SharedPreferences].
  ///
  /// Retorna un `int` con el rol del usuario o `null` si no se encuentra.
  /// Los roles disponibles son: 0=cliente, 1=propietario, 2=admin.
  Future<int?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("role");
  }

  @override
  void initState() {
    super.initState();
    fetchReservations();
    initNotifications();
    loadUserRole();
  }

  void loadUserRole() async {
    int? r = await getUserRole();
    setState(() {
      role = r;
    });
  }

  /// Obtiene todas las reservas del usuario del servidor.
  ///
  /// Agrupa las reservas por día para mostrarlas en el calendario.
  /// Actualiza el estado con las reservas ordenadas por fecha.
  Future<void> fetchReservations() async {
    try {
      final grouped = await _reservationService.getReservationsGroupedByDay();

      // Convertir a Map<DateTime, List<dynamic>> para compatibilidad
      Map<DateTime, List<dynamic>> loaded = {};
      grouped.forEach((date, reservations) {
        loaded[date] = reservations.cast<dynamic>();
      });

      setState(() {
        reservations = loaded;
      });
    } catch (e) {
      if (mounted) {
        InputDecorations.showTopSnackBarError(
          context,
          "Error al cargar reservas: $e",
        );
      }
    }
  }

  /// Obtiene las reservas para un día específico.
  ///
  /// [day] es el día para el cual se desean obtener las reservas (`DateTime`).
  ///
  /// Retorna un `List<dynamic>` con las reservas de ese día o una lista vacía.
  List<dynamic> _getReservationsForDay(DateTime day) {
    return reservations[DateTime(day.year, day.month, day.day)] ?? [];
  }

  /// Maneja la navegación cuando se presiona un ícono de la barra inferior.
  ///
  /// [index] es el índice del ícono presionado, del 0 al 4 (`int`).
  ///
  /// Navega a diferentes páginas según el índice y el rol del usuario.
  void _onItemTapped(int index) async {
    int role = await getUserRole() ?? 0;

    // Aquí puedes poner la acción de cada icono
    switch (index) {
      case 0:
        print("Calendario pulsado");
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => NotificationPage()),
        );
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );
        break;
    }
  }

  Future<int> getUnreadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("unread_notifications") ?? 0;
  }

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
      // BARRA INFERIOR
      bottomNavigationBar: InputDecorations.mainBottomNavBar(
        context: context,
        currentIndex: 0,
        owner: role == 1,
        onTap: _onItemTapped,
        unreadNotifications: unread,
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 90),

          Text(
            'Mis reservas',
            style: TextStyle(
              fontSize: 33,
              color: Color.fromARGB(255, 200, 156, 125),
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Revisa tus reservas ya creadas o solicita alguna nueva',
            style: TextStyle(
              fontSize: 14,
              color: Color.fromARGB(255, 200, 156, 125),
            ),
          ),

          SizedBox(height: 70),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color.fromARGB(
                  255,
                  30,
                  30,
                  30,
                ), // ligeramente distinto del fondo
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
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

                  // Abrir la vista detallada del día
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DayDetailPage(initialDate: selectedDay),
                    ),
                  ).then((_) {
                    // 🔁 Se ejecuta cuando vuelves
                    initNotifications();
                    fetchReservations();
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
                  leftChevronIcon: Icon(
                    Icons.chevron_left,
                    color: primaryColor,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    color: primaryColor,
                  ),
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}
