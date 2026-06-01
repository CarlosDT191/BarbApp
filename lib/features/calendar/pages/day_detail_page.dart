import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/calendar/models/calendar_entry.dart';
import 'package:flutter_application_1/models/reservation.dart';
import 'package:flutter_application_1/services/reservation_service.dart';
import 'package:flutter_application_1/features/calendar/widgets/day_timeline_view.dart';
import 'package:flutter_application_1/features/reservations/reservation_flow_page.dart';
import 'package:flutter_application_1/features/reservations/appointment_flow_page.dart';
import 'package:flutter_application_1/models/decorations.dart';
import 'package:flutter_application_1/services/user_service.dart';
import 'package:intl/intl.dart';

enum _CreateAction { reservation, appointment }

class DayDetailPage extends StatefulWidget {
  final DateTime initialDate;
  final bool ownerView;
  final CalendarOwnerFilter ownerFilter;

  const DayDetailPage({
    super.key,
    required this.initialDate,
    this.ownerView = false,
    this.ownerFilter = CalendarOwnerFilter.all,
  });

  @override
  State<DayDetailPage> createState() => _DayDetailPageState();
}

class _DayDetailPageState extends State<DayDetailPage> {
  late PageController _pageController;
  late DateTime _displayedDate;
  final ReservationService _reservationService = ReservationService();
  Map<DateTime, List<CalendarEntry>> _cachedEntries = {};
  bool _isLoading = true;
  static const int _initialPage = 10000;

