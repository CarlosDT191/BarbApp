import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/reservation.dart';

class EventBlock extends StatelessWidget {
  final Reservation reservation;
  final double hourHeight;
  final bool isOwnerView;
  final Color backgroundColor;
  final double? left;
  final double? width;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const EventBlock({
    super.key,
    required this.reservation,
    required this.hourHeight,
    this.isOwnerView = false,
    this.backgroundColor = const Color.fromARGB(255, 200, 156, 125),
    this.left,
    this.width,
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
    final title = isOwnerView
        ? reservation.serviceDisplayName
        : reservation.businessDisplayName;
    final subtitle = isOwnerView
        ? reservation.clientDisplayName
        : reservation.serviceDisplayName;
    final parts = reservation.time.split(':');

    final startDateTime = DateTime(
      reservation.date.year,
      reservation.date.month,
      reservation.date.day,
      int.parse(parts[0]), // horas
      int.parse(parts[1]), // minutos
    );

    final endDateTime = startDateTime.add(
      Duration(minutes: reservation.durationMinutes),
    );

    final formattedEnd =
    "${endDateTime.hour.toString().padLeft(2, '0')}:${endDateTime.minute.toString().padLeft(2, '0')}";

    final leftPosition = left ?? 70;
    final rightPosition = width == null ? 8.0 : null;

    return Positioned(
      top: topPosition,
      left: leftPosition,
      right: rightPosition,
      width: width,
      height: blockHeight.clamp(30.0, double.infinity),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onDelete,
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
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
                '${reservation.time} - ${formattedEnd}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (reservation.durationMinutes > 20) ... [
                const SizedBox(height: 1),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    overflow: TextOverflow.ellipsis,
                  ),
                  maxLines: 1,
                ),
              ],
              if (reservation.durationMinutes > 35) ... [
                const SizedBox(height: 2),
                Expanded(
                  child: Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 2,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
