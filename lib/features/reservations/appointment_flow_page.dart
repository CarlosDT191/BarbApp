import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/booking_models.dart';
import 'package:flutter_application_1/models/decorations.dart';
import 'package:flutter_application_1/models/reservation.dart';
import 'package:flutter_application_1/services/business_service.dart';
import 'package:flutter_application_1/services/reservation_service.dart';
import 'package:intl/intl.dart';

class AppointmentFlowPage extends StatefulWidget {
  final DateTime? initialDate;
  final String? initialTime;

  const AppointmentFlowPage({
    super.key,
    this.initialDate,
    this.initialTime,
  });

  @override
  State<AppointmentFlowPage> createState() => _AppointmentFlowPageState();
}

class _AppointmentFlowPageState extends State<AppointmentFlowPage> {
  final ReservationService _reservationService = ReservationService();
  final TextEditingController _clientNameController = TextEditingController();

  int _currentStep = 0;
  bool _isLoadingBusinesses = false;
  bool _isLoadingBusinessDetails = false;
  bool _isLoadingAvailability = false;
  bool _isSaving = false;

  List<BookingBusinessSummary> _businesses = [];
  BookingBusinessSummary? _selectedBusiness;
  BookingBusinessDetails? _selectedBusinessDetails;

  int? _selectedOfferIndex;
  BookingAvailability? _availability;
  String? _selectedTime;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _loadBusinesses();
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    super.dispose();
  }

  Future<void> _loadBusinesses() async {
    setState(() {
      _isLoadingBusinesses = true;
    });

    try {
      final rawBusinesses = await BusinessService.getMyBusinesses();
      final businesses = rawBusinesses
          .whereType<Map<String, dynamic>>()
          .map(_mapOwnerBusiness)
          .where((business) => business.id.isNotEmpty)
          .toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _businesses = businesses;
        _isLoadingBusinesses = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _businesses = [];
        _isLoadingBusinesses = false;
      });

      InputDecorations.showTopSnackBarError(
        context,
        'No se pudieron cargar tus negocios.',
      );
    }
  }

  BookingBusinessSummary _mapOwnerBusiness(Map<String, dynamic> json) {
    final googlePlace = json['googlePlace'] as Map<String, dynamic>?;

    return BookingBusinessSummary(
      id: (json['_id'] ?? json['id']).toString(),
      name: json['name']?.toString() ?? '',
      address: googlePlace?['address']?.toString() ?? '',
      placeId: googlePlace?['placeId']?.toString() ?? '',
    );
  }

  Future<void> _loadBusinessDetails(String businessId) async {
    setState(() {
      _isLoadingBusinessDetails = true;
    });

    try {
      final details =
          await BusinessService.getBusinessDetails(businessId: businessId);

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedBusinessDetails = details;
        _isLoadingBusinessDetails = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _selectedBusinessDetails = null;
        _isLoadingBusinessDetails = false;
      });

      InputDecorations.showTopSnackBarError(
        context,
        'No se pudo cargar el detalle del negocio.',
      );
    }
  }

  Future<void> _loadAvailability() async {
    final selectedBusiness = _selectedBusinessDetails;
    final selectedOfferIndex = _selectedOfferIndex;

    if (selectedBusiness == null || selectedOfferIndex == null) {
      return;
    }

    setState(() {
      _isLoadingAvailability = true;
      _availability = null;
      _selectedTime = null;
    });

    try {
      final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final availability = await BusinessService.getBusinessAvailability(
        businessId: selectedBusiness.id,
        date: dateString,
        offerIndex: selectedOfferIndex,
      );

      if (!mounted) {
        return;
      }

      String? preselectedTime;
      if (_selectedTime == null && widget.initialTime != null) {
        final candidate = widget.initialTime!.trim();
        if (availability.slots.any((slot) => slot.time == candidate)) {
          preselectedTime = candidate;
        }
      }

      setState(() {
        _availability = availability;
        _selectedTime = preselectedTime;
        _isLoadingAvailability = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _availability = null;
        _selectedTime = null;
        _isLoadingAvailability = false;
      });

      InputDecorations.showTopSnackBarError(
        context,
        'No se pudo cargar la disponibilidad.',
      );
    }
  }

  void _selectBusiness(BookingBusinessSummary business) {
    setState(() {
      _selectedBusiness = business;
      _selectedBusinessDetails = null;
      _selectedOfferIndex = null;
      _availability = null;
      _selectedTime = null;
    });

    _loadBusinessDetails(business.id);

    setState(() {
      _currentStep = 1;
    });
  }

  void _selectOffer(int index) {
    setState(() {
      _selectedOfferIndex = index;
      _availability = null;
      _selectedTime = null;
    });

    _loadAvailability();

    setState(() {
      _currentStep = 3;
    });
  }

  Future<void> _pickDate() async {
    final initialDate = _selectedDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        final theme = Theme.of(context);

        return Theme(
          data: theme.copyWith(
            colorScheme: const ColorScheme.dark().copyWith(
              primary: Color.fromARGB(255, 200, 156, 125), // día seleccionado
              onPrimary: Colors.white, // texto sobre día seleccionado

              surface: Color.fromARGB(255, 30, 30, 30), // fondo principal calendario
              onSurface: Colors.white, // texto general

              background: Color.fromARGB(255, 23, 23, 23), // fondo general
              onBackground: Colors.white,
            ),

            dialogBackgroundColor: const Color.fromARGB(255, 23, 23, 23),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _selectedDate = DateTime(picked.year, picked.month, picked.day);
    });

    await _loadAvailability();
  }

  Future<void> _confirmAppointment() async {
    final selectedBusiness = _selectedBusinessDetails;
    final selectedOfferIndex = _selectedOfferIndex;
    final selectedTime = _selectedTime;
    final clientName = _clientNameController.text.trim();

    if (selectedBusiness == null || selectedOfferIndex == null) {
      return;
    }

    if (clientName.isEmpty) {
      InputDecorations.showTopSnackBarWarning(
        context,
        'Indica el nombre del cliente.',
      );
      return;
    }

    if (selectedTime == null || selectedTime.isEmpty) {
      InputDecorations.showTopSnackBarWarning(
        context,
        'Selecciona una hora disponible.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final reservation = await _reservationService.createAppointment(
        date: _selectedDate,
        time: selectedTime,
        businessId: selectedBusiness.id,
        offerIndex: selectedOfferIndex,
        clientName: clientName,
      );

      if (!mounted) {
        return;
      }

      Navigator.pop<Reservation>(context, reservation);

      InputDecorations.showTopSnackBarSuccess(
        context,
        'Cita creada exitosamente.',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      InputDecorations.showTopSnackBarError(
        context,
        'Error al crear la cita: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  bool get _canContinue {
    if (_currentStep == 0) {
      return _selectedBusiness != null;
    }
    if (_currentStep == 1) {
      return _clientNameController.text.trim().isNotEmpty;
    }
    if (_currentStep == 2) {
      return _selectedOfferIndex != null;
    }
    if (_currentStep == 3) {
      return _selectedTime != null && _selectedTime!.isNotEmpty;
    }
    return false;
  }

  void _handleNext() {
    if (_currentStep == 0) {
      if (_selectedBusiness == null) {
        InputDecorations.showTopSnackBarWarning(
          context,
          'Selecciona un negocio.',
        );
        return;
      }
      setState(() => _currentStep = 1);
      return;
    }

    if (_currentStep == 1) {
      if (_clientNameController.text.trim().isEmpty) {
        InputDecorations.showTopSnackBarWarning(
          context,
          'Indica el nombre del cliente.',
        );
        return;
      }
      setState(() => _currentStep = 2);
      return;
    }

    if (_currentStep == 2) {
      if (_selectedOfferIndex == null) {
        InputDecorations.showTopSnackBarWarning(
          context,
          'Selecciona un servicio.',
        );
        return;
      }
      setState(() => _currentStep = 3);
      return;
    }

    _confirmAppointment();
  }

  void _handleBack() {
    if (_currentStep == 0) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _currentStep -= 1;
    });
  }

  Widget _buildStepHeader() {
    return Row(
      children: List.generate(4, (index) {
        final selected = index <= _currentStep;
        return Expanded(
          child: Container(
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: selected
                  ? const Color.fromARGB(255, 200, 156, 125)
                  : Colors.white12,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildBusinessStep() {
    return _buildCard(
      title: '1. Selecciona tu negocio',
      subtitle: 'Elige uno de tus locales registrados.',
      expandChild: true,
      child: _isLoadingBusinesses
          ? const Center(
              child: CircularProgressIndicator(
                color: Color.fromARGB(255, 200, 156, 125),
              ),
            )
          : _businesses.isEmpty
              ? const Center(
                  child: Text(
                    'No tienes negocios registrados.',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : ListView.separated(
                  itemCount: _businesses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final business = _businesses[index];
                    final isSelected = _selectedBusiness?.id == business.id;

                    return InkWell(
                      onTap: () => _selectBusiness(business),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color.fromARGB(255, 55, 45, 38)
                              : const Color.fromARGB(255, 30, 30, 30),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color.fromARGB(255, 200, 156, 125)
                                : Colors.transparent,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              business.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (business.address.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                business.address,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildClientStep() {
    return _buildCard(
      title: '2. Datos del cliente',
      subtitle: 'Indica quién reserva el servicio.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _clientNameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Nombre del cliente',
              labelStyle: const TextStyle(color: Colors.white70),
              hintText: 'Ej: Juan Perez',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: const Color.fromARGB(255, 38, 38, 38),

              // 🔹 Borde normal
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color.fromARGB(255, 70, 70, 70),
                  width: 1,
                ),
              ),

              // 🔹 Borde cuando está seleccionado
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color.fromARGB(255, 200, 156, 125),
                  width: 1.5,
                ),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferStep() {
    if (_isLoadingBusinessDetails) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color.fromARGB(255, 200, 156, 125),
        ),
      );
    }

    final business = _selectedBusinessDetails;

    if (business == null) {
      return _buildCard(
        title: '3. Selecciona un servicio',
        subtitle: '',
        expandChild: true,
        child: const Center(
          child: Text(
            'Selecciona un negocio para ver los servicios.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    if (business.offers.isEmpty) {
      return _buildCard(
        title: '3. Selecciona un servicio',
        subtitle: '',
        expandChild: true,
        child: const Center(
          child: Text(
            'Este negocio no tiene servicios configurados.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return _buildCard(
      title: '3. Selecciona un servicio',
      subtitle: 'Elige el servicio que deseas reservar.',
      expandChild: true,
      child: ListView.separated(
        itemCount: business.offers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final offer = business.offers[index];
          final isSelected = _selectedOfferIndex == index;

          return InkWell(
            onTap: () => _selectOffer(index),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color.fromARGB(255, 55, 45, 38)
                    : const Color.fromARGB(255, 38, 38, 38),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color.fromARGB(255, 200, 156, 125)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          offer.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${offer.durationMinutes} min • ${offer.serviceType}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${offer.price.toStringAsFixed(2)}€',
                    style: const TextStyle(
                      color: Color.fromARGB(255, 200, 156, 125),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateStep() {
    final availability = _availability;
    final slots = availability?.slots ?? [];
    final formattedDate = DateFormat('dd/MM/yyyy').format(_selectedDate);

    Widget availabilityContent;
    if (_isLoadingAvailability) {
      availabilityContent = const Center(
        child: CircularProgressIndicator(
          color: Color.fromARGB(255, 200, 156, 125),
        ),
      );
    } else if (availability == null) {
      availabilityContent = const Text(
        'Selecciona un servicio para ver horarios disponibles.',
        style: TextStyle(color: Colors.white70),
      );
    } else if (slots.isEmpty) {
      availabilityContent = const Text(
        'No hay horarios disponibles para esta fecha.',
        style: TextStyle(color: Colors.white70),
      );
    } else {
      availabilityContent = SingleChildScrollView(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: slots.map((slot) {
            final isSelected = _selectedTime == slot.time;
            final label = slot.remaining > 1
                ? '${slot.time} (${slot.remaining})'
                : slot.time;

            return ChoiceChip(
              label: Text(label),
              selected: isSelected,
              selectedColor: const Color.fromARGB(255, 200, 156, 125),
              backgroundColor: const Color.fromARGB(255, 30, 30, 30),
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: FontWeight.w600,
              ),
              onSelected: (_) {
                setState(() {
                  _selectedTime = slot.time;
                });
              },
            );
          }).toList(),
        ),
      );
    }

    return _buildCard(
      title: '4. Selecciona fecha y hora',
      subtitle: 'Escoge un día y una hora disponible.',
      expandChild: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 38, 38, 38),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: Color.fromARGB(255, 200, 156, 125),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    formattedDate,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const Spacer(),
                  const Icon(Icons.edit, color: Colors.white54, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: availabilityContent),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String subtitle,
    required Widget child,
    bool expandChild = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 30, 30, 30),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color.fromARGB(255, 200, 156, 125),
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 25),
          expandChild ? Expanded(child: child) : child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextSelectionTheme(
      data: const TextSelectionThemeData(
        cursorColor: Color.fromARGB(255, 200, 156, 125),
        selectionHandleColor: Color.fromARGB(255, 200, 156, 125),
        selectionColor: Color.fromARGB(80, 200, 156, 125),
      ),
      child: Scaffold(
      backgroundColor: const Color.fromARGB(255, 23, 23, 23),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 23, 23, 23),
        foregroundColor: Colors.white,
        title: const Text('Nueva cita'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          child: Column(
            children: [
              _buildStepHeader(),
              const SizedBox(height: 18),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: IndexedStack(
                    index: _currentStep,
                    children: [
                      _buildBusinessStep(),
                      _buildClientStep(),
                      _buildOfferStep(),
                      _buildDateStep(),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _isSaving ? null : _handleBack,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Colors.white54),
                        ),
                        child: const Text(
                          'Atrás',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            _isSaving ? null : (_canContinue ? _handleNext : null),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 200, 156, 125),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: const BorderSide(
                              color: Colors.white,
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                _currentStep == 3 ? 'Crear cita' : 'Continuar',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
