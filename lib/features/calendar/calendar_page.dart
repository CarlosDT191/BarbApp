import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/home/home_page_client.dart';
import 'package:flutter_application_1/features/home/home_page_owner.dart';
import 'package:flutter_application_1/features/favorites/favorites.dart';
import 'package:flutter_application_1/features/notifications/notification_page.dart';
import 'package:flutter_application_1/features/profile/profile_page.dart';
import 'package:flutter_application_1/features/business/owner_business_page.dart';
import 'package:flutter_application_1/features/calendar/pages/day_detail_page.dart';
import 'package:flutter_application_1/features/calendar/models/calendar_entry.dart';
import 'package:flutter_application_1/models/reservation.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_application_1/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/models/decorations.dart';
import 'package:flutter_application_1/services/reservation_service.dart';
import 'package:flutter_application_1/services/google_calendar_service.dart';

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
  CalendarOwnerFilter _ownerFilter = CalendarOwnerFilter.all;
  bool _isExporting = false;

  Map<DateTime, List<CalendarEntry>> _calendarEntries = {};
  final ReservationService _reservationService = ReservationService();

  final primaryColor = reservationPrimaryColor;
  final appointmentColor = appointmentPrimaryColor;
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
    initNotifications();
    loadUserRole();
  }

  void loadUserRole() async {
    int? r = await getUserRole();
    if (!mounted) {
      return;
    }
    setState(() {
      role = r;
    });
    await fetchCalendarEntries();
  }

  /// Obtiene todas las reservas del usuario del servidor.
  ///
  /// Agrupa las reservas por día para mostrarlas en el calendario.
  /// Actualiza el estado con las reservas ordenadas por fecha.
  Future<void> fetchCalendarEntries() async {
    try {
      final currentRole = role ?? 0;
      final merged = <DateTime, List<CalendarEntry>>{};

      if (currentRole == 1) {
        final reservations = await _reservationService
            .getReservationsGroupedByDay();
        final appointments = await _reservationService
            .getAppointmentsGroupedByDay();
        _mergeEntries(merged, reservations, CalendarEntryType.reservation);
        _mergeEntries(merged, appointments, CalendarEntryType.appointment);
      } else {
        final reservations = await _reservationService
            .getReservationsGroupedByDay();
        _mergeEntries(merged, reservations, CalendarEntryType.reservation);
      }

      _sortEntries(merged);

      if (!mounted) {
        return;
      }

      setState(() {
        _calendarEntries = merged;
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
  /// Retorna un `List<CalendarEntry>` con las reservas de ese día o una lista vacía.
  List<CalendarEntry> _getEntriesForDay(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    final entries = _calendarEntries[normalized] ?? [];
    return _filterEntries(entries);
  }

  List<CalendarEntry> _filterEntries(List<CalendarEntry> entries) {
    if (role != 1) {
      return entries;
    }

    switch (_ownerFilter) {
      case CalendarOwnerFilter.reservations:
        return entries
            .where((entry) => entry.type == CalendarEntryType.reservation)
            .toList();
      case CalendarOwnerFilter.appointments:
        return entries
            .where((entry) => entry.type == CalendarEntryType.appointment)
            .toList();
      case CalendarOwnerFilter.all:
      default:
        return entries;
    }
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

  Future<void> _exportToGoogleCalendar() async {
    if (_isExporting) {
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      final currentRole = role ?? 0;
      final reservations = await _reservationService.getMyReservations();
      final allEvents = <String, Reservation>{};

      for (final reservation in reservations) {
        allEvents[reservation.id] = reservation;
      }

      if (currentRole == 1) {
        final appointments = await _reservationService.getMyAppointments();
        for (final appointment in appointments) {
          allEvents[appointment.id] = appointment;
        }
      }

      final exportList = allEvents.values.toList(growable: false);
      if (exportList.isEmpty) {
        InputDecorations.showTopSnackBarWarning(
          context,
          'No hay eventos para exportar.',
        );
        return;
      }

      final calendarService = GoogleCalendarService();
      final createdCount = await calendarService.exportReservations(exportList);

      if (!mounted) {
        return;
      }

      InputDecorations.showTopSnackBarSuccess(
        context,
        'Se exportaron $createdCount eventos a Google Calendar.',
      );
    } catch (e) {
      if (mounted) {
        InputDecorations.showTopSnackBarError(
          context,
          'No se pudieron exportar los eventos: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Widget _buildOwnerFilter() {
    final isSelected = [
      _ownerFilter == CalendarOwnerFilter.all,
      _ownerFilter == CalendarOwnerFilter.reservations,
      _ownerFilter == CalendarOwnerFilter.appointments,
    ];

    return ToggleButtons(
      isSelected: isSelected,
      onPressed: (index) {
        setState(() {
          _ownerFilter = CalendarOwnerFilter.values[index];
        });
      },
      borderRadius: BorderRadius.circular(18),
      color: textColor.withOpacity(0.7),
      selectedColor: textColor,
      fillColor: primaryColor.withOpacity(0.2),
      borderColor: primaryColor.withOpacity(0.3),
      selectedBorderColor: primaryColor,
      constraints: const BoxConstraints(minHeight: 36),
      children: const [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text('Todas'),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text('Reservas'),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text('Citas'),
        ),
      ],
    );
  }

  Color _colorForEntryType(CalendarEntryType type) {
    return type == CalendarEntryType.appointment
        ? appointmentColor
        : primaryColor;
  }

  void _mergeEntries(
    Map<DateTime, List<CalendarEntry>> target,
    Map<DateTime, List<Reservation>> source,
    CalendarEntryType type,
  ) {
    source.forEach((date, reservations) {
      final normalized = DateTime(date.year, date.month, date.day);
      target.putIfAbsent(normalized, () => []);
      target[normalized]!.addAll(
        reservations.map(
          (reservation) => CalendarEntry(reservation: reservation, type: type),
        ),
      );
    });
  }

  void _sortEntries(Map<DateTime, List<CalendarEntry>> entries) {
    entries.forEach((date, items) {
      items.sort((a, b) {
        final aMinutes =
            (a.reservation.startHour * 60) + a.reservation.startMinute;
        final bMinutes =
            (b.reservation.startHour * 60) + b.reservation.startMinute;
        return aMinutes.compareTo(bMinutes);
      });
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

      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 30),

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

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 24),
          if (role == 1) ...[
            _buildOwnerFilter(),
            const SizedBox(height: 24),
          ] else ...[
            const SizedBox(height: 46),
          ],

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
                      builder: (context) => DayDetailPage(
                        initialDate: selectedDay,
                        ownerView: role == 1,
                        ownerFilter: _ownerFilter,
                      ),
                    ),
                  ).then((_) {
                    // 🔁 Se ejecuta cuando vuelves
                    initNotifications();
                    fetchCalendarEntries();
                  });
                },

                eventLoader: (day) {
                  return _getEntriesForDay(day);
                },

                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    if (events.isEmpty) {
                      return null;
                    }

                    final entries = events.cast<CalendarEntry>();
                    final types = entries
                        .map((entry) => entry.type)
                        .toSet()
                        .toList();

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: types.map((type) {
                        return Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: _colorForEntryType(type),
                            shape: BoxShape.circle,
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

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

                  outsideTextStyle: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isExporting ? null : _exportToGoogleCalendar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 200, 156, 125),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: const BorderSide(color: Colors.white, width: 1.5),
                  ),
                ),
                icon: _isExporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.calendar_month),
                label: Text(
                  _isExporting
                      ? 'Exportando eventos...'
                      : 'Exportar eventos a Google Calendar',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