  @override
  void initState() {
    super.initState();
    _displayedDate = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
    _pageController = PageController(initialPage: _initialPage);
    _loadEntries();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Carga todas las reservas agrupadas por día
  Future<void> _loadEntries() async {
    try {
      setState(() => _isLoading = true);
      final merged = <DateTime, List<CalendarEntry>>{};
      if (widget.ownerView) {
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
      setState(() {
        _cachedEntries = merged;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        InputDecorations.showTopSnackBarError(
          context,
          "Error al cargar reservas: $e",
        );
      }
      setState(() => _isLoading = false);
    }
  }

  /// Obtiene las reservas para un día específico
  List<CalendarEntry> _getEntriesForDay(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final entries = _cachedEntries[normalized] ?? [];
    return _filterEntries(entries);
  }

  List<CalendarEntry> _filterEntries(List<CalendarEntry> entries) {
    if (!widget.ownerView) {
      return entries;
    }

    switch (widget.ownerFilter) {
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

  Future<void> _openReservationFlow({DateTime? date, String? time}) async {
    final initialDate = date ?? _displayedDate;
    final createdReservation = await Navigator.push<Reservation>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ReservationFlowPage(initialDate: initialDate, initialTime: time),
      ),
    );

    if (createdReservation == null || !mounted) {
      return;
    }

    final normalized = DateTime(
      createdReservation.date.year,
      createdReservation.date.month,
      createdReservation.date.day,
    );

    if (!_cachedEntries.containsKey(normalized)) {
      _cachedEntries[normalized] = [];
    }

    _cachedEntries[normalized]!.add(
      CalendarEntry(
        reservation: createdReservation,
        type: CalendarEntryType.reservation,
      ),
    );
    _cachedEntries[normalized]!.sort((a, b) {
      final aMinutes =
          (a.reservation.startHour * 60) + a.reservation.startMinute;
      final bMinutes =
          (b.reservation.startHour * 60) + b.reservation.startMinute;
      return aMinutes.compareTo(bMinutes);
    });

    await UserService.updateUnreadNotifications();

    setState(() {});
  }

  Future<void> _openAppointmentFlow({DateTime? date, String? time}) async {
    final initialDate = date ?? _displayedDate;
    final createdAppointment = await Navigator.push<Reservation>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AppointmentFlowPage(initialDate: initialDate, initialTime: time),
      ),
    );

    if (createdAppointment == null || !mounted) {
      return;
    }

    final normalized = DateTime(
      createdAppointment.date.year,
      createdAppointment.date.month,
      createdAppointment.date.day,
    );

    if (!_cachedEntries.containsKey(normalized)) {
      _cachedEntries[normalized] = [];
    }

    _cachedEntries[normalized]!.add(
      CalendarEntry(
        reservation: createdAppointment,
        type: CalendarEntryType.appointment,
      ),
    );
    _cachedEntries[normalized]!.sort((a, b) {
      final aMinutes =
          (a.reservation.startHour * 60) + a.reservation.startMinute;
      final bMinutes =
          (b.reservation.startHour * 60) + b.reservation.startMinute;
      return aMinutes.compareTo(bMinutes);
    });

    await UserService.updateUnreadNotifications();

    setState(() {});
  }

  Future<void> _showCreateOptions({DateTime? date, String? time}) async {
    final action = await showModalBottomSheet<_CreateAction>(
      context: context,
      backgroundColor: const Color.fromARGB(255, 30, 30, 30),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Crear evento',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  splashColor: const Color.fromARGB(120, 200, 156, 125),
                  highlightColor: const Color.fromARGB(80, 200, 156, 125),
                  onTap: () => Navigator.pop(context, _CreateAction.reservation),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 38, 38, 38),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color.fromARGB(255, 70, 70, 70),
                        width: 1,
                      ),
                    ),
                    child: const ListTile(
                      leading: Icon(
                        Icons.event_available,
                        color: Color.fromARGB(255, 200, 156, 125),
                      ),
                      title: Text(
                        'Crear nueva reserva',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        'Usa el flujo de reserva actual.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 🔹 Opción 2
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  splashColor: const Color.fromARGB(120, 200, 156, 125),
                  highlightColor: const Color.fromARGB(80, 200, 156, 125),
                  onTap: () => Navigator.pop(context, _CreateAction.appointment),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 38, 38, 38),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color.fromARGB(255, 70, 70, 70),
                        width: 1,
                      ),
                    ),
                    child: const ListTile(
                      leading: Icon(
                        Icons.work_outline,
                        color: Color.fromARGB(255, 200, 156, 125),
                      ),
                      title: Text(
                        'Crear nueva cita para mis negocios',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        'Registra una cita manualmente.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );

    if (!mounted || action == null) {
      return;
    }

    if (action == _CreateAction.reservation) {
      await _openReservationFlow(date: date, time: time);
    } else {
      await _openAppointmentFlow(date: date, time: time);
    }
  }

  /// Elimina una reserva
  Future<void> _deleteReservation(
    String reservationId,
    bool isAppointment,
  ) async {
    try {
      await _reservationService.deleteReservation(reservationId);

      // Actualizar caché local
      final normalized = DateTime(
        _displayedDate.year,
        _displayedDate.month,
        _displayedDate.day,
      );
      _cachedEntries[normalized]?.removeWhere(
        (entry) => entry.reservation.id == reservationId,
      );

      setState(() {});

      await UserService.updateUnreadNotifications();

      if (mounted) {
        final successMessage = isAppointment
            ? "Eliminación de cita confirmada"
            : "Eliminación de reserva confirmada";
        InputDecorations.showTopSnackBarInfo(context, successMessage);
      }
    } catch (e) {
      if (mounted) {
        InputDecorations.showTopSnackBarError(context, "Error al eliminar: $e");
      }
    }
  }

  /// Formatea la fecha para el AppBar
  String _formatDateForAppBar(DateTime date) {
    return DateFormat('EEEE, d MMMM', 'es_ES').format(date);
  }

  bool _isPastDay(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.isBefore(today);
  }

  @override
  Widget build(BuildContext context) {
    final isPastDay = _isPastDay(_displayedDate);
    if (_isLoading && _cachedEntries.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          foregroundColor: Colors.white,
          backgroundColor: const Color.fromARGB(255, 23, 23, 23),
          title: const Text('Cargando...'),
        ),
        backgroundColor: const Color.fromARGB(255, 23, 23, 23),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color.fromARGB(255, 200, 156, 125),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: const Color.fromARGB(255, 23, 23, 23),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatDateForAppBar(_displayedDate),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),

      backgroundColor: const Color.fromARGB(255, 23, 23, 23),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          final daysOffset = index - _initialPage;
          final newDate = widget.initialDate.add(Duration(days: daysOffset));

          setState(() {
            _displayedDate = DateTime(newDate.year, newDate.month, newDate.day);
          });
        },
        itemBuilder: (context, index) {
          // Calcular la fecha para esta página
          final daysOffset = index - _initialPage;
          final pageDate = widget.initialDate.add(Duration(days: daysOffset));
          final normalizedDate = DateTime(
            pageDate.year,
            pageDate.month,
            pageDate.day,
          );
          final dayEntries = _getEntriesForDay(normalizedDate);

          return DayTimelineView(
            date: normalizedDate,
            entries: dayEntries,
            onHourSelected: (hour) {
              if (_isPastDay(normalizedDate)) {
                return;
              }
              final formattedHour = hour.toString().padLeft(2, '0');
              if (widget.ownerView) {
                _showCreateOptions(
                  date: normalizedDate,
                  time: '$formattedHour:00',
                );
              } else {
                _openReservationFlow(
                  date: normalizedDate,
                  time: '$formattedHour:00',
                );
              }
            },
            onDeleteReservation: _deleteReservation,
          );
        },
      ),
      // Botón flotante para crear evento rápido
      floatingActionButton: isPastDay
          ? null
          : FloatingActionButton(
              onPressed: () {
                if (widget.ownerView) {
                  _showCreateOptions(date: _displayedDate);
                } else {
                  _openReservationFlow(date: _displayedDate);
                }
              },
              backgroundColor: const Color.fromARGB(255, 200, 156, 125),
              foregroundColor: Colors.white,
              tooltip: widget.ownerView ? 'Nuevo evento' : 'Nueva reserva',
              child: const Icon(Icons.add),
            ),
    );
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
}
