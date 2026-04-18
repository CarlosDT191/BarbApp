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
      headers: {
        "Authorization": "Bearer $token"
      },
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
      MaterialPageRoute(
        builder: (_) => const OwnerBusinessSetupFlowPage(),
      ),
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
        
        body: Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
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
                width: 2.0,          // Grosor del borde
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
            textAlign: TextAlign.center
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
                          horizontal: 30,
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
            )
          ]
          else
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
                    const SizedBox(height: 10),
                    const Text(
                      'Ofertas',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...business.offers.map(
                      (offer) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '- ${offer.name}: ${offer.price.toStringAsFixed(2)} EUR',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Horario',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...business.schedule.map(
                      (day) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          day.isOpen
                              ? '- ${day.day}: ${day.openTime} - ${day.closeTime}'
                              : '- ${day.day}: Cerrado',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
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

class _OwnerBusinessSetupFlowPageState extends State<OwnerBusinessSetupFlowPage> {
  static const _primaryColor = Color.fromARGB(255, 200, 156, 125);
  static const _backgroundColor = Color.fromARGB(255, 23, 23, 23);
  static const _cardColor = Color.fromARGB(255, 30, 30, 30);

  final _businessNameController = TextEditingController();
  final List<_OfferDraft> _offers = [
    _OfferDraft(),
  ];

  int _currentStep = 0;
  int _employeeCount = 0;

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
  late Map<String, TimeOfDay> _openTime;
  late Map<String, TimeOfDay> _closeTime;

  @override
  void initState() {
    super.initState();
    _isOpen = {for (final day in _weekDays) day: true};
    _openTime = {
      for (final day in _weekDays) day: const TimeOfDay(hour: 9, minute: 0),
    };
    _closeTime = {
      for (final day in _weekDays) day: const TimeOfDay(hour: 18, minute: 0),
    };
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    for (final offer in _offers) {
      offer.dispose();
    }
    super.dispose();
  }

  Future<void> _pickTime(String day, bool isOpenTime) async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: isOpenTime ? _openTime[day]! : _closeTime[day]!,
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

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  bool _validateCurrentStep() {
    if (_currentStep == 0) {
      final name = _businessNameController.text.trim();
      if (name.isEmpty) {
        InputDecorations.showTopSnackBarWarning(context, "Debes indicar el nombre del negocio.");
        return false;
      }
      return true;
    }

    if (_currentStep == 1) {
      final validOffers = _offers.where((offer) {
        final name = offer.nameController.text.trim();
        final price = double.tryParse(offer.priceController.text.trim());
        return name.isNotEmpty && price != null && price > 0;
      }).toList();

      if (validOffers.isEmpty) {
        InputDecorations.showTopSnackBarWarning(context, "Agrega al menos una oferta con nombre y precio valido.");
        return false;
      }
      return true;
    }

    if (_currentStep == 2) {
      for (final day in _weekDays) {
        if (!_isOpen[day]!) {
          continue;
        }

        final open = _openTime[day]!;
        final close = _closeTime[day]!;
        final openMinutes = open.hour * 60 + open.minute;
        final closeMinutes = close.hour * 60 + close.minute;

        if (closeMinutes <= openMinutes) {
          InputDecorations.showTopSnackBarWarning(context, 'El horario de $day debe tener hora de cierre mayor a la de apertura.');
          return false;
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

    final offers = _offers
        .map((offer) {
          final name = offer.nameController.text.trim();
          final price = double.tryParse(offer.priceController.text.trim());
          if (name.isEmpty || price == null || price <= 0) {
            return null;
          }
          return BusinessOffer(name: name, price: price);
        })
        .whereType<BusinessOffer>()
        .toList();

    final schedule = _weekDays
        .map(
          (day) => BusinessDaySchedule(
            day: day,
            isOpen: _isOpen[day]!,
            openTime: _formatTime(_openTime[day]!),
            closeTime: _formatTime(_closeTime[day]!),
          ),
        )
        .toList();

    final newBusiness = OwnerBusiness(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _businessNameController.text.trim(),
      offers: offers,
      schedule: schedule,
      employeeCount: _employeeCount,
    );

    try {
      await OwnerBusinessStorage.addBusiness(newBusiness);
    } catch (e) {
      if (mounted) {
        InputDecorations.showTopSnackBarError(context, 'No se pudo guardar el negocio: $e');
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
                  _buildBusinessNameStep(),
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
                          side: BorderSide(                 // borde del botón
                            color: Colors.white,            // color del borde
                            width: 1,                       // grosor del borde
                          ),
                        ),
                      ),
                      child: Text(_currentStep == 3 ? 'Guardar negocio' : 'Siguiente'),
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

  Widget _buildBusinessNameStep() {
    return _buildCard(
      title: '1. Nombre del negocio',
      subtitle: 'Define el nombre comercial que verá el cliente que se asocia con tu negocio.',
      child: TextField(
        controller: _businessNameController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Ej: Barberia Central',
          hintStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: const Color.fromARGB(255, 38, 38, 38),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildOffersStep() {
    return _buildCard(
      title: '2. Tipos de ofertas',
      subtitle: 'Agrega servicios como tipos de pelados y su precio.',
      child: Column(
        children: [
          ..._offers.asMap().entries.map((entry) {
            final index = entry.key;
            final offer = entry.value;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 38, 38, 38),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: offer.nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Nombre del servicio',
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: offer.priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Precio',
                      suffixText: 'EUR',
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                  ),
                  if (_offers.length > 1)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            final removed = _offers.removeAt(index);
                            removed.dispose();
                          });
                        },
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
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
                  _offers.add(_OfferDraft());
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
      subtitle: 'Personaliza dias y rangos de atencion.',
      child: ListView(
        children: _weekDays.map((day) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 38, 38, 38),
              borderRadius: BorderRadius.circular(14),
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
                        });
                      },
                    ),
                  ],
                ),
                if (_isOpen[day]!)
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
              ],
            ),
          );
        }).toList(),
      ),
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
                icon: const Icon(Icons.remove_circle_outline, color: Colors.white),
              ),
              const SizedBox(width: 22),
              IconButton(
                onPressed: () {
                  setState(() {
                    _employeeCount += 1;
                  });
                },
                icon: const Icon(Icons.add_circle_outline, color: _primaryColor),
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
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70),
          ),
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
        priceController = TextEditingController();

  final TextEditingController nameController;
  final TextEditingController priceController;

  void dispose() {
    nameController.dispose();
    priceController.dispose();
  }
}

