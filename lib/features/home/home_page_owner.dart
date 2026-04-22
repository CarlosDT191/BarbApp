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
import 'package:flutter_application_1/services/business_service.dart';
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
  static const Color _primaryColor = Color.fromARGB(255, 200, 156, 125);
  static const Color _registeredSheetBackgroundColor = Color.fromARGB(
    255,
    23,
    23,
    23,
  );
  static const Color _registeredCardColor = Color.fromARGB(255, 30, 30, 30);

  int _selectedIndex = 2;
  int unread = 0;
  int _nearbyFoundCount = 0;
  bool _hasCompletedNearbySearch = false;
  static const int _maxNearbyResults =
      60; // Máximo límite de locales para la API de Google Places.
  static const int _nearbySearchPageLimit = 3;
  static const int _nearbySearchRadiusMeters =
      500; // Radio de búsqueda reducido a 500 metros para encontrar más cercanos.
  static const String _mapStatePrefsKey = 'home_page_owner_map_state_v1';
  static const double _defaultMapZoom = 14;
  static const List<String> _businessKeywords = ['peluqueria', 'barberia'];
  static const List<String> _placeTypes = ['barber_shop', 'hair_care'];

  // Hues personalizables para pines: verde apagado, rojo apagado y neutro.
  static const double _pinHueOpen = 110; // VERDE ES 120, apagado es 110
  static const double _pinHueClosed = 20; // ROJO ES 0, apagado es 20
  static const double _pinHueUnknown = 300;

  LatLng _searchCenter = const LatLng(37.8882, -4.7794);
  LatLng _currentMapTarget = const LatLng(37.8882, -4.7794);
  double _currentZoom = 14.0;
  Set<Marker> _hairSalonMarkers = {};
  Set<Circle> _searchAreaCircles = {};
  final Map<String, _HairBusiness> _hairBusinessesById = {};
  final Map<String, Map<String, dynamic>> _registeredBusinessesByPlaceId = {};
  final Map<String, PageController> _photoControllersByPlaceId = {};
  GoogleMapController? _mapController;
  _HairBusiness? _selectedBusinessForRoute;
  bool _isLoadingNearbyBusinesses = false;
  // RADIO DEL CÍRCULO
  double _searchCircleRadiusMeters = _nearbySearchRadiusMeters.toDouble();
  CameraPosition _lastCameraPosition = const CameraPosition(
    target: LatLng(37.8882, -4.7794),
    zoom: _defaultMapZoom,
  );
  final BitmapDescriptor _openPinIcon = BitmapDescriptor.defaultMarkerWithHue(
    _pinHueOpen,
  );
  final BitmapDescriptor _closedPinIcon = BitmapDescriptor.defaultMarkerWithHue(
    _pinHueClosed,
  );
  final BitmapDescriptor _unknownPinIcon =
      BitmapDescriptor.defaultMarkerWithHue(_pinHueUnknown);

  Circle _buildSearchCircle(LatLng center) {
    return Circle(
      circleId: const CircleId('search-radius-circle'),
      center: center,
      radius: 1000.0,
      strokeColor: const Color.fromARGB(255, 200, 156, 125),
      strokeWidth: 2,
      fillColor: const Color.fromARGB(255, 200, 156, 125).withOpacity(0.12),
    );
  }

  Set<Marker> _buildMarkersFromBusinesses(Iterable<_HairBusiness> businesses) {
    return businesses
        .map(
          (business) => Marker(
            markerId: MarkerId(business.id),
            position: business.location,
            icon: _markerIconForBusiness(business),
            onTap: () {
              _selectedBusinessForRoute = business;
              _mapController?.hideMarkerInfoWindow(MarkerId(business.id));
              _showSalonInfoSheet(business.id);
            },
          ),
        )
        .toSet();
  }

  @override
  void dispose() {
    for (final controller in _photoControllersByPlaceId.values) {
      controller.dispose();
    }
    _photoControllersByPlaceId.clear();
    _mapController?.dispose();
    super.dispose();
  }

  PageController _getPhotoPageController(String placeId) {
    return _photoControllersByPlaceId.putIfAbsent(
      placeId,
      () => PageController(viewportFraction: 0.93),
    );
  }

  String _formatReviewCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  Uri? _buildBusinessPhotoUri(String photoReference, {int maxWidth = 1100}) {
    final apiKey = dotenv.env['google_maps_api_key'];
    if (apiKey == null || apiKey.isEmpty || photoReference.trim().isEmpty) {
      return null;
    }

    return Uri.parse(
      'https://maps.googleapis.com/maps/api/place/photo',
    ).replace(
      queryParameters: {
        'maxwidth': '$maxWidth',
        'photoreference': photoReference,
        'key': apiKey,
      },
    );
  }

  Future<void> _syncRegisteredBusinesses(Iterable<String> placeIds) async {
    try {
      final registeredByPlaceId =
          await BusinessService.getRegisteredBusinessesByPlaceIds(
            placeIds.toList(growable: false),
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _registeredBusinessesByPlaceId
          ..clear()
          ..addAll(registeredByPlaceId);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _registeredBusinessesByPlaceId.clear();
      });
    }
  }

  Map<String, double> _latLngToMap(LatLng value) {
    return {'lat': value.latitude, 'lng': value.longitude};
  }

  double? _asDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  bool? _asBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is String) {
      if (value.toLowerCase() == 'true') {
        return true;
      }
      if (value.toLowerCase() == 'false') {
        return false;
      }
    }
    return null;
  }

  Map<String, dynamic> _businessToJson(_HairBusiness business) {
    return {
      'id': business.id,
      'name': business.name,
      'address': business.address,
      'lat': business.location.latitude,
      'lng': business.location.longitude,
      'openNow': business.openNow,
      'rating': business.rating,
      'reviewCount': business.reviewCount,
      'openingHours': business.openingHours,
      'phone': business.phone,
      'photoReferences': business.photoReferences,
    };
  }

  Future<void> _persistMapState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final state = {
        'searchCenter': _latLngToMap(_searchCenter),
        'currentMapTarget': _latLngToMap(_currentMapTarget),
        'camera': {
          'lat': _lastCameraPosition.target.latitude,
          'lng': _lastCameraPosition.target.longitude,
          'zoom': _lastCameraPosition.zoom,
          'bearing': _lastCameraPosition.bearing,
          'tilt': _lastCameraPosition.tilt,
        },
        'searchCircleRadiusMeters': _searchCircleRadiusMeters,
        'businesses': _hairBusinessesById.values
            .map(_businessToJson)
            .toList(growable: false),
      };

      await prefs.setString(_mapStatePrefsKey, jsonEncode(state));
    } catch (_) {
      // Ignoramos errores de cache para no bloquear la UI.
    }
  }

  Future<bool> _restoreMapState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawState = prefs.getString(_mapStatePrefsKey);
      if (rawState == null || rawState.isEmpty) {
        return false;
      }

      final decoded = jsonDecode(rawState);
      if (decoded is! Map<String, dynamic>) {
        return false;
      }

      final searchCenterData = decoded['searchCenter'];
      final currentTargetData = decoded['currentMapTarget'];
      final cameraData = decoded['camera'];
      if (searchCenterData is! Map<String, dynamic> ||
          currentTargetData is! Map<String, dynamic> ||
          cameraData is! Map<String, dynamic>) {
        return false;
      }

      final searchLat = _asDouble(searchCenterData['lat']);
      final searchLng = _asDouble(searchCenterData['lng']);
      final targetLat = _asDouble(currentTargetData['lat']);
      final targetLng = _asDouble(currentTargetData['lng']);
      final cameraLat = _asDouble(cameraData['lat']);
      final cameraLng = _asDouble(cameraData['lng']);
      final cameraZoom = _asDouble(cameraData['zoom']);
      final cameraBearing = _asDouble(cameraData['bearing']) ?? 0;
      final cameraTilt = _asDouble(cameraData['tilt']) ?? 0;

      if (searchLat == null ||
          searchLng == null ||
          targetLat == null ||
          targetLng == null ||
          cameraLat == null ||
          cameraLng == null ||
          cameraZoom == null) {
        return false;
      }

      final restoredSearchCenter = LatLng(searchLat, searchLng);
      final restoredCurrentTarget = LatLng(targetLat, targetLng);
      final restoredCameraPosition = CameraPosition(
        target: LatLng(cameraLat, cameraLng),
        zoom: cameraZoom,
        bearing: cameraBearing,
        tilt: cameraTilt,
      );

      final restoredBusinesses = <String, _HairBusiness>{};
      final businessesRaw = decoded['businesses'];
      if (businessesRaw is List) {
        for (final rawBusiness in businessesRaw) {
          if (rawBusiness is! Map<String, dynamic>) {
            continue;
          }

          final id = rawBusiness['id']?.toString();
          final name = rawBusiness['name']?.toString();
          final address = rawBusiness['address']?.toString();
          final lat = _asDouble(rawBusiness['lat']);
          final lng = _asDouble(rawBusiness['lng']);

          if (id == null ||
              name == null ||
              address == null ||
              lat == null ||
              lng == null) {
            continue;
          }

          final openingHoursRaw = rawBusiness['openingHours'];
          final openingHours = openingHoursRaw is List
              ? openingHoursRaw.map((value) => value.toString()).toList()
              : null;

          final photoReferencesRaw = rawBusiness['photoReferences'];
          final photoReferences = photoReferencesRaw is List
              ? photoReferencesRaw
                    .map((value) => value.toString().trim())
                    .where((value) => value.isNotEmpty)
                    .toList(growable: false)
              : null;

          final reviewCount = rawBusiness['reviewCount'];

          restoredBusinesses[id] = _HairBusiness(
            id: id,
            name: name,
            address: address,
            location: LatLng(lat, lng),
            openNow: _asBool(rawBusiness['openNow']),
            rating: _asDouble(rawBusiness['rating']),
            reviewCount: reviewCount is num ? reviewCount.toInt() : null,
            openingHours: openingHours,
            phone: rawBusiness['phone']?.toString(),
            photoReferences: photoReferences,
          );
        }
      }

      final restoredRadius =
          _asDouble(decoded['searchCircleRadiusMeters']) ??
          _searchCircleRadiusMeters;

      if (!mounted) {
        return true;
      }

      setState(() {
        _searchCenter = restoredSearchCenter;
        _currentMapTarget = restoredCurrentTarget;
        _lastCameraPosition = restoredCameraPosition;
        _searchCircleRadiusMeters = restoredRadius;

        _hairBusinessesById
          ..clear()
          ..addAll(restoredBusinesses);

        _hairSalonMarkers = _buildMarkersFromBusinesses(
          restoredBusinesses.values,
        );
        _nearbyFoundCount = restoredBusinesses.length;
        _hasCompletedNearbySearch = true;
        _searchAreaCircles = {_buildSearchCircle(restoredSearchCenter)};
      });

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(_lastCameraPosition),
      );

      await _syncRegisteredBusinesses(restoredBusinesses.keys);

      return true;
    } catch (_) {
      return false;
    }
  }

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
    final restored = await _restoreMapState();
    if (restored) {
      return;
    }

    await _determineSearchCenter();
    await _loadHairBusinesses();
  }

  Future<void> _centerMapOnUserLocation() async {
    await _determineSearchCenter();
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _searchCenter, zoom: _currentZoom),
      ),
    );
  }

  Future<void> _refreshBusinessesAroundCurrentView() async {
    setState(() {
      _searchCenter = _currentMapTarget;
      _selectedBusinessForRoute = null;
    });

    await _loadHairBusinesses();
  }

  void _resetMapOrientation() {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _currentMapTarget,
          zoom: _currentZoom,
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
    required bool inverted,
  }) {
    Color primaryColor = Color.fromARGB(255, 23, 23, 23);
    Color secondaryColor = Colors.white;
    if (inverted) {
      primaryColor = Colors.white;
      secondaryColor = Color.fromARGB(255, 23, 23, 23);
    }
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: secondaryColor, // COLOR DE FONDO DEL BOTON
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: IconButton(
        tooltip: tooltip,
        icon: Icon(icon, color: primaryColor), // COLOR DEL ICONO
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
        InputDecorations.showTopSnackBarError(
          context,
          'No hay locales disponibles para calcular ruta.',
        );
      }
      return;
    }

    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'origin': '${_searchCenter.latitude},${_searchCenter.longitude}',
      'destination':
          '${business.location.latitude},${business.location.longitude}',
      'travelmode': 'driving',
    });

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!launched && mounted) {
      InputDecorations.showTopSnackBarError(
        context,
        'No se pudo abrir Google Maps.',
      );
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

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
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
        _currentMapTarget = userCenter;
        _lastCameraPosition = CameraPosition(
          target: userCenter,
          zoom: _currentZoom,
          bearing: 0,
          tilt: 0,
        );
      });
      _mapController?.animateCamera(CameraUpdate.newLatLng(userCenter));
      await _persistMapState();
    } catch (_) {
      // Si falla el GPS mantenemos el centro por defecto.
    }
  }

  Future<void> _loadHairBusinesses() async {
    final apiKey = dotenv.env['google_maps_api_key'];
    if (apiKey == null || apiKey.isEmpty) {
      return;
    }

    final searchOrigin = _searchCenter;
    if (mounted) {
      setState(() {
        _isLoadingNearbyBusinesses = true;
        _nearbyFoundCount = 0;
        _hasCompletedNearbySearch = false;
        _searchAreaCircles = {_buildSearchCircle(searchOrigin)};
      });
    }

    try {
      final places = await _fetchNearbyPlaces(
        apiKey: apiKey,
        onProgressCount: (count) {
          if (!mounted) {
            return;
          }

          setState(() {
            _nearbyFoundCount = count;
          });
        },
      );
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
        final photosRaw = place['photos'] as List<dynamic>?;
        final photoReferences = photosRaw
            ?.whereType<Map<String, dynamic>>()
            .map((photo) => photo['photo_reference']?.toString().trim() ?? '')
            .where((photoReference) => photoReference.isNotEmpty)
            .toList(growable: false);

        businessesById[placeId] = _HairBusiness(
          id: placeId,
          name: place['name']?.toString() ?? 'Peluqueria',
          address: place['vicinity']?.toString() ?? 'Direccion no disponible',
          location: LatLng(lat.toDouble(), lng.toDouble()),
          openNow: openingData?['open_now'] as bool?,
          rating: (place['rating'] as num?)?.toDouble(),
          reviewCount: (place['user_ratings_total'] as num?)?.toInt(),
          photoReferences: photoReferences == null || photoReferences.isEmpty
              ? null
              : photoReferences,
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

        _hairSalonMarkers = _buildMarkersFromBusinesses(businesses);
        _nearbyFoundCount = businesses.length;
        _hasCompletedNearbySearch = true;
        _searchAreaCircles = {_buildSearchCircle(searchOrigin)};
      });

      await _syncRegisteredBusinesses(businessesById.keys);
      await _persistMapState();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingNearbyBusinesses = false;
        });
      }
    }
  }

  Uri _buildNearbySearchUri({
    required String apiKey,
    required String keyword,
    required String type,
  }) {
    final encodedKeyword = Uri.encodeQueryComponent(keyword);

    return Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
      '?location=${_searchCenter.latitude},${_searchCenter.longitude}'
      '&radius=$_nearbySearchRadiusMeters'
      '&type=$type'
      '&keyword=$encodedKeyword'
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
    void Function(int count)? onProgressCount,
  }) async {
    final collected = <Map<String, dynamic>>[];
    final seenPlaceIds = <String>{};

    for (final keyword in _businessKeywords) {
      for (final type in _placeTypes) {
        String? nextPageToken;
        int fetchedPages = 0;

        while (fetchedPages < _nearbySearchPageLimit &&
            collected.length < _maxNearbyResults) {
          final page = nextPageToken == null
              ? await _requestNearbyPage(
                  _buildNearbySearchUri(
                    apiKey: apiKey,
                    keyword: keyword,
                    type: type,
                  ),
                )
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

          for (final result in pageResults) {
            final placeId = result['place_id']?.toString();
            if (placeId == null || seenPlaceIds.contains(placeId)) {
              continue;
            }

            seenPlaceIds.add(placeId);
            collected.add(result);

            if (collected.length >= _maxNearbyResults) {
              break;
            }
          }

          onProgressCount?.call(collected.length);

          nextPageToken = page['next_page_token']?.toString();
          fetchedPages++;

          if (nextPageToken == null || collected.length >= _maxNearbyResults) {
            break;
          }
        }

        if (collected.length >= _maxNearbyResults) {
          break;
        }
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
      '&fields=name,formatted_address,opening_hours,current_opening_hours,formatted_phone_number,rating,user_ratings_total,photos'
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

    final openingHours =
        ((result['current_opening_hours']
                    as Map<String, dynamic>?)?['weekday_text']
                as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        ((result['opening_hours'] as Map<String, dynamic>?)?['weekday_text']
                as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList();

    final photosRaw = result['photos'] as List<dynamic>?;
    final photoReferences = photosRaw
        ?.whereType<Map<String, dynamic>>()
        .map((photo) => photo['photo_reference']?.toString().trim() ?? '')
        .where((photoReference) => photoReference.isNotEmpty)
        .toList(growable: false);

    return _HairBusiness(
      id: current.id,
      name: result['name']?.toString() ?? current.name,
      address: result['formatted_address']?.toString() ?? current.address,
      location: current.location,
      openNow: current.openNow,
      rating: (result['rating'] as num?)?.toDouble() ?? current.rating,
      reviewCount:
          (result['user_ratings_total'] as num?)?.toInt() ??
          current.reviewCount,
      openingHours: openingHours,
      phone: result['formatted_phone_number']?.toString(),
      photoReferences: photoReferences == null || photoReferences.isEmpty
          ? current.photoReferences
          : photoReferences,
    );
  }

  void _showSalonInfoSheet(String placeId) {
    _selectedBusinessForRoute =
        _hairBusinessesById[placeId] ?? _selectedBusinessForRoute;

    final registeredBusiness = _registeredBusinessesByPlaceId[placeId];
    final isRegistered = registeredBusiness != null;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FutureBuilder<_HairBusiness>(
          future: _fetchHairBusinessDetails(placeId),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done &&
                !snapshot.hasData) {
              return const SizedBox(
                height: 170,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (!snapshot.hasData) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                child: const Text(
                  'No se pudo cargar el detalle del local.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              );
            }

            final business = snapshot.data!;
            final firstHoursLine =
                (business.openingHours != null &&
                    business.openingHours!.isNotEmpty)
                ? business.openingHours!.first
                : 'Horario no disponible';

            final titleColor = isRegistered
                ? _primaryColor
                : const Color.fromARGB(255, 23, 23, 23);
            final secondaryTextColor = isRegistered
                ? Colors.white70
                : const Color.fromARGB(255, 78, 78, 78);
            final iconColor = isRegistered
                ? _primaryColor
                : const Color.fromARGB(255, 65, 65, 65);
            final containerColor = isRegistered
                ? _registeredSheetBackgroundColor
                : Colors.white;
            final infoCardColor = isRegistered
                ? _registeredCardColor
                : const Color.fromARGB(255, 246, 246, 246);
            final photos = business.photoReferences ?? const <String>[];

            return SafeArea(
              top: false,
              child: Container(
                decoration: BoxDecoration(
                  color: containerColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isRegistered
                                ? Colors.white30
                                : const Color.fromARGB(255, 205, 205, 205),
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (photos.isNotEmpty)
                        _buildPhotoCarousel(
                          placeId: placeId,
                          photoReferences: photos,
                          isRegistered: isRegistered,
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    business.name,
                                    style: TextStyle(
                                      fontSize: 23,
                                      fontWeight: FontWeight.w800,
                                      color: titleColor,
                                    ),
                                  ),
                                ),
                                if (isRegistered)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 8, top: 2),
                                    child: Icon(
                                      Icons.verified_rounded,
                                      color: _primaryColor,
                                      size: 28,
                                    ),
                                  ),
                              ],
                            ),
                            if (isRegistered) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Local registrado en BarbApp',
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            if (business.rating != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: infoCardColor,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    Row(
                                      children: _buildRatingStars(
                                        business.rating!,
                                        size: 23,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      business.rating!.toStringAsFixed(1),
                                      style: TextStyle(
                                        color: titleColor,
                                        fontSize: 30,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        business.reviewCount == null
                                            ? 'Valoracion basada en usuarios'
                                            : '${_formatReviewCount(business.reviewCount!)} reseñas',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: secondaryTextColor,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: infoCardColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  _buildDetailRow(
                                    icon: Icons.location_on_outlined,
                                    iconColor: iconColor,
                                    textColor: secondaryTextColor,
                                    text: business.address,
                                  ),
                                  const SizedBox(height: 10),
                                  _buildDetailRow(
                                    icon: Icons.access_time,
                                    iconColor: iconColor,
                                    textColor: secondaryTextColor,
                                    text: firstHoursLine,
                                  ),
                                  const SizedBox(height: 10),
                                  _buildDetailRow(
                                    icon: Icons.storefront_outlined,
                                    iconColor: iconColor,
                                    textColor: secondaryTextColor,
                                    text: business.openNow == null
                                        ? 'Estado: no disponible'
                                        : (business.openNow!
                                              ? 'Abierto ahora'
                                              : 'Cerrado ahora'),
                                  ),
                                  if (business.phone != null) ...[
                                    const SizedBox(height: 10),
                                    _buildDetailRow(
                                      icon: Icons.phone_outlined,
                                      iconColor: iconColor,
                                      textColor: secondaryTextColor,
                                      text: business.phone!,
                                    ),
                                  ],
                                ],
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
          },
        );
      },
    );
  }

  Widget _buildPhotoCarousel({
    required String placeId,
    required List<String> photoReferences,
    required bool isRegistered,
  }) {
    final totalPhotos = photoReferences.length > 10
        ? 10
        : photoReferences.length;
    final pageController = _getPhotoPageController(placeId);
    final fallbackBackground = isRegistered
        ? _registeredCardColor
        : const Color.fromARGB(255, 238, 238, 238);

    return SizedBox(
      height: 210,
      child: PageView.builder(
        controller: pageController,
        itemCount: totalPhotos,
        itemBuilder: (context, index) {
          final imageUri = _buildBusinessPhotoUri(photoReferences[index]);

          return Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 16 : 6,
              right: index == totalPhotos - 1 ? 16 : 6,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                color: fallbackBackground,
                child: imageUri == null
                    ? Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: isRegistered ? Colors.white54 : Colors.black38,
                          size: 32,
                        ),
                      )
                    : Image.network(
                        imageUri.toString(),
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) {
                            return child;
                          }

                          return Center(
                            child: CircularProgressIndicator(
                              color: isRegistered
                                  ? _primaryColor
                                  : Colors.black45,
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) {
                          return Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: isRegistered
                                  ? Colors.white54
                                  : Colors.black38,
                              size: 32,
                            ),
                          );
                        },
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String text,
    required Color iconColor,
    required Color textColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildRatingStars(double rating, {double size = 22}) {
    final clamped = rating.clamp(0, 5);
    final fullStars = clamped.floor();
    final hasHalfStar = (clamped - fullStars) >= 0.5;

    return List<Widget>.generate(5, (index) {
      if (index < fullStars) {
        return Icon(Icons.star_rounded, size: size, color: Colors.amber);
      }

      if (index == fullStars && hasHalfStar) {
        return Icon(Icons.star_half_rounded, size: size, color: Colors.amber);
      }

      return Icon(
        Icons.star_border_rounded,
        size: size,
        color: const Color.fromARGB(255, 191, 191, 191),
      );
    });
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
      headers: {"Authorization": "Bearer $token"},
    );

    return jsonDecode(response.body);
  }

  /// Maneja la navegación cuando se presiona un ícono de la barra inferior.
  ///
  /// [index] es el índice del ícono presionado, del 0 al 4 (`int`).
  ///
  /// Navega a diferentes páginas según el índice seleccionado.
  void _onItemTapped(int index) {
    _persistMapState();

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
        unreadNotifications: unread,
      ),

      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
              _mapController?.animateCamera(
                CameraUpdate.newCameraPosition(_lastCameraPosition),
              );
            },
            onCameraMove: (position) {
              _currentMapTarget = position.target;
              _currentZoom = position.zoom;
              _lastCameraPosition = position;
            },
            onCameraIdle: () {
              _persistMapState();
            },
            initialCameraPosition: _lastCameraPosition,
            markers: _hairSalonMarkers,
            circles: _searchAreaCircles,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            compassEnabled: false,
            zoomControlsEnabled: false,
          ),

          if (_isLoadingNearbyBusinesses)
            Positioned(
              top: 112,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color.fromARGB(255, 23, 23, 23),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _nearbyFoundCount == 1
                              ? 'Buscando locales... 1 encontrado'
                              : 'Buscando locales... $_nearbyFoundCount encontrados',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          if (!_isLoadingNearbyBusinesses && _hasCompletedNearbySearch)
            Positioned(
              top: 112,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(245, 255, 255, 255),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.storefront_rounded,
                          size: 16,
                          color: Color.fromARGB(255, 23, 23, 23),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _nearbyFoundCount == 1
                              ? '1 negocio encontrado'
                              : '$_nearbyFoundCount negocios encontrados',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color.fromARGB(255, 23, 23, 23),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
                  ),
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
                      style: TextStyle(color: Colors.black, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: "Buscar locales",
                        hintStyle: TextStyle(color: Colors.grey),
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
            bottom: 15,
            child: Column(
              children: [
                _buildMapControlButton(
                  icon: Icons.my_location,
                  tooltip: 'Centrar en mi ubicacion',
                  onPressed: _centerMapOnUserLocation,
                  inverted: false,
                ),
                const SizedBox(height: 10),
                _buildMapControlButton(
                  icon: Icons.explore,
                  tooltip: 'Orientar mapa al norte',
                  onPressed: _resetMapOrientation,
                  inverted: false,
                ),
              ],
            ),
          ),

          Positioned(
            right: 16,
            bottom: 15,
            child: Column(
              children: [
                _buildMapControlButton(
                  icon: Icons.sync_rounded,
                  tooltip:
                      'Recalcular negocios según localización actual del mapa',
                  onPressed: _refreshBusinessesAroundCurrentView,
                  inverted: true,
                ),
                const SizedBox(height: 10),
                _buildMapControlButton(
                  icon: Icons.directions_rounded,
                  tooltip: 'Abrir ruta en Google Maps',
                  onPressed: _openGoogleMapsRoute,
                  inverted: false,
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
    this.reviewCount,
    this.openingHours,
    this.phone,
    this.photoReferences,
  });

  final String id;
  final String name;
  final String address;
  final LatLng location;
  final bool? openNow;
  final double? rating;
  final int? reviewCount;
  final List<String>? openingHours;
  final String? phone;
  final List<String>? photoReferences;
}
