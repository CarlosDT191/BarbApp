import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/reservation.dart';

class EventBlock extends StatelessWidget {
  final Reservation reservation;
  final double hourHeight;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const EventBlock({
    super.key,
    required this.reservation,
    required this.hourHeight,
    this.onTap,
    this.onDelete,
  });

  /// Calcula la posición vertical del evento dentro de la hora
  double get topPosition {
    return (reservation.startMinute / 60) * hourHeight;
  }

  /// Calcula la altura del evento basado en su duración
  double get blockHeight {
    final minutesFraction = reservation.durationMinutes / 60;
    return minutesFraction * hourHeight;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: topPosition,
      left: 60,
      right: 8,
      height: blockHeight.clamp(30.0, double.infinity),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onDelete,
        child: Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 200, 156, 125),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Hora del evento
              Text(
                '${reservation.time}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              // Nombre del local
              Expanded(
                child: Text(
                  reservation.localName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                    overflow: TextOverflow.ellipsis,
                  ),
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
