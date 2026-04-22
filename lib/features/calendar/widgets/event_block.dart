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

  /// Calcula la posición vertical del evento dentro de la fila horaria.
  ///
  /// Basado en los minutos de inicio y la altura de la hora.
  /// Retorna un `double` con la posición en píxeles desde la parte superior.
  double get topPosition {
    final totalMinutes = (reservation.startHour * 60) + reservation.startMinute;
    return (totalMinutes / 60) * hourHeight;
  }

  /// Calcula la altura del bloque del evento en píxeles.
  ///
  /// Se basa en la duración total del evento en minutos.
  /// Retorna un `double` con la altura del bloque en píxeles.
  double get blockHeight {
    final minutesFraction = reservation.durationMinutes / 60;
    return minutesFraction * hourHeight;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: topPosition,
      left: 70,
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
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              // Nombre del local
              Expanded(
                child: Text(
                  reservation.localName,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
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
