import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/reservation.dart';
import 'package:flutter_application_1/features/calendar/models/calendar_entry.dart';
import 'package:flutter_application_1/features/calendar/widgets/timeline_hour.dart';
import 'package:flutter_application_1/features/calendar/widgets/event_block.dart';

class DayTimelineView extends StatefulWidget {
  final DateTime date;
  final List<CalendarEntry> entries;
  final VoidCallback? onHourTap;
  final Function(int hour)? onHourSelected;
  final Function(String reservationId)? onDeleteReservation;
  final Color reservationColor;
  final Color appointmentColor;
  final double hourHeight;

  const DayTimelineView({
    super.key,
    required this.date,
    required this.entries,
    this.onHourTap,
    this.onHourSelected,
    this.onDeleteReservation,
    this.reservationColor = reservationPrimaryColor,
    this.appointmentColor = appointmentPrimaryColor,
    this.hourHeight = 120.0,
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
    final eventLayouts = _buildEventLayouts(widget.entries);

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 100),
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
          LayoutBuilder(
            builder: (context, constraints) {
              const leftInset = 70.0;
              const rightInset = 8.0;
              final availableWidth =
                  (constraints.maxWidth - leftInset - rightInset)
                      .clamp(0.0, double.infinity);

              return SizedBox(
                height: 24 * widget.hourHeight,
                child: Stack(
                  children: eventLayouts
                      .map(
                        (layout) {
                          final columnCount =
                              layout.columnCount > 0 ? layout.columnCount : 1;
                          final columnWidth = availableWidth / columnCount;
                          final left = leftInset + (columnWidth * layout.columnIndex);

                          return EventBlock(
                            reservation: layout.entry.reservation,
                            hourHeight: widget.hourHeight,
                            isOwnerView: layout.entry.isAppointment,
                            backgroundColor: layout.entry.isAppointment
                                ? widget.appointmentColor
                                : widget.reservationColor,
                            left: left,
                            width: columnWidth,
                            onTap: () {
                              _showReservationDetails(layout.entry);
                            },
                            onDelete: () {
                              _confirmDeleteReservation(layout.entry.reservation);
                            },
                          );
                        },
                      )
                      .toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  List<_EventLayout> _buildEventLayouts(List<CalendarEntry> entries) {
    final grouped = <String, List<CalendarEntry>>{};

    for (final entry in entries) {
      final key = entry.reservation.time.trim();
      grouped.putIfAbsent(key, () => []).add(entry);
    }

    final layouts = <_EventLayout>[];
    for (final group in grouped.values) {
      for (var index = 0; index < group.length; index += 1) {
        layouts.add(
          _EventLayout(
            entry: group[index],
            columnIndex: index,
            columnCount: group.length,
          ),
        );
      }
    }

    return layouts;
  }

  /// Muestra detalles de una reserva
  void _showReservationDetails(CalendarEntry entry) {
    final reservation = entry.reservation;
    final isAppointment = entry.isAppointment;
    final details = <Map<String, String>>[
      {'Tipo:': isAppointment ? 'Cita' : 'Reserva'},
      {'Local:': reservation.businessDisplayName},
      {'Servicio:': reservation.serviceDisplayName},
      {'Hora:': reservation.time},
      {'Duración:': '${reservation.durationMinutes} minutos'},
    ];

    if (isAppointment) {
      details.insert(2, {'Cliente:': reservation.clientDisplayName});
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color.fromARGB(255, 35, 35, 35),
      builder: (context) => Padding(
        padding: const EdgeInsets.only(bottom: 70, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAppointment ? 'Detalles de la Cita' : 'Detalles de la Reserva',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ...details.map((row) {
              final entry = row.entries.first;
              return _detailRow(entry.key, entry.value);
            }).toList(),
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

class _EventLayout {
  final CalendarEntry entry;
  final int columnIndex;
  final int columnCount;

  const _EventLayout({
    required this.entry,
    required this.columnIndex,
    required this.columnCount,
  });
}
