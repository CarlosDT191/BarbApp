import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/reservation.dart';

const Color reservationPrimaryColor = Color.fromARGB(255, 200, 156, 125);
const Color appointmentPrimaryColor = Color.fromARGB(255, 215, 145, 50);

enum CalendarEntryType { reservation, appointment }

enum CalendarOwnerFilter { all, reservations, appointments }

class CalendarEntry {
  final Reservation reservation;
  final CalendarEntryType type;

  const CalendarEntry({
    required this.reservation,
    required this.type,
  });

  bool get isAppointment => type == CalendarEntryType.appointment;
}
