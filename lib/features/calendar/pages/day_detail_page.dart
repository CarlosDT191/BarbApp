import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/reservation.dart';
import 'package:flutter_application_1/services/reservation_service.dart';
import 'package:flutter_application_1/features/calendar/widgets/day_timeline_view.dart';
import 'package:flutter_application_1/features/calendar/widgets/create_event_modal.dart';
import 'package:flutter_application_1/models/decorations.dart';
import 'package:intl/intl.dart';

class DayDetailPage extends StatefulWidget {
  final DateTime initialDate;

  const DayDetailPage({
    super.key,
    required this.initialDate,
  });

  @override
  State<DayDetailPage> createState() => _DayDetailPageState();
}

class _DayDetailPageState extends State<DayDetailPage> {
  late PageController _pageController;
  late DateTime _displayedDate;
  final ReservationService _reservationService = ReservationService();
  Map<DateTime, List<Reservation>> _cachedReservations = {};
  bool _isLoading = true;
  int? _selectedHourForCreation;

  @override
  void initState() {
    super.initState();
    _displayedDate = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
    _pageController = PageController(
      initialPage: 0,
    );
    _loadReservations();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Carga todas las reservaciones agrupadas por día
  Future<void> _loadReservations() async {
    try {
      setState(() => _isLoading = true);
      final grouped = await _reservationService.getReservationsGroupedByDay();
      setState(() {
        _cachedReservations = grouped;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar reservaciones: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  /// Obtiene las reservaciones para un día específico
  List<Reservation> _getReservationsForDay(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return _cachedReservations[normalized] ?? [];
  }

  /// Navega al día anterior
  void _previousDay() {
    final previousDate = _displayedDate.subtract(const Duration(days: 1));
    _displayedDate = previousDate;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Navega al día siguiente
  void _nextDay() {
    final nextDate = _displayedDate.add(const Duration(days: 1));
    _displayedDate = nextDate;
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Abre el modal para crear un evento
  void _openCreateEventModal(DateTime date, [int? suggestedHour]) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 23, 23, 23),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: CreateEventModal(
          selectedDate: date,
          suggestedHour: suggestedHour,
          onEventCreated: _createReservation,
        ),
      ),
    );
  }

  /// Crea una nueva reservación
  Future<void> _createReservation(
    DateTime date,
    String time,
    String localName,
  ) async {
    try {
      final newReservation = await _reservationService.createReservation(
        date: date,
        time: time,
        localName: localName,
      );

      // Actualizar caché local
      final normalized = DateTime(date.year, date.month, date.day);
      if (!_cachedReservations.containsKey(normalized)) {
        _cachedReservations[normalized] = [];
      }
      _cachedReservations[normalized]!.add(newReservation);
      _cachedReservations[normalized]!
          .sort((a, b) => a.startHour.compareTo(b.startHour));

      setState(() {});

      if (mounted) {
        InputDecorations.showTopSnackBarSuccess(context, "Reservación creada exitosamente");
      }
    } catch (e) {
      if (mounted) {
        InputDecorations.showTopSnackBarError(context, "Error al crear la reserva: $e");
      }
    }
  }

  /// Elimina una reservación
  Future<void> _deleteReservation(String reservationId) async {
    try {
      await _reservationService.deleteReservation(reservationId);

      // Actualizar caché local
      final normalized = DateTime(
        _displayedDate.year,
        _displayedDate.month,
        _displayedDate.day,
      );
      _cachedReservations[normalized]?.removeWhere(
        (res) => res.id == reservationId,
      );

      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reservación eliminada'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Formatea la fecha para el AppBar
  String _formatDateForAppBar(DateTime date) {
    return DateFormat('EEEE, d MMMM', 'es_ES').format(date);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _cachedReservations.isEmpty) {
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
        actions: [
          // Botón anterior
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: _previousDay,
            tooltip: 'Día anterior',
          ),
          // Botón siguiente
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: _nextDay,
            tooltip: 'Día siguiente',
          ),
        ],
      ),
      backgroundColor: const Color.fromARGB(255, 23, 23, 23),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          // Calcular la nueva fecha basada en el índice
          // El índice 0 es today, -1 es yesterday, +1 es tomorrow, etc.
          final daysOffset = index;
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
          final pageDate = widget.initialDate.add(Duration(days: index));
          final normalizedDate = DateTime(
            pageDate.year,
            pageDate.month,
            pageDate.day,
          );
          final dayReservations = _getReservationsForDay(normalizedDate);

          return DayTimelineView(
            date: normalizedDate,
            reservations: dayReservations,
            onHourSelected: (hour) {
              _selectedHourForCreation = hour;
              _openCreateEventModal(normalizedDate, hour);
            },
            onDeleteReservation: _deleteReservation,
          );
        },
      ),
      // Botón flotante para crear evento rápido
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreateEventModal(_displayedDate),
        backgroundColor: const Color.fromARGB(255, 200, 156, 125),
        foregroundColor: Colors.black,
        tooltip: 'Nueva reservación',
        child: const Icon(Icons.add),
      ),
    );
  }
}
