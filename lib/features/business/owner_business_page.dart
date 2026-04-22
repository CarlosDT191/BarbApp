import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/features/calendar/calendar_page.dart';
import 'package:flutter_application_1/features/profile/profile_page.dart';
import 'package:flutter_application_1/features/home/home_page_owner.dart';
import 'package:flutter_application_1/features/notifications/notification_page.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/models/decorations.dart';
import 'package:flutter_application_1/services/business_service.dart';

class OwnerBusinessPage extends StatefulWidget {
  const OwnerBusinessPage({super.key});

  @override
  State<OwnerBusinessPage> createState() => _OwnerBusinessPageState();
}

class _OwnerBusinessPageState extends State<OwnerBusinessPage> {
  bool _isLoading = true;
  bool _wizardShown = false;
  List<OwnerBusiness> _businesses = [];
  List<dynamic> notifications = [];
  int _selectedIndex = 0;
  bool isLoadingNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadBusinesses();
    fetchNotifications();
  }

  int get unreadCount {
    return notifications.where((n) => n["read"] == false).length;
  }

  Future<void> fetchNotifications() async {
    final token = await getUserToken();
    final apiBaseUrl = getApiBaseUrl();

    final response = await http.get(
      Uri.parse("$apiBaseUrl/notifications"),
      headers: {"Authorization": "Bearer $token"},
    );

    final data = jsonDecode(response.body);

    setState(() {
      notifications = data;
      isLoadingNotifications = false;
    });
  }

  Future<String?> getUserToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  Future<void> _loadBusinesses() async {
    final businesses = await OwnerBusinessStorage.loadBusinesses();

    if (!mounted) {
      return;
    }

    setState(() {
      _businesses = businesses;
      _isLoading = false;
    });

    if (_businesses.isEmpty && !_wizardShown) {
      _wizardShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openSetupFlow();
      });
    }
  }

  Future<void> _openSetupFlow() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const OwnerBusinessSetupFlowPage()),
    );

    if (created == true) {
      await _loadBusinesses();
    }
  }

  // Controla qué pasa al pulsar cada icono
  void _onItemTapped(int index) async {
    setState(() {
      _selectedIndex = index; // Actualiza el icono seleccionado
    });

    // Aquí puedes poner la acción de cada icono
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CalendarPage()),
        );
        break;
      case 1:
        print("Negocios pulsado");
        break;
      case 2:
        // PROPIETARIO
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePageOwner()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const NotificationPage()),
        );
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
    const backgroundColor = Color.fromARGB(255, 23, 23, 23);
    const cardColor = Color.fromARGB(255, 30, 30, 30);
    const primaryColor = Color.fromARGB(255, 200, 156, 125);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,

        bottomNavigationBar: InputDecorations.mainBottomNavBar(
          context: context,
          currentIndex: 1,
          owner: true,
          onTap: _onItemTapped,
          unreadNotifications: unreadCount,
        ),

        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,

      bottomNavigationBar: InputDecorations.mainBottomNavBar(
        context: context,
        currentIndex: 1,
        owner: true,
        onTap: _onItemTapped,
        unreadNotifications: unreadCount,
      ),

      floatingActionButton: _businesses.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _openSetupFlow,
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
                side: BorderSide(
                  color: Colors.white, // Color del borde
                  width: 2.0, // Grosor del borde
                ),
              ),
              icon: const Icon(Icons.add_business_rounded),
              label: const Text('Nuevo negocio'),
            )
          : null,

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 70),

          const Text(
            'Mis negocios',
            style: TextStyle(
              color: primaryColor,
              fontSize: 33,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 50),

          if (_businesses.isEmpty) ...[
            const SizedBox(height: 90),
            Center(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.storefront_rounded,
                      size: 62,
                      color: primaryColor,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Aun no tienes negocios creados',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Configura tu primer negocio para definir ofertas, horario y numero de empleados.',
                      style: TextStyle(color: Colors.white70, fontSize: 15),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 35),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 25,
                        vertical: 16,
                      ),
                      child: InputDecorations.loadingButton(
                        isSent: false,
                        isEnabled: true,
                        text: "Empezar configuracion",
                        onPressed: _openSetupFlow,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else
            ..._businesses.map((business) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      business.name,
                      style: const TextStyle(
                        color: primaryColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Empleados: ${business.employeeCount}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    if (business.googlePlace != null) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'Dirección del local vinculado',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '- ${business.googlePlace!.name}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        '- ${business.googlePlace!.address}',
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ],
                    const SizedBox(height: 10),
                    const Text(
                      'Ofertas',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...business.offers.map((offer) {
                      final durationLabel = offer.durationMinutes > 0
                          ? ' - ${offer.durationMinutes} min'
                          : '';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '- ${offer.name}: ${offer.price.toStringAsFixed(2)} EUR$durationLabel',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      );
                    }),
                    const SizedBox(height: 10),
                    const Text(
                      'Horario',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...business.schedule.map((day) {
                      final splitShiftText =
                          day.isSplitShift &&
                              day.secondOpenTime.isNotEmpty &&
                              day.secondCloseTime.isNotEmpty
                          ? ' / ${day.secondOpenTime} - ${day.secondCloseTime}'
                          : '';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          day.isOpen
                              ? '- ${day.day}: ${day.openTime} - ${day.closeTime}$splitShiftText'
                              : '- ${day.day}: Cerrado',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      );
                    }),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}

class OwnerBusinessSetupFlowPage extends StatefulWidget {
  const OwnerBusinessSetupFlowPage({super.key});

  @override
  State<OwnerBusinessSetupFlowPage> createState() =>
      _OwnerBusinessSetupFlowPageState();
}

class _OwnerBusinessSetupFlowPageState
    extends State<OwnerBusinessSetupFlowPage> {
  static const _primaryColor = Color.fromARGB(255, 200, 156, 125);
  static const _backgroundColor = Color.fromARGB(255, 23, 23, 23);
  static const _cardColor = Color.fromARGB(255, 30, 30, 30);

  final _googlePlaceSearchController = TextEditingController();
  final _sameDurationController = TextEditingController(text: '30');
  final List<_OfferDraft> _offers = [_OfferDraft()];
  final List<BusinessGooglePlace> _googlePlaceResults = [];

  int _currentStep = 0;
  int _employeeCount = 0;
  bool _isSearchingGooglePlaces = false;
  bool _useSameDurationForAllOffers = false;
  bool _useScheduleByDays = false;
  bool _defaultIsSplitShift = false;
  BusinessGooglePlace? _selectedGooglePlace;

  final List<String> _weekDays = const [
    'Lunes',
    'Martes',
    'Miercoles',
    'Jueves',
    'Viernes',
    'Sabado',
    'Domingo',
  ];

  late Map<String, bool> _isOpen;
  late Map<String, bool> _isSplitShift;
  late Map<String, TimeOfDay> _openTime;
  late Map<String, TimeOfDay> _closeTime;
  late Map<String, TimeOfDay> _secondOpenTime;
  late Map<String, TimeOfDay> _secondCloseTime;
  late TimeOfDay _defaultOpenTime;
  late TimeOfDay _defaultCloseTime;
  late TimeOfDay _defaultSecondOpenTime;
  late TimeOfDay _defaultSecondCloseTime;

  @override
  void initState() {
    super.initState();

    _defaultOpenTime = const TimeOfDay(hour: 9, minute: 0);
    _defaultCloseTime = const TimeOfDay(hour: 18, minute: 0);
    _defaultSecondOpenTime = const TimeOfDay(hour: 16, minute: 0);
    _defaultSecondCloseTime = const TimeOfDay(hour: 20, minute: 0);

    _isOpen = {for (final day in _weekDays) day: true};
    _openTime = {for (final day in _weekDays) day: _defaultOpenTime};
    _closeTime = {for (final day in _weekDays) day: _defaultCloseTime};
    _isSplitShift = {for (final day in _weekDays) day: false};
    _secondOpenTime = {
      for (final day in _weekDays) day: _defaultSecondOpenTime,
    };
    _secondCloseTime = {
      for (final day in _weekDays) day: _defaultSecondCloseTime,
    };

    _offers.first.durationController.text = _sameDurationController.text.trim();
  }

  @override
  void dispose() {
    _googlePlaceSearchController.dispose();
    _sameDurationController.dispose();
    for (final offer in _offers) {
      offer.dispose();
    }
    super.dispose();
  }

  void _syncDurationToAllOffers([String? rawDuration]) {
    final sharedDuration = (rawDuration ?? _sameDurationController.text).trim();
    for (final offer in _offers) {
      offer.durationController.text = sharedDuration;
    }
  }

  void _applyGeneralScheduleToEachDay() {
    for (final day in _weekDays) {
      _openTime[day] = _defaultOpenTime;
      _closeTime[day] = _defaultCloseTime;
      _isSplitShift[day] = _defaultIsSplitShift;
      _secondOpenTime[day] = _defaultSecondOpenTime;
      _secondCloseTime[day] = _defaultSecondCloseTime;
    }
  }

  Future<TimeOfDay?> _showBusinessTimePicker(TimeOfDay initialTime) async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _primaryColor,
              surface: _cardColor,
            ),
          ),
          child: child!,
        );
      },
    );

    return selectedTime;
  }

  Future<void> _pickTime(String day, bool isOpenTime) async {
    final selectedTime = await _showBusinessTimePicker(
      isOpenTime ? _openTime[day]! : _closeTime[day]!,
    );

    if (selectedTime == null) {
      return;
    }

    setState(() {
      if (isOpenTime) {
        _openTime[day] = selectedTime;
      } else {
        _closeTime[day] = selectedTime;
      }
    });
  }

  Future<void> _pickSplitTime(String day, bool isOpenTime) async {
    final selectedTime = await _showBusinessTimePicker(
      isOpenTime ? _secondOpenTime[day]! : _secondCloseTime[day]!,
    );

    if (selectedTime == null) {
      return;
    }

    setState(() {
      if (isOpenTime) {
        _secondOpenTime[day] = selectedTime;
      } else {
        _secondCloseTime[day] = selectedTime;
      }
    });
  }

  Future<void> _pickGeneralTime(bool isOpenTime) async {
    final selectedTime = await _showBusinessTimePicker(
      isOpenTime ? _defaultOpenTime : _defaultCloseTime,
    );

    if (selectedTime == null) {
      return;
    }

    setState(() {
      if (isOpenTime) {
        _defaultOpenTime = selectedTime;
      } else {
        _defaultCloseTime = selectedTime;
      }
    });
  }

  Future<void> _pickGeneralSplitTime(bool isOpenTime) async {
    final selectedTime = await _showBusinessTimePicker(
      isOpenTime ? _defaultSecondOpenTime : _defaultSecondCloseTime,
    );

    if (selectedTime == null) {
      return;
    }

    setState(() {
      if (isOpenTime) {
        _defaultSecondOpenTime = selectedTime;
      } else {
        _defaultSecondCloseTime = selectedTime;
      }
    });
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _searchGooglePlaces() async {
    final query = _googlePlaceSearchController.text.trim();
    if (query.length < 2) {
      InputDecorations.showTopSnackBarWarning(
        context,
        "Escribe al menos 2 caracteres para buscar el local en Google Maps.",
      );
      return;
    }

    setState(() {
      _isSearchingGooglePlaces = true;
    });

    try {
      final results = await BusinessService.searchGooglePlacesForBusinessLink(
        query: query,
      );

      if (!mounted) {
        return;
      }

      final mappedResults = results
          .map((item) => BusinessGooglePlace.fromJson(item))
          .toList(growable: false);

      setState(() {
        _googlePlaceResults
          ..clear()
          ..addAll(mappedResults);

        if (_selectedGooglePlace != null) {
          final stillExists = mappedResults.any(
            (place) => place.placeId == _selectedGooglePlace!.placeId,
          );

          if (!stillExists) {
            _selectedGooglePlace = null;
          }
        }
      });

      if (mappedResults.isEmpty && mounted) {
        InputDecorations.showTopSnackBarWarning(
          context,
          "No se encontraron peluquerias/barberias para esa busqueda.",
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      InputDecorations.showTopSnackBarError(
        context,
        "No se pudo consultar Google Places: $e",
      );
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSearchingGooglePlaces = false;
      });
    }
  }

  int _toMinutes(TimeOfDay time) {
    return (time.hour * 60) + time.minute;
  }

  bool _validateCurrentStep() {
    if (_currentStep == 0) {
      if (_selectedGooglePlace == null) {
        InputDecorations.showTopSnackBarWarning(
          context,
          "Debes seleccionar un local real de Google Maps para continuar.",
        );
        return false;
      }
      return true;
    }

    if (_currentStep == 1) {
      final validOffers = _offers.where((offer) {
        final name = offer.nameController.text.trim();
        final price = double.tryParse(offer.priceController.text.trim());
        final duration = int.tryParse(offer.durationController.text.trim());
        return name.isNotEmpty &&
            price != null &&
            price > 0 &&
            duration != null &&
            duration > 0;
      }).toList();

      if (validOffers.isEmpty) {
        InputDecorations.showTopSnackBarWarning(
          context,
          "Agrega al menos una oferta con nombre, precio y duracion validos.",
        );
        return false;
      }

      if (_useSameDurationForAllOffers) {
        final sharedDuration = int.tryParse(
          _sameDurationController.text.trim(),
        );
        if (sharedDuration == null || sharedDuration <= 0) {
          InputDecorations.showTopSnackBarWarning(
            context,
            "La duracion compartida debe ser mayor de 0 minutos.",
          );
          return false;
        }
      }

      return true;
    }

    if (_currentStep == 2) {
      final openDaysCount = _weekDays
          .where((day) => _isOpen[day] == true)
          .length;
      if (openDaysCount == 0) {
        InputDecorations.showTopSnackBarWarning(
          context,
          "Selecciona al menos un dia de trabajo.",
        );
        return false;
      }

      if (!_useScheduleByDays) {
        final openMinutes = _toMinutes(_defaultOpenTime);
        final closeMinutes = _toMinutes(_defaultCloseTime);

        if (closeMinutes <= openMinutes) {
          InputDecorations.showTopSnackBarWarning(
            context,
            "El horario general debe tener hora de cierre mayor a la de apertura.",
          );
          return false;
        }

        if (_defaultIsSplitShift) {
          final secondOpenMinutes = _toMinutes(_defaultSecondOpenTime);
          final secondCloseMinutes = _toMinutes(_defaultSecondCloseTime);

          if (secondCloseMinutes <= secondOpenMinutes) {
            InputDecorations.showTopSnackBarWarning(
              context,
              "El segundo tramo debe tener cierre mayor que apertura.",
            );
            return false;
          }

          if (secondOpenMinutes <= closeMinutes) {
            InputDecorations.showTopSnackBarWarning(
              context,
              "El segundo tramo debe comenzar despues del cierre del primer tramo.",
            );
            return false;
          }
        }

        return true;
      }

      for (final day in _weekDays) {
        if (!_isOpen[day]!) {
          continue;
        }

        final open = _openTime[day]!;
        final close = _closeTime[day]!;
        final openMinutes = _toMinutes(open);
        final closeMinutes = _toMinutes(close);

        if (closeMinutes <= openMinutes) {
          InputDecorations.showTopSnackBarWarning(
            context,
            'El horario de $day debe tener hora de cierre mayor a la de apertura.',
          );
          return false;
        }

        if (_isSplitShift[day]!) {
          final secondOpen = _secondOpenTime[day]!;
          final secondClose = _secondCloseTime[day]!;
          final secondOpenMinutes = _toMinutes(secondOpen);
          final secondCloseMinutes = _toMinutes(secondClose);

          if (secondCloseMinutes <= secondOpenMinutes) {
            InputDecorations.showTopSnackBarWarning(
              context,
              'El segundo tramo de $day debe tener cierre mayor que apertura.',
            );
            return false;
          }

          if (secondOpenMinutes <= closeMinutes) {
            InputDecorations.showTopSnackBarWarning(
              context,
              'El segundo tramo de $day debe comenzar despues del cierre del primer tramo.',
            );
            return false;
          }
        }
      }

      return true;
    }

    return true;
  }

  Future<void> _saveBusiness() async {
    if (!_validateCurrentStep()) {
      return;
    }

    final selectedGooglePlace = _selectedGooglePlace;
    if (selectedGooglePlace == null) {
      InputDecorations.showTopSnackBarWarning(
        context,
        "Debes seleccionar un local de Google Maps.",
      );
      return;
    }

    final offers = _offers
        .map((offer) {
          final name = offer.nameController.text.trim();
          final price = double.tryParse(offer.priceController.text.trim());
          final duration = int.tryParse(offer.durationController.text.trim());
          if (name.isEmpty ||
              price == null ||
              price <= 0 ||
              duration == null ||
              duration <= 0) {
            return null;
          }

          return BusinessOffer(
            name: name,
            price: price,
            durationMinutes: duration,
          );
        })
        .whereType<BusinessOffer>()
        .toList();

    final schedule = _weekDays.map((day) {
      final isOpen = _isOpen[day]!;
      final firstOpen = _useScheduleByDays ? _openTime[day]! : _defaultOpenTime;
      final firstClose = _useScheduleByDays
          ? _closeTime[day]!
          : _defaultCloseTime;
      final secondOpen = _useScheduleByDays
          ? _secondOpenTime[day]!
          : _defaultSecondOpenTime;
      final secondClose = _useScheduleByDays
          ? _secondCloseTime[day]!
          : _defaultSecondCloseTime;
      final isSplitShift =
          isOpen &&
          (_useScheduleByDays ? _isSplitShift[day]! : _defaultIsSplitShift);

      return BusinessDaySchedule(
        day: day,
        isOpen: isOpen,
        openTime: _formatTime(firstOpen),
        closeTime: _formatTime(firstClose),
        isSplitShift: isSplitShift,
        secondOpenTime: isSplitShift ? _formatTime(secondOpen) : '',
        secondCloseTime: isSplitShift ? _formatTime(secondClose) : '',
      );
    }).toList();

    final newBusiness = OwnerBusiness(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: selectedGooglePlace.name,
      offers: offers,
      schedule: schedule,
      scheduleMode: _useScheduleByDays ? 'by_day' : 'single',
      employeeCount: _employeeCount,
      googlePlace: selectedGooglePlace,
    );

    try {
      await OwnerBusinessStorage.addBusiness(newBusiness);
    } catch (e) {
      if (mounted) {
        InputDecorations.showTopSnackBarError(
          context,
          'No se pudo guardar el negocio: $e',
        );
      }
      return;
    }

    if (!mounted) {
      return;
    }

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        foregroundColor: Colors.white,
        title: const Text('Configuracion del negocio'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: List.generate(4, (index) {
                final selected = index <= _currentStep;
                return Expanded(
                  child: Container(
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: selected ? _primaryColor : Colors.white12,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: IndexedStack(
                index: _currentStep,
                children: [
                  _buildGooglePlaceLinkStep(),
                  _buildOffersStep(),
                  _buildScheduleStep(),
                  _buildEmployeesStep(),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(bottom: 50), // 👈 ajusta esto
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _currentStep -= 1;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white30),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Atrás'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (!_validateCurrentStep()) {
                          return;
                        }

                        if (_currentStep == 3) {
                          _saveBusiness();
                          return;
                        }

                        setState(() {
                          _currentStep += 1;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                          side: BorderSide(
                            // borde del botón
                            color: Colors.white, // color del borde
                            width: 1, // grosor del borde
                          ),
                        ),
                      ),
                      child: Text(
                        _currentStep == 3 ? 'Guardar negocio' : 'Siguiente',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGooglePlaceLinkStep() {
    return _buildCard(
      title: '1. Vincular negocio real',
      subtitle:
          'Busca y selecciona el nombre de tu peluqueria o barberia real. El negocio que estás creando en estos momentos se vinculará con Google Maps.',
      child: Column(
        children: [
          TextField(
            controller: _googlePlaceSearchController,
            style: const TextStyle(color: Colors.white),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _searchGooglePlaces(),
            decoration: InputDecoration(
              hintText: 'Ej: Peluquerias low cost',
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: const Color.fromARGB(255, 38, 38, 38),

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: const Color.fromARGB(255, 200, 156, 125),
                  width: 2,
                ),
              ),

              suffixIcon: IconButton(
                onPressed: _isSearchingGooglePlaces
                    ? null
                    : _searchGooglePlaces,
                icon: const Icon(Icons.search),
                color: _primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 12),

          const SizedBox(
            height: 18,
          ), // Distancia entre barra de búsqueda y resultados
          Expanded(
            child: _isSearchingGooglePlaces
                ? const Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  )
                : _googlePlaceResults.isEmpty
                ? const Center(
                    child: Text(
                      'Los resultados más similares a tu búsqueda se mostrarán aquí.',
                      style: TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    itemCount: _googlePlaceResults.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12), // Spacing entre resultados
                    itemBuilder: (context, index) {
                      final place = _googlePlaceResults[index];
                      final selected =
                          _selectedGooglePlace?.placeId == place.placeId;

                      return InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          setState(() {
                            if (_selectedGooglePlace?.placeId ==
                                place.placeId) {
                              _selectedGooglePlace = null; // 👈 deseleccionar
                            } else {
                              _selectedGooglePlace = place; // 👈 seleccionar
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 38, 38, 38),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: selected ? _primaryColor : Colors.white24,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      place.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      place.address,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Icon(
                                selected
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked,
                                color: selected
                                    ? _primaryColor
                                    : Colors.white54,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOffersStep() {
    return _buildCard(
      title: '2. Tipos de ofertas',
      subtitle: 'Agrega servicios junto a su precio y duracion.',
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _useSameDurationForAllOffers,
            activeColor: _primaryColor,
            title: const Text(
              'Misma duracion para todos los servicios',
              style: TextStyle(color: Colors.white),
            ),
            onChanged: (value) {
              setState(() {
                _useSameDurationForAllOffers = value;
                if (_useSameDurationForAllOffers) {
                  if (_sameDurationController.text.trim().isEmpty) {
                    _sameDurationController.text = '30';
                  }
                  _syncDurationToAllOffers();
                }
              });
            },
          ),
          if (_useSameDurationForAllOffers) ...[
            TextField(
              controller: _sameDurationController,
              keyboardType: TextInputType.number,
              onChanged: (value) {
                if (_useSameDurationForAllOffers) {
                  _syncDurationToAllOffers(value);
                }
              },
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Duracion unica (minutos)',
                suffixText: 'min',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Color.fromARGB(255, 200, 156, 125),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          ..._offers.asMap().entries.map((entry) {
            final index = entry.key;
            final offer = entry.value;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 38, 38, 38),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: offer.nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Nombre del servicio',
                      labelStyle: TextStyle(color: Colors.white70),

                      border: OutlineInputBorder(borderSide: BorderSide.none),

                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide.none,
                      ),

                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: const Color.fromARGB(255, 200, 156, 125),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: offer.priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Precio',
                      suffixText: 'EUR',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(borderSide: BorderSide.none),

                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide.none,
                      ),

                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: const Color.fromARGB(255, 200, 156, 125),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: offer.durationController,
                    keyboardType: TextInputType.number,
                    enabled: !_useSameDurationForAllOffers,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Duracion del servicio',
                      suffixText: 'min',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color.fromARGB(255, 200, 156, 125),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_offers.length > 1)
                    Align(
                      alignment: Alignment.centerRight,

                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            final removed = _offers.removeAt(index);
                            removed.dispose();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Color.fromARGB(
                            255,
                            30,
                            30,
                            30,
                          ), // color de fondo
                        ),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        label: const Text(
                          'Quitar',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  final offer = _OfferDraft();
                  if (_useSameDurationForAllOffers) {
                    offer.durationController.text = _sameDurationController.text
                        .trim();
                  }
                  _offers.add(offer);
                });
              },
              icon: const Icon(Icons.add_circle_outline, color: _primaryColor),
              label: const Text(
                'Agregar oferta',
                style: TextStyle(color: _primaryColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleStep() {
    return _buildCard(
      title: '3. Horario del propietario',
      subtitle: _useScheduleByDays
          ? 'Configura el horario de cada dia por separado.'
          : 'Selecciona dias de trabajo y un horario general.',
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _useScheduleByDays = !_useScheduleByDays;
                  if (_useScheduleByDays) {
                    _applyGeneralScheduleToEachDay();
                  }
                });
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: _useScheduleByDays
                    ? _primaryColor
                    : Colors.white,
                side: BorderSide(
                  color: _useScheduleByDays ? _primaryColor : Colors.white24,
                ),
              ),
              icon: Icon(
                _useScheduleByDays
                    ? Icons.calendar_view_week
                    : Icons.calendar_today,
              ),
              label: Text(
                _useScheduleByDays
                    ? 'Horario por dias: activo'
                    : 'Horario por dias: desactivado',
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _useScheduleByDays
                ? _buildScheduleByDayContent()
                : _buildSingleScheduleContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleScheduleContent() {
    return ListView(
      children: [
        const Text(
          'Dias laborables',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _weekDays.map((day) {
            final selected = _isOpen[day]!;
            return FilterChip(
              selected: selected,
              showCheckmark: false,
              selectedColor: _primaryColor,
              backgroundColor: const Color.fromARGB(255, 38, 38, 38),
              labelStyle: TextStyle(
                color: selected ? Colors.black : Colors.white,
                fontWeight: FontWeight.w700,
              ),
              label: Text(day),
              onSelected: (value) {
                setState(() {
                  _isOpen[day] = value;
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 38, 38, 38),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => _pickGeneralTime(true),
                      child: Text(
                        'Apertura ${_formatTime(_defaultOpenTime)}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () => _pickGeneralTime(false),
                      child: Text(
                        'Cierre ${_formatTime(_defaultCloseTime)}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _defaultIsSplitShift,
                activeColor: _primaryColor,
                title: const Text(
                  'Horario partido',
                  style: TextStyle(color: Colors.white),
                ),
                onChanged: (value) {
                  setState(() {
                    _defaultIsSplitShift = value;
                  });
                },
              ),
              if (_defaultIsSplitShift)
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => _pickGeneralSplitTime(true),
                        child: Text(
                          '2a apertura ${_formatTime(_defaultSecondOpenTime)}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () => _pickGeneralSplitTime(false),
                        child: Text(
                          '2o cierre ${_formatTime(_defaultSecondCloseTime)}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleByDayContent() {
    return ListView(
      children: _weekDays.map((day) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 38, 38, 38),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      day,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  Switch(
                    value: _isOpen[day]!,
                    activeColor: _primaryColor,
                    onChanged: (value) {
                      setState(() {
                        _isOpen[day] = value;
                        if (!value) {
                          _isSplitShift[day] = false;
                        }
                      });
                    },
                  ),
                ],
              ),
              if (_isOpen[day]!) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => _pickTime(day, true),
                        child: Text(
                          'Apertura ${_formatTime(_openTime[day]!)}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () => _pickTime(day, false),
                        child: Text(
                          'Cierre ${_formatTime(_closeTime[day]!)}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isSplitShift[day]!,
                  activeColor: _primaryColor,
                  title: const Text(
                    'Horario partido',
                    style: TextStyle(color: Colors.white),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _isSplitShift[day] = value;
                    });
                  },
                ),
                if (_isSplitShift[day]!)
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => _pickSplitTime(day, true),
                          child: Text(
                            '2a apertura ${_formatTime(_secondOpenTime[day]!)}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () => _pickSplitTime(day, false),
                          child: Text(
                            '2o cierre ${_formatTime(_secondCloseTime[day]!)}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmployeesStep() {
    return _buildCard(
      title: '4. Cantidad de empleados',
      subtitle: 'Define cuantas personas atienden en el negocio.',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.groups_2_rounded, color: _primaryColor, size: 56),
          const SizedBox(height: 16),
          Text(
            '$_employeeCount',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  if (_employeeCount <= 0) {
                    return;
                  }
                  setState(() {
                    _employeeCount -= 1;
                  });
                },
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 22),
              IconButton(
                onPressed: () {
                  setState(() {
                    _employeeCount += 1;
                  });
                },
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: _primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _primaryColor,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _OfferDraft {
  _OfferDraft()
    : nameController = TextEditingController(),
      priceController = TextEditingController(),
      durationController = TextEditingController();

  final TextEditingController nameController;
  final TextEditingController priceController;
  final TextEditingController durationController;

  void dispose() {
    nameController.dispose();
    priceController.dispose();
    durationController.dispose();
  }
}

class OwnerBusinessStorage {
  static Future<List<OwnerBusiness>> loadBusinesses() async {
    final businesses = await BusinessService.getMyBusinesses();
    return businesses.map((item) => OwnerBusiness.fromJson(item)).toList();
  }

  static Future<void> addBusiness(OwnerBusiness business) async {
    final requestPayload = business.toJson();
    final createdBusiness = await BusinessService.createBusiness(
      payload: requestPayload,
    );

    final generatedData = {
      'offerCount': business.offers.length,
      'openDaysCount': business.schedule.where((day) => day.isOpen).length,
      'scheduleMode': business.scheduleMode,
      'splitShiftEnabled': business.schedule.any((day) => day.isSplitShift),
      'sameOfferDuration':
          business.offers
              .map((offer) => offer.durationMinutes)
              .toSet()
              .length <=
          1,
      'employeeCount': business.employeeCount,
      'businessName': business.name,
      'googlePlaceId': business.googlePlace?.placeId,
      'googlePlaceName': business.googlePlace?.name,
    };

    await BusinessService.saveBusinessCreationData(
      businessId: createdBusiness['_id'] as String,
      requestPayload: requestPayload,
      generatedData: generatedData,
    );
  }
}

class OwnerBusiness {
  OwnerBusiness({
    required this.id,
    required this.name,
    required this.offers,
    required this.schedule,
    required this.scheduleMode,
    required this.employeeCount,
    this.googlePlace,
  });

  final String id;
  final String name;
  final List<BusinessOffer> offers;
  final List<BusinessDaySchedule> schedule;
  final String scheduleMode;
  final int employeeCount;
  final BusinessGooglePlace? googlePlace;

  factory OwnerBusiness.fromJson(Map<String, dynamic> json) {
    final googlePlaceData = json['googlePlace'];

    return OwnerBusiness(
      id: (json['_id'] ?? json['id']) as String,
      name: json['name'] as String,
      offers: (json['offers'] as List<dynamic>)
          .map((item) => BusinessOffer.fromJson(item as Map<String, dynamic>))
          .toList(),
      schedule: (json['schedule'] as List<dynamic>)
          .map(
            (item) =>
                BusinessDaySchedule.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      scheduleMode: json['scheduleMode']?.toString() == 'by_day'
          ? 'by_day'
          : 'single',
      employeeCount: json['employeeCount'] as int,
      googlePlace: googlePlaceData is Map<String, dynamic>
          ? BusinessGooglePlace.fromJson(googlePlaceData)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'offers': offers.map((item) => item.toJson()).toList(),
      'schedule': schedule.map((item) => item.toJson()).toList(),
      'scheduleMode': scheduleMode,
      'employeeCount': employeeCount,
      if (googlePlace != null) 'googlePlace': googlePlace!.toJson(),
    };
  }
}

class BusinessGooglePlace {
  BusinessGooglePlace({
    required this.placeId,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
  });

  final String placeId;
  final String name;
  final String address;
  final double lat;
  final double lng;

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }

    return 0;
  }

  factory BusinessGooglePlace.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>? ?? const {};

    return BusinessGooglePlace(
      placeId: json['placeId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      lat: _toDouble(location['lat']),
      lng: _toDouble(location['lng']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'placeId': placeId,
      'name': name,
      'address': address,
      'location': {'lat': lat, 'lng': lng},
    };
  }
}

class BusinessOffer {
  BusinessOffer({
    required this.name,
    required this.price,
    required this.durationMinutes,
  });

  final String name;
  final double price;
  final int durationMinutes;

  factory BusinessOffer.fromJson(Map<String, dynamic> json) {
    final rawDuration = json['durationMinutes'];
    final durationFromNumber = rawDuration is num ? rawDuration.toInt() : null;

    return BusinessOffer(
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      durationMinutes:
          durationFromNumber ??
          int.tryParse(rawDuration?.toString() ?? '') ??
          0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'price': price, 'durationMinutes': durationMinutes};
  }
}

class BusinessDaySchedule {
  BusinessDaySchedule({
    required this.day,
    required this.isOpen,
    required this.openTime,
    required this.closeTime,
    this.isSplitShift = false,
    this.secondOpenTime = '',
    this.secondCloseTime = '',
  });

  final String day;
  final bool isOpen;
  final String openTime;
  final String closeTime;
  final bool isSplitShift;
  final String secondOpenTime;
  final String secondCloseTime;

  factory BusinessDaySchedule.fromJson(Map<String, dynamic> json) {
    return BusinessDaySchedule(
      day: json['day'] as String,
      isOpen: json['isOpen'] as bool,
      openTime: json['openTime'] as String,
      closeTime: json['closeTime'] as String,
      isSplitShift: json['isSplitShift'] as bool? ?? false,
      secondOpenTime: json['secondOpenTime']?.toString() ?? '',
      secondCloseTime: json['secondCloseTime']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'isOpen': isOpen,
      'openTime': openTime,
      'closeTime': closeTime,
      'isSplitShift': isSplitShift,
      'secondOpenTime': secondOpenTime,
      'secondCloseTime': secondCloseTime,
    };
  }
}
