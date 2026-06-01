import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/home/home_page_client.dart';
import 'package:flutter_application_1/features/home/home_page_owner.dart';
import 'package:flutter_application_1/features/favorites/favorites.dart';
import 'package:flutter_application_1/features/calendar/calendar_page.dart';
import 'package:flutter_application_1/features/calendar/models/calendar_entry.dart';
import 'package:flutter_application_1/features/profile/profile_page.dart';
import 'package:flutter_application_1/features/business/owner_business_page.dart';
import 'package:flutter_application_1/models/reservation.dart';
import 'package:flutter_application_1/services/reservation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/models/decorations.dart';
import 'package:intl/intl.dart';

class _ReservationNotificationDetails {
  const _ReservationNotificationDetails({
    required this.title,
    this.business,
    this.service,
    this.date,
    this.time,
    this.client,
    this.servicePrice,
    this.serviceDurationMinutes,
    this.showClient = false,
  });

  final String title;
  final String? business;
  final String? service;
  final String? date;
  final String? time;
  final String? client;
  final double? servicePrice;
  final int? serviceDurationMinutes;
  final bool showClient;
}

class _NotificationVisual {
  const _NotificationVisual({required this.icon, required this.color});

  final IconData icon;
  final Color color;
}

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  int _selectedIndex = 0;
  int? role = 0;

  List<dynamic> notifications = [];
  bool isLoading = true;

  final ReservationService _reservationService = ReservationService();
  final Map<String, Reservation> _reservationsById = {};

  final primaryColor = Color.fromARGB(255, 200, 156, 125);
  final backgroundColor = Color.fromARGB(255, 23, 23, 23);
  final textColor = Colors.white;

  /// Obtiene el rol del usuario desde [SharedPreferences].
  ///
  /// Retorna un `int` con el rol del usuario o `null` si no existe.
  /// Los roles son: 0=cliente, 1=propietario, 2=admin.
  Future<int?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("role");
  }

  int get unreadCount {
    return notifications.where((n) => n["read"] == false).length;
  }

  /// Obtiene todas las notificaciones del usuario desde el backend.
  ///
  /// Realiza una solicitud HTTP al servidor y actualiza el estado
  /// con la lista completa de notificaciones del usuario autenticado.
  Future<void> fetchNotifications() async {
    final token = await getUserToken();
    final apiBaseUrl = getApiBaseUrl();

    final response = await http.get(
      Uri.parse("$apiBaseUrl/notifications"),
      headers: {"Authorization": "Bearer $token"},
    );

    final data = jsonDecode(response.body);

    if (!mounted) {
      return;
    }

    setState(() {
      notifications = data;
      isLoading = false;
    });
  }

  Future<void> _refreshNotifications() async {
    await Future.wait([
      fetchNotifications(),
      _loadReservationDetails(),
    ]);
  }

  Future<void> _loadReservationDetails() async {
    try {
      final results = await Future.wait([
        _reservationService.getMyReservations(),
        _reservationService.getMyAppointments(),
      ]);

      final reservations = <Reservation>[
        ...results[0],
        ...results[1],
      ];

      final updated = <String, Reservation>{
        for (final reservation in reservations)
          reservation.id: reservation,
      };

      if (!mounted) {
        return;
      }

      setState(() {
        _reservationsById
          ..clear()
          ..addAll(updated);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _reservationsById.clear();
      });
    }
  }

  Reservation? _reservationForNotification(dynamic notif) {
    final relatedId = notif['relatedId']?.toString().trim();
    if (relatedId == null || relatedId.isEmpty) {
      return null;
    }
    return _reservationsById[relatedId];
  }

  /// Marca una notificación como leída.
  ///
  /// [id] es el ID único de la notificación a marcar como leída (`String`).
  ///
  /// Realiza una solicitud PATCH al backend y recarga la lista de notificaciones.
  Future<void> markAsRead(String id) async {
    final token = await getUserToken();
    final apiBaseUrl = getApiBaseUrl();

    await http.patch(
      Uri.parse("$apiBaseUrl/notifications/$id/read"),
      headers: {"Authorization": "Bearer $token"},
    );

    fetchNotifications();
  }

  _ReservationNotificationDetails? _parseNotificationForItem(dynamic notif) {
    final message = notif["message"]?.toString() ?? '';
    final type = notif["type"]?.toString() ?? '';
    final lowerMessage = message.toLowerCase();
    final shouldParse =
        type == 'reservation' ||
        lowerMessage.contains('reserva') ||
        lowerMessage.contains('cita');

    if (!shouldParse) {
      return null;
    }

    final reservation = _reservationForNotification(notif);
    return _parseReservationNotification(
      message,
      reservation: reservation,
    );
  }

  _NotificationVisual _resolveNotificationVisual(
    dynamic notif,
    _ReservationNotificationDetails? parsed,
  ) {
    final type = notif["type"]?.toString() ?? '';
    if (type == 'cancel') {
      return const _NotificationVisual(
        icon: Icons.event_busy_rounded,
        color: Color.fromARGB(255, 176, 90, 90),
      );
    }

    if (parsed?.showClient == true) {
      return const _NotificationVisual(
        icon: Icons.move_to_inbox,
        color: appointmentPrimaryColor,
      );
    }

    return _NotificationVisual(
      icon: Icons.event_available_rounded,
      color: primaryColor,
    );
  }

  _ReservationNotificationDetails? _parseReservationNotification(
    String message, {
    Reservation? reservation,
  }) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    double? parsedPrice;
    int? parsedDuration;
    final priceMatch = RegExp(
      r'(\d+(?:[\.,]\d+)?)\s*(?:eur)',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (priceMatch != null) {
      parsedPrice = double.tryParse(
        priceMatch.group(1)?.replaceAll(',', '.') ?? '',
      );
    }

    final durationMatch = RegExp(
      r'(\d+)\s*min',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (durationMatch != null) {
      parsedDuration = int.tryParse(durationMatch.group(1) ?? '');
    }

    final confirmMatch = RegExp(
      r'^Reserva confirmada:\s*Has reservado en (.*?),\s*(.*?)\s+para el\s+(.*?)\s+a las\s+(.*?)[\.!]*$',
    ).firstMatch(trimmed);
    if (confirmMatch != null) {
      final details = _ReservationNotificationDetails(
        title: 'Reserva confirmada',
        business: confirmMatch.group(1)?.trim(),
        service: confirmMatch.group(2)?.trim(),
        date: confirmMatch.group(3)?.trim(),
        time: confirmMatch.group(4)?.trim(),
        servicePrice: parsedPrice,
        serviceDurationMinutes: parsedDuration,
      );
      return _withReservationDefaults(details, reservation);
    }

    final ownerMatch = RegExp(
      r'^Nueva cita:\s*(.*?)\s+ha reservado\s+(.*?)\s+\((.*?)\)\s+para el\s+(.*?)\s+a las\s+(.*?)[\.!]*$',
    ).firstMatch(trimmed);
    if (ownerMatch != null) {
      final details = _ReservationNotificationDetails(
        title: 'Nueva cita',
        client: ownerMatch.group(1)?.trim(),
        service: ownerMatch.group(2)?.trim(),
        business: ownerMatch.group(3)?.trim(),
        date: ownerMatch.group(4)?.trim(),
        time: ownerMatch.group(5)?.trim(),
        servicePrice: parsedPrice,
        serviceDurationMinutes: parsedDuration,
        showClient: true,
      );
      return _withReservationDefaults(details, reservation);
    }

    final createdMatch = RegExp(
      r'^Nueva cita creada para\s+(.*?)\s+en\s+(.*?)\s+el día\s+(.*?)\s+a las\s+(.*?)[\.!]*$',
    ).firstMatch(trimmed);
    if (createdMatch != null) {
      final details = _ReservationNotificationDetails(
        title: 'Nueva cita creada manualmente',
        client: createdMatch.group(1)?.trim(),
        business: createdMatch.group(2)?.trim(),
        date: createdMatch.group(3)?.trim(),
        time: createdMatch.group(4)?.trim(),
        servicePrice: parsedPrice,
        serviceDurationMinutes: parsedDuration,
        showClient: true,
      );
      return _withReservationDefaults(details, reservation);
    }

    final clientCancelMatch = RegExp(
      r'^Tu reserva en (.*?)\s+del\s+(.*?)\s+a las\s+(\d{1,2}:\d{2})(?:\s*[hH])?(?:[\.!]*\s*(.*))?$',
    ).firstMatch(trimmed);
    if (clientCancelMatch != null) {
      final labels = _extractBusinessAndService(
        clientCancelMatch.group(1) ?? '',
      );
      final reason = _cleanCancelReason(clientCancelMatch.group(4));
      final title = _buildClientCancelTitle(reason);

      final details = _ReservationNotificationDetails(
        title: title,
        business: labels['business'],
        service: labels['service'],
        date: clientCancelMatch.group(2)?.trim(),
        time: clientCancelMatch.group(3)?.trim(),
        servicePrice: parsedPrice,
        serviceDurationMinutes: parsedDuration,
      );
      return _withReservationDefaults(details, reservation);
    }

    final clientSelfCancelMatch = RegExp(
      r'^Has cancelado tu reserva en (.*?)\s+del\s+(.*?)\s+a las\s+(\d{1,2}:\d{2})(?:\s*[hH])?[\.!]*$',
    ).firstMatch(trimmed);
    if (clientSelfCancelMatch != null) {
      final labels = _extractBusinessAndService(
        clientSelfCancelMatch.group(1) ?? '',
      );

      final details = _ReservationNotificationDetails(
        title: 'Has cancelado tu reserva',
        business: labels['business'],
        service: labels['service'],
        date: clientSelfCancelMatch.group(2)?.trim(),
        time: clientSelfCancelMatch.group(3)?.trim(),
        servicePrice: parsedPrice,
        serviceDurationMinutes: parsedDuration,
      );
      return _withReservationDefaults(details, reservation);
    }

    final ownerCancelMatch = RegExp(
      r'^La reserva de (.*?)\s+en\s+(.*?)\s+del\s+(.*?)\s+a las\s+(\d{1,2}:\d{2})(?:\s*[hH])?(?:[\.!]*\s*(.*))?$',
    ).firstMatch(trimmed);
    if (ownerCancelMatch != null) {
      final labels = _extractBusinessAndService(
        ownerCancelMatch.group(2) ?? '',
      );
      final reason = _cleanCancelReason(ownerCancelMatch.group(5));
      final title = _buildOwnerCancelTitle(reason);

      final details = _ReservationNotificationDetails(
        title: title,
        client: ownerCancelMatch.group(1)?.trim(),
        business: labels['business'],
        service: labels['service'],
        date: ownerCancelMatch.group(3)?.trim(),
        time: ownerCancelMatch.group(4)?.trim(),
        servicePrice: parsedPrice,
        serviceDurationMinutes: parsedDuration,
        showClient: true,
      );
      return _withReservationDefaults(details, reservation);
    }

    final ownerSelfCancelMatch = RegExp(
      r'^Has cancelado la reserva de (.*?)\s+en\s+(.*?)\s+del\s+(.*?)\s+a las\s+(\d{1,2}:\d{2})(?:\s*[hH])?[\.!]*$',
    ).firstMatch(trimmed);
    if (ownerSelfCancelMatch != null) {
      final labels = _extractBusinessAndService(
        ownerSelfCancelMatch.group(2) ?? '',
      );

      final details = _ReservationNotificationDetails(
        title: 'Has cancelado la reserva',
        client: ownerSelfCancelMatch.group(1)?.trim(),
        business: labels['business'],
        service: labels['service'],
        date: ownerSelfCancelMatch.group(3)?.trim(),
        time: ownerSelfCancelMatch.group(4)?.trim(),
        servicePrice: parsedPrice,
        serviceDurationMinutes: parsedDuration,
        showClient: true,
      );
      return _withReservationDefaults(details, reservation);
    }

    final fallbackMatch = RegExp(
      r'\ben\s+(.*?)\s+del\s+(.*?)\s+a las\s+(\d{1,2}:\d{2})(?:\s*[hH])?[\.!]*$',
    ).firstMatch(trimmed);
    if (fallbackMatch != null) {
      final titleIndex = trimmed.toLowerCase().indexOf(' en ');
      final title = titleIndex > 0
          ? trimmed.substring(0, titleIndex).trim()
          : 'Reserva';

      final rawBusiness = fallbackMatch.group(1)?.trim() ?? '';
      final serviceMatch = RegExp(r'^(.*)\((.*)\)\s*$').firstMatch(rawBusiness);
      final businessLabel = serviceMatch != null
          ? serviceMatch.group(1)?.trim()
          : rawBusiness;
      final serviceLabel = serviceMatch != null
          ? serviceMatch.group(2)?.trim()
          : null;

      final details = _ReservationNotificationDetails(
        title: title,
        business: businessLabel?.isEmpty == true ? null : businessLabel,
        service: serviceLabel?.isEmpty == true ? null : serviceLabel,
        date: fallbackMatch.group(2)?.trim(),
        time: fallbackMatch.group(3)?.trim(),
        servicePrice: parsedPrice,
        serviceDurationMinutes: parsedDuration,
      );
      return _withReservationDefaults(details, reservation);
    }

    return null;
  }

  Map<String, String?> _extractBusinessAndService(String rawLabel) {
    final trimmed = rawLabel.trim();
    if (trimmed.isEmpty) {
      return {'business': null, 'service': null};
    }

    final serviceMatch = RegExp(r'^(.*)\((.*)\)\s*$').firstMatch(trimmed);
    final businessLabel = serviceMatch != null
        ? serviceMatch.group(1)?.trim()
        : trimmed;
    final serviceLabel = serviceMatch != null
        ? serviceMatch.group(2)?.trim()
        : null;

    return {
      'business': businessLabel?.isEmpty == true ? null : businessLabel,
      'service': serviceLabel?.isEmpty == true ? null : serviceLabel,
    };
  }

  String _cleanCancelReason(String? reason) {
    var normalized = reason?.trim() ?? '';
    if (normalized.isEmpty) {
      return '';
    }

    normalized = normalized.replaceAll(RegExp(r'^[\s\.-]+'), '');
    normalized = normalized.replaceAll(RegExp(r'[\s\.!]+$'), '');
    return normalized;
  }

  String _buildClientCancelTitle(String reason) {
    final cleaned = _cleanCancelReason(reason);
    if (cleaned.isEmpty) {
      return 'Tu reserva fue cancelada';
    }
    return 'Tu reserva $cleaned';
  }

  String _buildOwnerCancelTitle(String reason) {
    final cleaned = _cleanCancelReason(reason);
    if (cleaned.isEmpty) {
      return 'Reserva cancelada';
    }

    var normalized = cleaned;
    final lower = normalized.toLowerCase();
    if (lower.startsWith('fue ')) {
      normalized = normalized.substring(4);
    } else if (lower.startsWith('se ')) {
      normalized = normalized.substring(3);
    }

    final lowerNormalized = normalized.toLowerCase();
    if (lowerNormalized.startsWith('canceló') ||
        lowerNormalized.startsWith('cancelo')) {
      final prefixLength =
          lowerNormalized.startsWith('canceló') ? 7 : 6;
      final remainder = normalized.substring(prefixLength).trim();
      return remainder.isEmpty
          ? 'Reserva cancelada'
          : 'Reserva cancelada $remainder';
    }

    final cancelMatch = RegExp(
      r'^cancel\w*\s*(.*)$',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (cancelMatch != null) {
      final remainder = cancelMatch.group(1)?.trim() ?? '';
      normalized = remainder.isEmpty ? 'cancelada' : 'cancelada $remainder';
    }

    return 'Reserva $normalized';
  }

  _ReservationNotificationDetails _withReservationDefaults(
    _ReservationNotificationDetails details,
    Reservation? reservation,
  ) {
    if (reservation == null) {
      return details;
    }

    final business = (details.business == null || details.business!.isEmpty)
        ? (reservation.localName.isNotEmpty
              ? reservation.localName
              : details.business)
        : details.business;
    final service = (details.service == null || details.service!.isEmpty)
        ? (reservation.serviceName.isNotEmpty
              ? reservation.serviceName
              : details.service)
        : details.service;
        final client = details.showClient
        ? ((details.client == null || details.client!.isEmpty)
          ? (reservation.clientName.isNotEmpty
            ? reservation.clientName
            : details.client)
          : details.client)
        : null;

    final duration = details.serviceDurationMinutes ??
        (reservation.durationMinutes > 0
            ? reservation.durationMinutes
            : null);

    return _ReservationNotificationDetails(
      title: details.title,
      business: business,
      service: service,
      date: details.date,
      time: details.time,
      client: client,
      servicePrice: details.servicePrice ?? reservation.servicePrice,
      serviceDurationMinutes: duration,
      showClient: details.showClient,
    );
  }

  Widget _buildNotificationDetailLine({
    required IconData icon,
    required String text,
    Color? iconColor,
  }) {
    final resolvedIconColor = iconColor ?? primaryColor;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: resolvedIconColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceDetailLine({
    required String service,
    double? price,
    int? durationMinutes,
    Color? iconColor,
  }) {
    final resolvedIconColor = iconColor ?? primaryColor;
    const detailStyle = TextStyle(
      color: Colors.white70,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );

    final priceLabel = price != null ? '${price.toStringAsFixed(2)} €' : null;
    final durationLabel =
        durationMinutes != null && durationMinutes > 0
            ? '${durationMinutes} min'
            : null;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.content_cut, size: 16, color: resolvedIconColor),
          const SizedBox(width: 6),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final parts = <String>[service];
                if (priceLabel != null && priceLabel.isNotEmpty) {
                  parts.add(priceLabel);
                }
                final baseText = parts.join(' - ');
                var displayText = baseText;

                if (durationLabel != null && durationLabel.isNotEmpty) {
                  final candidate = '$baseText - $durationLabel';
                  final painter = TextPainter(
                    text: TextSpan(text: candidate, style: detailStyle),
                    maxLines: 1,
                    textDirection: Directionality.of(context),
                  )..layout(maxWidth: constraints.maxWidth);

                  if (!painter.didExceedMaxLines) {
                    displayText = candidate;
                  }
                }

                return Text(
                  displayText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: detailStyle,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String? _joinNotificationDateTime(String? date, String? time) {
    final dateLabel = date?.trim() ?? '';
    final timeLabel = time?.trim() ?? '';
    if (dateLabel.isEmpty && timeLabel.isEmpty) {
      return null;
    }
    if (dateLabel.isEmpty) {
      return timeLabel;
    }
    if (timeLabel.isEmpty) {
      return dateLabel;
    }
    return '$dateLabel - $timeLabel';
  }

  Widget _buildNotificationContent(
    dynamic notif,
    bool isRead, {
    _ReservationNotificationDetails? parsed,
    Color? detailIconColor,
  }) {
    final message = notif["message"]?.toString() ?? '';
    final parsedDetails = parsed ?? _parseNotificationForItem(notif);
    if (parsedDetails == null) {
      return Text(
        message,
        style: TextStyle(
          color: Colors.white,
          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          parsedDetails.title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
          ),
        ),
        if (parsedDetails.showClient &&
            parsedDetails.client != null &&
            parsedDetails.client!.isNotEmpty)
          _buildNotificationDetailLine(
            icon: Icons.person_outline,
            text: parsedDetails.client!,
            iconColor: detailIconColor,
          ),
        if (parsedDetails.business != null &&
            parsedDetails.business!.isNotEmpty)
          _buildNotificationDetailLine(
            icon: Icons.storefront_outlined,
            text: parsedDetails.business!,
            iconColor: detailIconColor,
          ),
        if (parsedDetails.service != null &&
            parsedDetails.service!.isNotEmpty)
          _buildServiceDetailLine(
            service: parsedDetails.service!,
            price: parsedDetails.servicePrice,
            durationMinutes: parsedDetails.serviceDurationMinutes,
            iconColor: detailIconColor,
          ),
        if (_joinNotificationDateTime(
              parsedDetails.date,
              parsedDetails.time,
            ) !=
            null)
          _buildNotificationDetailLine(
            icon: Icons.calendar_month,
            text: _joinNotificationDateTime(
              parsedDetails.date,
              parsedDetails.time,
            )!,
            iconColor: detailIconColor,
          ),
      ],
    );
  }

  Widget _buildNotificationItem(dynamic notif) {
    final bool isRead = notif["read"] ?? false;
    final parsed = _parseNotificationForItem(notif);
    final visual = _resolveNotificationVisual(notif, parsed);
    final createdAt = _parseNotificationDate(notif);

    return GestureDetector(
      onTap: () => markAsRead(notif["_id"]),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead
              ? Color.fromARGB(255, 40, 40, 40)
              : Color.fromARGB(255, 60, 50, 40),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            SizedBox(width: 3),
            Icon(visual.icon, color: visual.color),
            SizedBox(width: 18),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNotificationContent(
                    notif,
                    isRead,
                    parsed: parsed,
                    detailIconColor: visual.color,
                  ),
                  SizedBox(height: 6),
                  Text(
                    createdAt == null
                        ? ''
                        : _formatNotificationTimestamp(createdAt),
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  DateTime? _parseNotificationDate(dynamic notif) {
    final raw = notif["createdAt"];
    if (raw is! String || raw.trim().isEmpty) {
      return null;
    }

    try {
      return DateTime.parse(raw).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _formatNotificationTimestamp(DateTime date) {
    final datePart = DateFormat('dd MMM yyyy', 'es').format(date);
    final timePart = DateFormat('HH:mm', 'es').format(date);
    final formattedDate = _capitalizeMonthInDateLabel(datePart);
    return '$formattedDate - $timePart';
  }

  String _capitalizeMonthInDateLabel(String label) {
    final parts = label.split(' ');
    if (parts.length < 2) {
      return _capitalizeFirstLetter(label);
    }
    parts[1] = _capitalizeFirstLetter(parts[1]);
    return parts.join(' ');
  }

  String _capitalizeFirstLetter(String value) {
    if (value.isEmpty) {
      return value;
    }
    return value.substring(0, 1).toUpperCase() + value.substring(1);
  }

  String _labelForNotificationDate(DateTime createdAt, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final createdDay = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final dayDiff = today.difference(createdDay).inDays;

    if (dayDiff <= 0) {
      return 'Hoy';
    }
    if (dayDiff == 1) {
      return 'Ayer';
    }
    if (dayDiff <= 6) {
      return 'Hace $dayDiff días';
    }
    if (dayDiff <= 13) {
      return 'La semana pasada';
    }
    if (dayDiff <= 20) {
      return 'Hace 2 semanas';
    }
    if (dayDiff <= 27) {
      return 'Hace 3 semanas';
    }

    final monthsDiff =
        (now.year - createdAt.year) * 12 + (now.month - createdAt.month);
    if (monthsDiff <= 0) {
      return 'Hace $dayDiff días';
    }
    if (monthsDiff == 1) {
      return 'Mes pasado';
    }
    if (monthsDiff <= 11) {
      return 'Hace $monthsDiff meses';
    }

    final yearsDiff = (monthsDiff / 12).floor();
    if (yearsDiff == 1) {
      return 'El año pasado';
    }
    return 'Hace $yearsDiff años';
  }

  Widget _buildNotificationGroupHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 18, 25, 6),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  List<dynamic> _sortedNotifications() {
    final items = List<dynamic>.from(notifications);
    items.sort((a, b) {
      final dateA = _parseNotificationDate(a);
      final dateB = _parseNotificationDate(b);

      if (dateA == null && dateB == null) {
        return 0;
      }
      if (dateA == null) {
        return 1;
      }
      if (dateB == null) {
        return -1;
      }

      return dateB.compareTo(dateA);
    });
    return items;
  }

  List<Widget> _buildNotificationListWidgets() {
    final now = DateTime.now();
    final items = _sortedNotifications();
    final widgets = <Widget>[];

    String? currentLabel;
    for (final notif in items) {
      final createdAt = _parseNotificationDate(notif);
      final label = createdAt == null
          ? 'Sin fecha'
          : _labelForNotificationDate(createdAt, now);

      if (label != currentLabel) {
        widgets.add(_buildNotificationGroupHeader(label));
        currentLabel = label;
      }

      widgets.add(_buildNotificationItem(notif));
    }

    return widgets;
  }

  @override
  void initState() {
    super.initState();
    fetchNotifications();
    _loadReservationDetails();
    loadUserRole();
  }

  void loadUserRole() async {
    int? r = await getUserRole();
    setState(() {
      role = r;
    });
  }

  Future<String?> getUserToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  // Controla qué pasa al pulsar cada icono
  void _onItemTapped(int index) async {
    setState(() {
      _selectedIndex = index; // Actualiza el icono seleccionado
    });

    int role = await getUserRole() ?? 0;

    // Aquí puedes poner la acción de cada icono
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CalendarPage()),
        );
        break;
      case 1:
        if (role == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OwnerBusinessPage()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const FavoritesPage()),
          );
        }
        break;
      case 2:
        // PROPIETARIO
        if (role == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePageOwner()),
          );
        }
        // CLIENTE
        else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
        break;
      case 3:
        print("Notificaciones pulsado");
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // BARRA INFERIOR
      bottomNavigationBar: InputDecorations.mainBottomNavBar(
        context: context,
        currentIndex: 3,
        owner: role == 1,
        onTap: _onItemTapped,
        unreadNotifications: unreadCount,
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 90),

          Text(
            'Notificaciones',
            style: TextStyle(
              fontSize: 33,
              color: Color.fromARGB(255, 200, 156, 125),
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Aquí puedes ver tus notificaciones',
            style: TextStyle(
              fontSize: 14,
              color: Color.fromARGB(255, 200, 156, 125),
            ),
          ),

          SizedBox(height: 20),

          Expanded(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: Color.fromARGB(255, 200, 156, 125),
                    ),
                  )
                : RefreshIndicator(
                    color: primaryColor,
                    onRefresh: _refreshNotifications,
                    child: notifications.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            children: const [
                              Center(
                                child: Text(
                                  "No tienes notificaciones",
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                            ],
                          )
                        : ListView(
                            padding: const EdgeInsets.only(bottom: 16),
                            children: _buildNotificationListWidgets(),
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
