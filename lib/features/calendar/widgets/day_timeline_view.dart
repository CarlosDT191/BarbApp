import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/reservation.dart';
import 'package:flutter_application_1/features/calendar/widgets/timeline_hour.dart';
import 'package:flutter_application_1/features/calendar/widgets/event_block.dart';

class DayTimelineView extends StatefulWidget {
  final DateTime date;
  final List<Reservation> reservations;
  final VoidCallback? onHourTap;
  final Function(int hour)? onHourSelected;
  final Function(String reservationId)? onDeleteReservation;
  final double hourHeight;

  const DayTimelineView({
    super.key,
    required this.date,
    required this.reservations,
    this.onHourTap,
    this.onHourSelected,
    this.onDeleteReservation,
    this.hourHeight = 60.0,
  });

  @override
  State<DayTimelineView> createState() => _DayTimelineViewState();
}

class _DayTimelineViewState extends State<DayTimelineView> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Scroll a la hora actual al abrir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentHour();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Scroll al hora actual
  void _scrollToCurrentHour() {
    final now = DateTime.now();
    final currentHour = now.hour;
    final scrollOffset = currentHour * widget.hourHeight;

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        scrollOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Construye la timeline para un día específico
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Stack(
        children: [
          // Timeline de horas
          Column(
            children: List.generate(
              24,
              (index) => TimelineHour(
                hour: index,
                height: widget.hourHeight,
                onTap: () {
                  widget.onHourSelected?.call(index);
                  widget.onHourTap?.call();
                },
              ),
            ),
          ),

          // Eventos superpuestos
          SizedBox(
            height: 24 * widget.hourHeight,
            child: Stack(
              children: widget.reservations
                  .map(
                    (reservation) => EventBlock(
                      reservation: reservation,
                      hourHeight: widget.hourHeight,
                      onTap: () {
                        // Mostrar detalles del evento (opcional)
                        _showReservationDetails(reservation);
                      },
                      onDelete: () {
                        _confirmDeleteReservation(reservation);
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Muestra detalles de una reserva
  void _showReservationDetails(Reservation reservation) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color.fromARGB(255, 35, 35, 35),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detalles de la Reserva',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _detailRow('Local:', reservation.localName),
            _detailRow('Hora:', reservation.time),
            _detailRow(
              'Duración:',
              '${reservation.durationMinutes} minutos',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _confirmDeleteReservation(reservation);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget auxiliar para mostrar filas de detalles
  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Confirma la eliminación de una reserva
  void _confirmDeleteReservation(Reservation reservation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 35, 35, 35),
        title: const Text(
          '¿Eliminar reserva?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Se eliminará la reserva en ${reservation.localName} a las ${reservation.time}',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: const TextStyle(color: Color.fromARGB(255, 200, 156, 125))),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDeleteReservation?.call(reservation.id);
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(100, 40),
              foregroundColor: Colors.white,
              backgroundColor: Color.fromARGB(255, 30, 30, 30), // color de fondo
            ),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