class OwnerBusinessStorage {
  static Future<List<OwnerBusiness>> loadBusinesses() async {
    final businesses = await BusinessService.getMyBusinesses();
    return businesses
        .map((item) => OwnerBusiness.fromJson(item))
        .toList();
  }

  static Future<void> addBusiness(OwnerBusiness business) async {
    final requestPayload = business.toJson();
    final createdBusiness = await BusinessService.createBusiness(payload: requestPayload);

    final generatedData = {
      'offerCount': business.offers.length,
      'openDaysCount': business.schedule.where((day) => day.isOpen).length,
      'employeeCount': business.employeeCount,
      'businessName': business.name,
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
    required this.employeeCount,
  });

  final String id;
  final String name;
  final List<BusinessOffer> offers;
  final List<BusinessDaySchedule> schedule;
  final int employeeCount;

  factory OwnerBusiness.fromJson(Map<String, dynamic> json) {
    return OwnerBusiness(
      id: (json['_id'] ?? json['id']) as String,
      name: json['name'] as String,
      offers: (json['offers'] as List<dynamic>)
          .map((item) => BusinessOffer.fromJson(item as Map<String, dynamic>))
          .toList(),
      schedule: (json['schedule'] as List<dynamic>)
          .map((item) =>
              BusinessDaySchedule.fromJson(item as Map<String, dynamic>))
          .toList(),
      employeeCount: json['employeeCount'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'offers': offers.map((item) => item.toJson()).toList(),
      'schedule': schedule.map((item) => item.toJson()).toList(),
      'employeeCount': employeeCount,
    };
  }
}

class BusinessOffer {
  BusinessOffer({required this.name, required this.price});

  final String name;
  final double price;

  factory BusinessOffer.fromJson(Map<String, dynamic> json) {
    return BusinessOffer(
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
    };
  }
}

class BusinessDaySchedule {
  BusinessDaySchedule({
    required this.day,
    required this.isOpen,
    required this.openTime,
    required this.closeTime,
  });

  final String day;
  final bool isOpen;
  final String openTime;
  final String closeTime;

  factory BusinessDaySchedule.fromJson(Map<String, dynamic> json) {
    return BusinessDaySchedule(
      day: json['day'] as String,
      isOpen: json['isOpen'] as bool,
      openTime: json['openTime'] as String,
      closeTime: json['closeTime'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'isOpen': isOpen,
      'openTime': openTime,
      'closeTime': closeTime,
    };
  }
}
