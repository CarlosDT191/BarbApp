import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/calendar/models/calendar_entry.dart';
import 'package:flutter_application_1/models/reservation.dart';
import 'package:flutter_application_1/services/reservation_service.dart';
import 'package:flutter_application_1/features/calendar/widgets/day_timeline_view.dart';
import 'package:flutter_application_1/features/reservations/reservation_flow_page.dart';
import 'package:flutter_application_1/models/decorations.dart';
import 'package:intl/intl.dart';

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
    _pageController = PageController(
      initialPage: _initialPage,
    );
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
        final reservations = await _reservationService.getReservationsGroupedByDay();
        final appointments = await _reservationService.getAppointmentsGroupedByDay();
        _mergeEntries(merged, reservations, CalendarEntryType.reservation);
        _mergeEntries(merged, appointments, CalendarEntryType.appointment);
      } else {
        final reservations = await _reservationService.getReservationsGroupedByDay();
        _mergeEntries(merged, reservations, CalendarEntryType.reservation);
      }

      _sortEntries(merged);
      setState(() {
        _cachedEntries = merged;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        InputDecorations.showTopSnackBarError(context, "Error al cargar reservas: $e");
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

  /// Navega al día anterior
  void _previousDay() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Navega al día siguiente
  void _nextDay() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _openReservationFlow({
    DateTime? date,
    String? time,
  }) async {
    final initialDate = date ?? _displayedDate;
    final createdReservation = await Navigator.push<Reservation>(
      context,
      MaterialPageRoute(
        builder: (_) => ReservationFlowPage(
          initialDate: initialDate,
          initialTime: time,
        ),
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
      final aMinutes = (a.reservation.startHour * 60) + a.reservation.startMinute;
      final bMinutes = (b.reservation.startHour * 60) + b.reservation.startMinute;
      return aMinutes.compareTo(bMinutes);
    });

    setState(() {});
  }

  /// Elimina una reserva
  Future<void> _deleteReservation(String reservationId) async {
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

      if (mounted) {
        InputDecorations.showTopSnackBarInfo(context, "Reserva eliminada");
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

  @override
  Widget build(BuildContext context) {
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
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
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
            _displayedDate = DateTime(
              newDate.year,
              newDate.month,
              newDate.day,
            );
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
              final formattedHour = hour.toString().padLeft(2, '0');
              _openReservationFlow(
                date: normalizedDate,
                time: '$formattedHour:00',
              );
            },
            onDeleteReservation: _deleteReservation,
          );
        },
      ),
      // Botón flotante para crear evento rápido
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openReservationFlow(date: _displayedDate),
        backgroundColor: const Color.fromARGB(255, 200, 156, 125),
        foregroundColor: Colors.white,
        tooltip: 'Nueva reserva',
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
        reservations.map((reservation) => CalendarEntry(
          reservation: reservation,
          type: type,
        )),
      );
    });
  }

  void _sortEntries(Map<DateTime, List<CalendarEntry>> entries) {
    entries.forEach((date, items) {
      items.sort((a, b) {
        final aMinutes = (a.reservation.startHour * 60)
            + a.reservation.startMinute;
        final bMinutes = (b.reservation.startHour * 60)
            + b.reservation.startMinute;
        return aMinutes.compareTo(bMinutes);
      });
    });
  }
}
