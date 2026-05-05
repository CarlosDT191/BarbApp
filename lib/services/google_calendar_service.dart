import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:flutter_application_1/models/reservation.dart';

class GoogleCalendarService {
  GoogleCalendarService({GoogleSignIn? googleSignIn})
    : _googleSignIn =
          googleSignIn ??
          GoogleSignIn(scopes: [calendar.CalendarApi.calendarEventsScope]);

  final GoogleSignIn _googleSignIn;

  Future<int> exportReservations(List<Reservation> reservations) async {
    if (reservations.isEmpty) {
      return 0;
    }

    final account =
        _googleSignIn.currentUser ??
        await _googleSignIn.signInSilently() ??
        await _googleSignIn.signIn();

    if (account == null) {
      throw Exception('Inicio de sesion cancelado');
    }

    final client = await _googleSignIn.authenticatedClient();
    if (client == null) {
      throw Exception('No se pudo autenticar con Google Calendar');
    }

    final api = calendar.CalendarApi(client);
    var created = 0;

    try {
      for (final reservation in reservations) {
        final start = DateTime(
          reservation.date.year,
          reservation.date.month,
          reservation.date.day,
          reservation.startHour,
          reservation.startMinute,
        );
        final end = start.add(Duration(minutes: reservation.durationMinutes));
        final summary =
            '${reservation.serviceDisplayName} - ${reservation.businessDisplayName}';

        final description = [
          if (reservation.clientName.isNotEmpty)
            'Cliente: ${reservation.clientDisplayName}',
          if (reservation.serviceType.isNotEmpty)
            'Tipo: ${reservation.serviceType}',
          if (reservation.servicePrice != null)
            'Precio: ${reservation.servicePrice!.toStringAsFixed(2)}€',
        ].join('\n');

        final event = calendar.Event(
          summary: summary,
          description: description.isEmpty ? null : description,
          start: calendar.EventDateTime(dateTime: start),
          end: calendar.EventDateTime(dateTime: end),
        );

        await api.events.insert(event, 'primary');
        created += 1;
      }
    } finally {
      client.close();
    }

    return created;
  }
}
