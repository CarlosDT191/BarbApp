import 'package:flutter/material.dart';

class TimelineHour extends StatelessWidget {
  final int hour;
  final double height;
  final VoidCallback? onTap;

  const TimelineHour({
    super.key,
    required this.hour,
    this.height = 60.0,
    this.onTap,
  });

  /// Formatea un número de hora en formato HH:00.
  ///
  /// [hour] es la hora en formato 0-23 (`int`).
  ///
  /// Retorna un `String` con la hora formateada (ej: "14:00").
  String _formatHour(int hour) {
    return '${hour.toString().padLeft(2, '0')}:00';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey[800]!,
              width: 1.0,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hora a la izquierda
            SizedBox(
              width: 60,
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0, right: 8.0),
                child: Text(
                  _formatHour(hour),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ),
            // Área de contenido
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Container(
                  // Placeholder para eventos
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
