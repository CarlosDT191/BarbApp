import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/features/calendar/calendar_page.dart';
import 'package:flutter_application_1/features/notifications/notification_page.dart';
import 'package:flutter_application_1/features/profile/profile_page.dart';
import 'package:flutter_application_1/features/business/owner_business_page.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_application_1/models/decorations.dart';
import 'package:flutter_application_1/services/user_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

class HomePageOwner extends StatefulWidget {
  const HomePageOwner({super.key});

  @override
  State<HomePageOwner> createState() => _HomePageOwnerState();
}

class _HomePageOwnerState extends State<HomePageOwner> {
  int _selectedIndex = 2;
  int unread = 0;
  static const int _maxNearbyResults = 60;
  static const int _nearbySearchPageLimit = 3;
  static const int _nearbySearchRadiusMeters = 3500;

  // Hues personalizables para pines: verde apagado, rojo apagado y neutro.
  static const double _pinHueOpen = 110;
  static const double _pinHueClosed = 8;
  static const double _pinHueUnknown = 35;

  LatLng _searchCenter = const LatLng(37.8882, -4.7794);
  Set<Marker> _hairSalonMarkers = {};
  final Map<String, _HairBusiness> _hairBusinessesById = {};
  GoogleMapController? _mapController;
  _HairBusiness? _selectedBusinessForRoute;
  final BitmapDescriptor _openPinIcon =
      BitmapDescriptor.defaultMarkerWithHue(_pinHueOpen);
  final BitmapDescriptor _closedPinIcon =
      BitmapDescriptor.defaultMarkerWithHue(_pinHueClosed);
  final BitmapDescriptor _unknownPinIcon =
      BitmapDescriptor.defaultMarkerWithHue(_pinHueUnknown);

  BitmapDescriptor _markerIconForBusiness(_HairBusiness business) {
    if (business.openNow == true) {
      return _openPinIcon;
    }
    if (business.openNow == false) {
      return _closedPinIcon;
    }
    return _unknownPinIcon;
  }

  Future<void> _initializeNearbySearch() async {
    await _determineSearchCenter();
    await _loadHairBusinesses();
  }

