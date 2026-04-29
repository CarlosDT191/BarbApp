import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/reservation.dart';
import 'package:flutter_application_1/services/reservation_service.dart';
import 'package:flutter_application_1/features/calendar/widgets/day_timeline_view.dart';
import 'package:flutter_application_1/features/reservations/reservation_flow_page.dart';
import 'package:flutter_application_1/models/decorations.dart';
import 'package:intl/intl.dart';

class DayDetailPage extends StatefulWidget {
  final DateTime initialDate;
  final bool ownerView;

  const DayDetailPage({
    super.key,
    required this.initialDate,
    this.ownerView = false,
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
    _loadReservations();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Carga todas las reservas agrupadas por día
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
        InputDecorations.showTopSnackBarError(context, "Error al cargar reservas: $e");
      }
      setState(() => _isLoading = false);
    }
  }

  /// Obtiene las reservas para un día específico
  List<Reservation> _getReservationsForDay(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return _cachedReservations[normalized] ?? [];
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

    if (!_cachedReservations.containsKey(normalized)) {
      _cachedReservations[normalized] = [];
    }

    _cachedReservations[normalized]!.add(createdReservation);
    _cachedReservations[normalized]!.sort((a, b) {
      final aMinutes = (a.startHour * 60) + a.startMinute;
      final bMinutes = (b.startHour * 60) + b.startMinute;
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
      _cachedReservations[normalized]?.removeWhere(
        (res) => res.id == reservationId,
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
          final dayReservations = _getReservationsForDay(normalizedDate);

          return DayTimelineView(
            date: normalizedDate,
            reservations: dayReservations,
            isOwnerView: widget.ownerView,
            eventColor: widget.ownerView
                ? const Color.fromARGB(255, 215, 145, 50)
                : const Color.fromARGB(255, 200, 156, 125),
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
}
