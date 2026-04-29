import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/booking_models.dart';
import 'package:flutter_application_1/models/decorations.dart';
import 'package:flutter_application_1/models/reservation.dart';
import 'package:flutter_application_1/services/business_service.dart';
import 'package:flutter_application_1/services/reservation_service.dart';
import 'package:intl/intl.dart';

class ReservationFlowPage extends StatefulWidget {
  final String? initialBusinessId;
  final String? initialBusinessName;
  final DateTime? initialDate;
  final String? initialTime;

  const ReservationFlowPage({
    super.key,
    this.initialBusinessId,
    this.initialBusinessName,
    this.initialDate,
    this.initialTime,
  });

  @override
  State<ReservationFlowPage> createState() => _ReservationFlowPageState();
}

class _ReservationFlowPageState extends State<ReservationFlowPage> {
  final ReservationService _reservationService = ReservationService();
  final TextEditingController _businessSearchController =
      TextEditingController();
  Timer? _searchDebounce;

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

    if (widget.initialBusinessId != null) {
      _currentStep = 1;
      if (widget.initialBusinessName != null &&
          widget.initialBusinessName!.trim().isNotEmpty) {
        _selectedBusiness = BookingBusinessSummary(
          id: widget.initialBusinessId!.trim(),
          name: widget.initialBusinessName!.trim(),
          address: '',
          placeId: '',
        );
      }
      _loadBusinessDetails(widget.initialBusinessId!);
    } else {
      _loadBusinesses();
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _businessSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadBusinesses([String query = '']) async {
    setState(() {
      _isLoadingBusinesses = true;
    });

    try {
      final businesses =
          await BusinessService.listRegisteredBusinesses(query: query);

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
        'No se pudieron cargar los negocios.',
      );
    }
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
        _selectedBusiness = BookingBusinessSummary(
          id: details.id,
          name: details.name,
          address: details.address,
          placeId: '',
        );
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
      if (widget.initialTime != null) {
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

  void _onBusinessSearchChanged(String rawQuery) {
    final query = rawQuery.trim();
    _searchDebounce?.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _loadBusinesses(query);
    });
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
      _currentStep = 2;
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
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _selectedDate = DateTime(picked.year, picked.month, picked.day);
    });

    await _loadAvailability();
  }

  Future<void> _confirmReservation() async {
    final selectedBusiness = _selectedBusinessDetails;
    final selectedOfferIndex = _selectedOfferIndex;
    final selectedTime = _selectedTime;

    if (selectedBusiness == null || selectedOfferIndex == null) {
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
      final reservation = await _reservationService.createReservation(
        date: _selectedDate,
        time: selectedTime,
        businessId: selectedBusiness.id,
        offerIndex: selectedOfferIndex,
      );

      if (!mounted) {
        return;
      }

      Navigator.pop<Reservation>(context, reservation);

      InputDecorations.showTopSnackBarSuccess(
        context,
        'Reserva creada exitosamente.',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      InputDecorations.showTopSnackBarError(
        context,
        'Error al crear la reserva: $e',
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
      return _selectedOfferIndex != null;
    }
    if (_currentStep == 2) {
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
      if (_selectedOfferIndex == null) {
        InputDecorations.showTopSnackBarWarning(
          context,
          'Selecciona un servicio.',
        );
        return;
      }
      setState(() => _currentStep = 2);
      return;
    }

    _confirmReservation();
  }

  void _handleBack() {
    if (_currentStep == 0) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _currentStep -= 1;
    });

    if (_currentStep == 0 && _businesses.isEmpty) {
      _loadBusinesses(_businessSearchController.text);
    }
  }

  Widget _buildStepHeader() {
    return Row(
      children: List.generate(3, (index) {
        final selected = index <= _currentStep;
        return Expanded(
          child: Container(
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: selected ? Color.fromARGB(255, 200, 156, 125) : Colors.white12,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildBusinessStep() {
    return _buildCard(
      title: '1. Selecciona el negocio',
      subtitle: 'Busca y elige un negocio disponible.',
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
                    'No hay negocios disponibles.',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : ListView(
                  children: [
                    TextField(
                      controller: _businessSearchController,
                      onChanged: _onBusinessSearchChanged,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Buscar negocio...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        suffixIcon:
                            const Icon(Icons.search, color: Color.fromARGB(255, 200, 156, 125)),
                        filled: true,
                        fillColor: const Color.fromARGB(255, 38, 38, 38),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    ..._businesses.map((business) {
                      final isSelected =
                          _selectedBusiness?.id == business.id;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
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
                                    ? const Color.fromARGB(
                                        255, 200, 156, 125)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
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
                        ),
                      );
                    }).toList(),
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
        title: '2. Selecciona un servicio',
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
        title: '2. Selecciona un servicio',
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
      title: '2. Selecciona un servicio',
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

    return _buildCard(
      title: '3. Selecciona fecha y hora',
      subtitle: 'Escoge un día y una hora disponible.',
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
          if (_isLoadingAvailability)
            const Center(
              child: CircularProgressIndicator(
                color: Color.fromARGB(255, 200, 156, 125),
              ),
            )
          else if (availability == null)
            const Text(
              'Selecciona un servicio para ver horarios disponibles.',
              style: TextStyle(color: Colors.white70),
            )
          else if (slots.isEmpty)
            const Text(
              'No hay horarios disponibles para esta fecha.',
              style: TextStyle(color: Colors.white70),
            )
          else
            Wrap(
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
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 23, 23, 23),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 23, 23, 23),
        foregroundColor: Colors.white,
        title: const Text('Reservar'),
      ),
      // PÁGINA DE RESERVAR EN NEGOCIOS
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
                        onPressed: _isSaving
                            ? null
                            : (_canContinue ? _handleNext : null),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 200, 156, 125),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30), // opcional (para bordes redondeados)
                            side: const BorderSide(
                              color: Colors.white, // ← aquí defines el borde blanco
                              width: 1.5,          // grosor del borde
                            ),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                _currentStep == 2 ? 'Reservar' : 'Continuar',
                                style: const TextStyle(
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
    );
  }
}