  Future<void> _centerMapOnUserLocation() async {
    await _determineSearchCenter();
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _searchCenter,
          zoom: 15,
        ),
      ),
    );
  }

  void _resetMapOrientation() {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _searchCenter,
          zoom: 15,
          bearing: 0,
          tilt: 0,
        ),
      ),
    );
  }

  Widget _buildMapControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        tooltip: tooltip,
        icon: Icon(icon, color: Color.fromARGB(255, 23, 23, 23)),
        onPressed: onPressed,
      ),
    );
  }

  _HairBusiness? _resolveBusinessForRoute() {
    if (_selectedBusinessForRoute != null) {
      return _selectedBusinessForRoute;
    }
    if (_hairBusinessesById.isEmpty) {
      return null;
    }

    _HairBusiness? nearest;
    double nearestDistance = double.infinity;

    for (final business in _hairBusinessesById.values) {
      final distance = Geolocator.distanceBetween(
        _searchCenter.latitude,
        _searchCenter.longitude,
        business.location.latitude,
        business.location.longitude,
      );

      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = business;
      }
    }

    return nearest;
  }

  Future<void> _openGoogleMapsRoute() async {
    final business = _resolveBusinessForRoute();

    if (business == null) {
      if (mounted) {
        InputDecorations.showTopSnackBarError(context, 'No hay locales disponibles para calcular ruta.');
      }
      return;
    }

    final uri = Uri.https(
      'www.google.com',
      '/maps/dir/',
      {
        'api': '1',
        'origin': '${_searchCenter.latitude},${_searchCenter.longitude}',
        'destination':
            '${business.location.latitude},${business.location.longitude}',
        'travelmode': 'driving',
      },
    );

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!launched && mounted) {
      InputDecorations.showTopSnackBarError(context, 'No se pudo abrir Google Maps.');
    }
  }

  Future<void> _determineSearchCenter() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) {
        return;
      }

      final userCenter = LatLng(position.latitude, position.longitude);
      setState(() {
        _searchCenter = userCenter;
      });
      _mapController?.animateCamera(CameraUpdate.newLatLng(userCenter));
    } catch (_) {
      // Si falla el GPS mantenemos el centro por defecto.
    }
  }

  Future<void> _loadHairBusinesses() async {
    final apiKey = dotenv.env['google_maps_api_key'];
    if (apiKey == null || apiKey.isEmpty) {
      return;
    }

    final places = await _fetchNearbyPlaces(apiKey: apiKey);
    final businessesById = <String, _HairBusiness>{};

    for (final place in places) {
      final placeId = place['place_id'] as String?;
      final geometry = place['geometry'] as Map<String, dynamic>?;
      final location = geometry?['location'] as Map<String, dynamic>?;
      final lat = location?['lat'];
      final lng = location?['lng'];

      if (placeId == null || lat is! num || lng is! num) {
        continue;
      }

      final openingData = place['opening_hours'] as Map<String, dynamic>?;

      businessesById[placeId] = _HairBusiness(
        id: placeId,
        name: place['name']?.toString() ?? 'Peluqueria',
        address: place['vicinity']?.toString() ?? 'Direccion no disponible',
        location: LatLng(lat.toDouble(), lng.toDouble()),
        openNow: openingData?['open_now'] as bool?,
        rating: (place['rating'] as num?)?.toDouble(),
      );
    }

    if (!mounted) {
      return;
    }

    final businesses = businessesById.values.take(_maxNearbyResults).toList();

    setState(() {
      _hairBusinessesById
        ..clear()
        ..addAll(businessesById);

      _hairSalonMarkers = businesses
          .map(
            (business) => Marker(
              markerId: MarkerId(business.id),
              position: business.location,
              infoWindow: InfoWindow(title: business.name),
              icon: _markerIconForBusiness(business),
              onTap: () {
                _selectedBusinessForRoute = business;
                _showSalonInfoSheet(business.id);
              },
            ),
          )
          .toSet();
    });
  }

  Uri _buildNearbySearchUri(String apiKey) {
    return Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
      '?location=${_searchCenter.latitude},${_searchCenter.longitude}'
      '&radius=$_nearbySearchRadiusMeters'
      '&type=hair_care'
      '&keyword=peluqueria'
      '&language=es'
      '&key=$apiKey',
    );
  }

  Uri _buildNearbySearchTokenUri({
    required String apiKey,
    required String pageToken,
  }) {
    return Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
      '?pagetoken=$pageToken'
      '&key=$apiKey',
    );
  }

  Future<Map<String, dynamic>?> _requestNearbyPage(Uri uri) async {
    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        return null;
      }

      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _requestNearbyPageWithToken({
    required String apiKey,
    required String pageToken,
  }) async {
    for (int attempt = 0; attempt < 3; attempt++) {
      await Future.delayed(const Duration(seconds: 2));
      final page = await _requestNearbyPage(
        _buildNearbySearchTokenUri(apiKey: apiKey, pageToken: pageToken),
      );
      if (page == null) {
        return null;
      }

      final status = page['status']?.toString() ?? '';
      if (status != 'INVALID_REQUEST') {
        return page;
      }
    }

    return null;
  }

  Future<List<Map<String, dynamic>>> _fetchNearbyPlaces({
    required String apiKey,
  }) async {
    final collected = <Map<String, dynamic>>[];
    String? nextPageToken;
    int fetchedPages = 0;

    while (fetchedPages < _nearbySearchPageLimit && collected.length < _maxNearbyResults) {
      final page = nextPageToken == null
          ? await _requestNearbyPage(_buildNearbySearchUri(apiKey))
          : await _requestNearbyPageWithToken(
              apiKey: apiKey,
              pageToken: nextPageToken,
            );

      if (page == null) {
        break;
      }

      final status = page['status']?.toString() ?? '';
      if (status == 'ZERO_RESULTS') {
        break;
      }
      if (status != 'OK') {
        break;
      }

      final pageResults =
          (page['results'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<Map<String, dynamic>>();

      collected.addAll(pageResults);
      nextPageToken = page['next_page_token']?.toString();
      fetchedPages++;

      if (nextPageToken == null) {
        break;
      }
    }

    return collected;
  }

  Future<_HairBusiness> _fetchHairBusinessDetails(String placeId) async {
    final apiKey = dotenv.env['google_maps_api_key'];
    final current = _hairBusinessesById[placeId];

    if (apiKey == null || apiKey.isEmpty || current == null) {
      throw Exception('No se pudo obtener la informacion del local.');
    }

    final uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json'
      '?place_id=$placeId'
      '&fields=name,formatted_address,opening_hours,current_opening_hours,formatted_phone_number,rating'
      '&language=es'
      '&key=$apiKey',
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Error al cargar el detalle.');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final result = body['result'] as Map<String, dynamic>?;
    if (result == null) {
      return current;
    }

    final openingHours = ((result['current_opening_hours'] as Map<String, dynamic>?)?['weekday_text'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        ((result['opening_hours'] as Map<String, dynamic>?)?['weekday_text'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList();

    return _HairBusiness(
      id: current.id,
      name: result['name']?.toString() ?? current.name,
      address: result['formatted_address']?.toString() ?? current.address,
      location: current.location,
      openNow: current.openNow,
      rating: (result['rating'] as num?)?.toDouble() ?? current.rating,
      openingHours: openingHours,
      phone: result['formatted_phone_number']?.toString(),
    );
  }

  void _showSalonInfoSheet(String placeId) {
    _selectedBusinessForRoute =
        _hairBusinessesById[placeId] ?? _selectedBusinessForRoute;

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return FutureBuilder<_HairBusiness>(
          future: _fetchHairBusinessDetails(placeId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 170,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final business = snapshot.data!;
            final firstHoursLine = (business.openingHours != null && business.openingHours!.isNotEmpty)
                ? business.openingHours!.first
                : 'Horario no disponible';

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      business.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(business.address)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(firstHoursLine)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.storefront_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          business.openNow == null
                              ? 'Estado: no disponible'
                              : (business.openNow! ? 'Abierto ahora' : 'Cerrado ahora'),
                        ),
                      ],
                    ),
                    if (business.rating != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star_rate_rounded, size: 18, color: Colors.amber),
                          const SizedBox(width: 8),
                          Text('Valoracion: ${business.rating!.toStringAsFixed(1)}'),
                        ],
                      ),
                    ],
                    if (business.phone != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(business.phone!)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Obtiene el token JWT almacenado del usuario.
  ///
  /// Retorna un `String` con el token o `null` si no existe en [SharedPreferences].
  /// El token se utiliza para autenticar las solicitudes HTTP al backend.
  Future<String?> getUserToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  /// Obtiene los datos del usuario desde el backend.
  ///
  /// Requiere un token JWT válido almacenado localmente.
  /// Retorna un `Map<String, dynamic>` con los datos del usuario incluyendo
  /// email, nombre, apellido y rol del usuario autenticado.
  Future<Map<String, dynamic>> getUserData() async {

    final token = await getUserToken();
    final apiBaseUrl = getApiBaseUrl();
    final response = await http.get(
      Uri.parse("$apiBaseUrl/users/me"),
      headers: {
        "Authorization": "Bearer $token"
      },
    );

    return jsonDecode(response.body);
  }

  /// Maneja la navegación cuando se presiona un ícono de la barra inferior.
  ///
  /// [index] es el índice del ícono presionado, del 0 al 4 (`int`).
  ///
  /// Navega a diferentes páginas según el índice seleccionado.
  void _onItemTapped(int index) {
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
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const OwnerBusinessPage()),
        );
        break;
      case 2:
        print("Mapa pulsado");
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => NotificationPage()),
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

  /// Obtiene el rol del usuario desde [SharedPreferences].
  ///
  /// Los roles disponibles son: 0=cliente, 1=propietario, 2=admin.
  /// Retorna un `int` con el rol del usuario o `null` si no existe.
  Future<int?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("role");
  }

  /// Obtiene el número de notificaciones no leídas.
  ///
  /// Lee el contador almacenado en [SharedPreferences].
  /// Retorna un `int` con el número total de notificaciones sin leer.
  Future<int> getUnreadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("unread_notifications") ?? 0;
  }

  @override
  void initState() {
    super.initState();
    initNotifications();
    _initializeNearbySearch();
  }

  /// Inicializa y actualiza el listado de notificaciones no leídas.
  ///
  /// Obtiene los datos del servidor mediante [UserService.updateUnreadNotifications]
  /// y actualiza el estado local con el conteo de notificaciones sin leer.
  void initNotifications() async {
    await UserService.updateUnreadNotifications(); // API
    int unread = await getUnreadNotifications(); // local

    setState(() {
      this.unread = unread;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

        // BARRA INFERIOR CON LOS ICONOS
        bottomNavigationBar: InputDecorations.mainBottomNavBar(
          context: context,
          currentIndex: 2,
          owner: true,
          onTap: _onItemTapped,
          unreadNotifications: unread
        ),

        body: Stack(
          children: [

            GoogleMap(
              onMapCreated: (controller) {
                _mapController = controller;
                _mapController?.animateCamera(CameraUpdate.newLatLng(_searchCenter));
              },
              initialCameraPosition: CameraPosition(
                target: _searchCenter,
                zoom: 14,
              ),
              markers: _hairSalonMarkers,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              compassEnabled: false,
              zoomControlsEnabled: false,
            ),

            // 👉 BARRA DE BÚSQUEDA FLOTANTE
            Positioned(
              top: 50,
              left: 16,
              right: 16,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    )
                  ],
                ),
                child: Row(
                  children: [

                    SizedBox(width: 15),

                    Icon(Icons.search, color: Colors.grey),

                    SizedBox(width: 8),

                    // 👉 INPUT
                    Expanded(
                      child: TextField(
                        style: TextStyle(
                          color: Colors.black, // 👈 color del texto que escribe el usuario
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: "Buscar locales",
                          hintStyle: TextStyle(
                          color: Colors.grey, // 👈 color del placeholder
                        ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    // 👉 ICONO DE FILTROS
                    IconButton(
                      icon: Icon(Icons.tune, color: Colors.grey),
                      onPressed: () {
                        print("Filtros pulsado");
                      },
                    ),

                    SizedBox(width: 1),
                  ],
                ),
              ),
            ),

            Positioned(
              left: 16,
              bottom: 20,
              child: _buildMapControlButton(
                icon: Icons.directions_rounded,
                tooltip: 'Abrir ruta en Google Maps',
                onPressed: _openGoogleMapsRoute,
              ),
            ),

            Positioned(
              right: 16,
              bottom: 20,
              child: Column(
                children: [
                  _buildMapControlButton(
                    icon: Icons.my_location,
                    tooltip: 'Centrar en mi ubicacion',
                    onPressed: _centerMapOnUserLocation,
                  ),
                  const SizedBox(height: 10),
                  _buildMapControlButton(
                    icon: Icons.explore,
                    tooltip: 'Orientar mapa al norte',
                    onPressed: _resetMapOrientation,
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }
}

class _HairBusiness {
  const _HairBusiness({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    this.openNow,
    this.rating,
    this.openingHours,
    this.phone,
  });

  final String id;
  final String name;
  final String address;
  final LatLng location;
  final bool? openNow;
  final double? rating;
  final List<String>? openingHours;
  final String? phone;
}
