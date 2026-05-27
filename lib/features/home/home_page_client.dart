import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/features/calendar/calendar_page.dart';
import 'package:flutter_application_1/features/favorites/favorites.dart';
import 'package:flutter_application_1/features/notifications/notification_page.dart';
import 'package:flutter_application_1/features/profile/profile_page.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_application_1/models/booking_models.dart';
import 'package:flutter_application_1/models/decorations.dart';
import 'package:flutter_application_1/models/service_types.dart';
import 'package:flutter_application_1/services/business_service.dart';
import 'package:flutter_application_1/services/favorite_service.dart';
import 'package:flutter_application_1/features/reservations/reservation_flow_page.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:convert';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color _primaryColor = Color.fromARGB(255, 200, 156, 125);
  static const Color _searchButtonHoldColor = Color.fromARGB(255, 173, 124, 92);
  static const Color _registeredSheetBackgroundColor = Color.fromARGB(
    255,
    23,
    23,
    23,
  );
  static const Color _registeredCardColor = Color.fromARGB(255, 30, 30, 30);
  static const String _welcomePrefsKey = "show_welcome_tab";

  int _selectedIndex = 2;
  int unread = 0;
  int _nearbyFoundCount = 0;
  bool _hasCompletedNearbySearch = false;

  // Máximo límite de locales para la API de Google Places.
  static const int _maxNearbyResults = 120;
  static const int _nearbySearchPageLimit = 3;

  // Radio de búsqueda reducido a 500 metros para encontrar más cercanos.
  static const int _defaultSearchRadiusMeters = 500;
  static const int _minSearchRadiusMeters = 50;
  static const int _maxSearchRadiusMeters = 3500;
  static const int _radiusStepMeters = 50;

  static const double _minOfferPrice = 3;
  static const double _maxOfferPrice = 80;
  static const double _offerPriceStep = 1;

  static const String _mapStatePrefsKey = 'home_page_client_map_state_v1';
  static const double _defaultMapZoom = 14;
  static const List<String> _businessKeywordsEs = ['peluqueria', 'barberia'];
  static const List<String> _businessKeywordsEn = ['hair salon', 'barber shop'];
  static const List<String> _placeTypes = ['barber_shop', 'hair_care'];
  static const Set<String> _spanishCountryCodes = {
    'AR',
    'BO',
    'CL',
    'CO',
    'CR',
    'CU',
    'DO',
    'EC',
    'ES',
    'GQ',
    'GT',
    'HN',
    'MX',
    'NI',
    'PA',
    'PE',
    'PR',
    'PY',
    'SV',
    'UY',
    'VE',
  };

  // Hues personalizables para pines: registrado y no registrado.
  static const double _pinHueRegistered = 50; // AMARILLO ES 60, apagado es 50
  static const double _pinHueUnregistered = 160; // CIAN ES 180, apagado es 170

  LatLng _searchCenter = const LatLng(37.8882, -4.7794);
  LatLng _currentMapTarget = const LatLng(37.8882, -4.7794);
  double _currentZoom = 14.0;
  Set<Marker> _hairSalonMarkers = {};
  Set<Circle> _searchAreaCircles = {};
  final Map<String, _HairBusiness> _hairBusinessesById = {};
  final Map<String, Map<String, dynamic>> _registeredBusinessesByPlaceId = {};
  final Map<String, PageController> _photoControllersByPlaceId = {};
  final Set<String> _favoriteBusinessIds = <String>{};
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final List<_AutocompletePlaceSuggestion> _searchSuggestions = [];
  Timer? _searchDebounce;
  GoogleMapController? _mapController;
  _HairBusiness? _selectedBusinessForRoute;
  bool _isLoadingNearbyBusinesses = false;
  bool _isLoadingSearchSuggestions = false;
  bool _hasSearched = false;
  bool _isSearchButtonActive = false;
  bool _isSearchButtonPressed = false;
  bool _welcomeTabShown = false;
  bool _filterBarberia = true;
  bool _filterPeluqueria = true;
  bool _filterRegisteredOnly = false;
  bool _filterOpenNowOnly = false;
  int _filterAvailabilityDays = 0;
  bool _filterUsePriceRange = false;
  String _filterServiceType = '';
  double? _filterPriceValue;
  double? _filterMinPrice;
  double? _filterMaxPrice;
  final Map<String, BookingBusinessDetails> _businessDetailsCache = {};
  bool _useEnglishKeywords = false;
  String? _lastCountryCode;
  LatLng? _lastCountryOrigin;
  DateTime? _lastCountryLookupAt;
  // RADIO DEL CÍRCULO
  double _searchCircleRadiusMeters = _defaultSearchRadiusMeters.toDouble();
  CameraPosition _lastCameraPosition = const CameraPosition(
    target: LatLng(37.8882, -4.7794),
    zoom: _defaultMapZoom,
  );
  final BitmapDescriptor _registeredPinIcon =
      BitmapDescriptor.defaultMarkerWithHue(_pinHueRegistered);
  final BitmapDescriptor _unregisteredPinIcon =
      BitmapDescriptor.defaultMarkerWithHue(_pinHueUnregistered);

  Circle _buildSearchCircle(LatLng center) {
    return Circle(
      circleId: const CircleId('search-radius-circle'),
      center: center,
      radius: _searchCircleRadiusMeters,
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
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();

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

  Future<void> _syncRegisteredBusinesses(
    Iterable<String> placeIds, {
    bool updateMarkers = true,
    Iterable<_HairBusiness>? markerSource,
  }) async {
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
        if (updateMarkers) {
          final businesses = markerSource ?? _hairBusinessesById.values;
          _hairSalonMarkers = _buildMarkersFromBusinesses(businesses);
        }
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

  bool get _isSearchOverlayVisible {
    if (_isLoadingSearchSuggestions || _searchSuggestions.isNotEmpty) {
      return true;
    }

    return _searchFocusNode.hasFocus &&
        _searchController.text.trim().isNotEmpty;
  }

  Uri _buildPlacesAutocompleteUri({
    required String apiKey,
    required String query,
  }) {
    return Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json',
    ).replace(
      queryParameters: {
        'input': query,
        'types': 'establishment',
        'language': 'es',
        'location':
            '${_currentMapTarget.latitude},${_currentMapTarget.longitude}',
        'radius': '40000',
        'key': apiKey,
      },
    );
  }

  bool _isHairSalonPrediction(Map<String, dynamic> rawPrediction) {
    final types =
        (rawPrediction['types'] as List<dynamic>? ?? const <dynamic>[])
            .map((type) => type.toString())
            .toSet();

    if (types.contains('hair_care') || types.contains('barber_shop')) {
      return true;
    }

    final description = (rawPrediction['description']?.toString() ?? '')
        .toLowerCase();

    return description.contains('barber') ||
        description.contains('peluquer') ||
        description.contains('hair');
  }

  void _clearSearchSuggestions({bool clearText = false}) {
    _searchDebounce?.cancel();

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoadingSearchSuggestions = false;
      _searchSuggestions.clear();
      _hasSearched = false;
      _isSearchButtonActive = false;
      _isSearchButtonPressed = false;
      if (clearText) {
        _searchController.clear();
      }
    });
  }

  void _onSearchQueryChanged(String rawQuery) {
    final query = rawQuery.trim();
    _searchDebounce?.cancel();

    if (!mounted) {
      return;
    }

    final shouldReset =
        _isLoadingSearchSuggestions ||
        _searchSuggestions.isNotEmpty ||
        _hasSearched ||
        _isSearchButtonActive ||
        _isSearchButtonPressed;

    if (shouldReset) {
      setState(() {
        _isLoadingSearchSuggestions = false;
        _searchSuggestions.clear();
        _hasSearched = false;
        _isSearchButtonActive = false;
        _isSearchButtonPressed = false;
      });
    }

    if (query.length < 2) {
      if (!_searchFocusNode.hasFocus) {
        _searchFocusNode.requestFocus();
      }
      return;
    }

    if (!_searchFocusNode.hasFocus) {
      _searchFocusNode.requestFocus();
    }
  }

  void _handleSearchTap() {
    final query = _searchController.text.trim();
    final canActivate = query.length >= 2;

    if (!mounted) {
      return;
    }

    setState(() {
      _isSearchButtonActive = canActivate;
    });

    _fetchAutocompleteSuggestions(query);
    if (!_searchFocusNode.hasFocus) {
      _searchFocusNode.requestFocus();
    }
  }

  Future<void> _fetchAutocompleteSuggestions(String query) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.length < 2) {
      if (mounted) {
        InputDecorations.showTopSnackBarWarning(
          context,
          'Escribe al menos 2 caracteres para buscar.',
        );
      }
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoadingSearchSuggestions = true;
      _hasSearched = true;
    });

    try {
      final primaryResults =
          await BusinessService.searchGooglePlacesForBusinessLink(
            query: normalizedQuery,
            type: 'hair_care',
          );
      final secondaryResults =
          await BusinessService.searchGooglePlacesForBusinessLink(
            query: normalizedQuery,
            type: 'barber_shop',
          );

      final combined = <Map<String, dynamic>>[];
      final seenPlaceIds = <String>{};

      for (final rawItem in [...primaryResults, ...secondaryResults]) {
        if (rawItem is! Map<String, dynamic>) {
          continue;
        }
        final placeId = rawItem['placeId']?.toString().trim() ?? '';
        if (placeId.isEmpty || seenPlaceIds.contains(placeId)) {
          continue;
        }
        seenPlaceIds.add(placeId);
        combined.add(rawItem);
      }

      final suggestions = combined
          .map((rawItem) {
            final placeId = rawItem['placeId']?.toString().trim() ?? '';
            final name = rawItem['name']?.toString().trim() ?? '';
            final address = rawItem['address']?.toString().trim() ?? '';
            final location = rawItem['location'];
            final locationMap = location is Map<String, dynamic>
                ? location
                : null;
            final lat = _asDouble(locationMap?['lat']);
            final lng = _asDouble(locationMap?['lng']);

            if (placeId.isEmpty || name.isEmpty || lat == null || lng == null) {
              return null;
            }

            return _AutocompletePlaceSuggestion(
              placeId: placeId,
              mainText: name,
              secondaryText: address,
              location: LatLng(lat, lng),
            );
          })
          .whereType<_AutocompletePlaceSuggestion>()
          .toList(growable: false);

      if (!mounted || _searchController.text.trim() != normalizedQuery) {
        return;
      }

      setState(() {
        _searchSuggestions
          ..clear()
          ..addAll(suggestions);
        _isLoadingSearchSuggestions = false;
      });

      if (suggestions.isEmpty && mounted) {
        InputDecorations.showTopSnackBarWarning(
          context,
          'No se encontraron peluquerias o barberias para esa busqueda.',
        );
      }
    } catch (_) {
      if (!mounted || _searchController.text.trim() != normalizedQuery) {
        return;
      }

      setState(() {
        _searchSuggestions.clear();
        _isLoadingSearchSuggestions = false;
      });

      if (mounted) {
        InputDecorations.showTopSnackBarError(
          context,
          'No se pudo consultar Google Places.',
        );
      }
    }
  }

  Future<_HairBusiness?> _fetchBusinessByPlaceId({
    required String placeId,
    required String fallbackName,
    required String fallbackAddress,
  }) async {
    final apiKey = dotenv.env['google_maps_api_key'];
    if (apiKey == null || apiKey.isEmpty) {
      return null;
    }

    final uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json'
      '?place_id=$placeId'
      '&fields=name,formatted_address,geometry,opening_hours,current_opening_hours,formatted_phone_number,rating,user_ratings_total,photos'
      '&language=es'
      '&key=$apiKey',
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        return null;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final result = body['result'] as Map<String, dynamic>?;
      if (result == null) {
        return null;
      }

      final geometry = result['geometry'] as Map<String, dynamic>?;
      final location = geometry?['location'] as Map<String, dynamic>?;
      final lat = _asDouble(location?['lat']);
      final lng = _asDouble(location?['lng']);

      if (lat == null || lng == null) {
        return null;
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

      final currentOpeningMap =
          result['current_opening_hours'] as Map<String, dynamic>?;
      final openingMap = result['opening_hours'] as Map<String, dynamic>?;

      return _HairBusiness(
        id: placeId,
        name: result['name']?.toString().trim().isNotEmpty == true
            ? result['name'].toString().trim()
            : fallbackName,
        address:
            result['formatted_address']?.toString().trim().isNotEmpty == true
            ? result['formatted_address'].toString().trim()
            : fallbackAddress,
        location: LatLng(lat, lng),
        openNow:
            currentOpeningMap?['open_now'] as bool? ??
            openingMap?['open_now'] as bool?,
        rating: (result['rating'] as num?)?.toDouble(),
        reviewCount: (result['user_ratings_total'] as num?)?.toInt(),
        openingHours: openingHours,
        phone: result['formatted_phone_number']?.toString(),
        photoReferences: photoReferences == null || photoReferences.isEmpty
            ? null
            : photoReferences,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _onSearchSuggestionSelected(
    _AutocompletePlaceSuggestion suggestion,
  ) async {
    _searchFocusNode.unfocus();
    _searchDebounce?.cancel();

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoadingSearchSuggestions = false;
      _searchSuggestions.clear();
    });

    var business = _hairBusinessesById[suggestion.placeId];
    if (business == null) {
      business = _HairBusiness(
        id: suggestion.placeId,
        name: suggestion.mainText,
        address: suggestion.secondaryText,
        location: suggestion.location,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _hairBusinessesById[suggestion.placeId] = business!;
        _hairSalonMarkers = _buildMarkersFromBusinesses(
          _hairBusinessesById.values,
        );
      });

      await _syncRegisteredBusinesses(_hairBusinessesById.keys);
    }

    if (!mounted) {
      return;
    }

    final targetZoom = _currentZoom < 16 ? 16.0 : _currentZoom;

    setState(() {
      _searchController.clear();
      _selectedBusinessForRoute = business;
      _currentMapTarget = business!.location;
      _lastCameraPosition = CameraPosition(
        target: business!.location,
        zoom: targetZoom,
      );
    });

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: business.location, zoom: targetZoom),
      ),
    );

    await _persistMapState();

    if (!mounted) {
      return;
    }

    _showSalonInfoSheet(business.id);
  }

  Widget _buildSearchSuggestionsPanel() {
    final query = _searchController.text.trim();
    final hasMinChars = query.length >= 2;

    return Positioned(
      top: 106,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 280),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: _isLoadingSearchSuggestions
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _primaryColor,
                      ),
                    ),
                  ),
                )
              : !hasMinChars
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Text(
                    'Escribe al menos 2 caracteres y pulsa buscar.',
                    style: TextStyle(color: Colors.black54),
                  ),
                )
              : !_hasSearched
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Text(
                    'Pulsa buscar para ver resultados.',
                    style: TextStyle(color: Colors.black54),
                  ),
                )
              : _searchSuggestions.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Text(
                    'No se encontraron peluquerias o barberias para esa busqueda.',
                    style: TextStyle(color: Colors.black54),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shrinkWrap: true,
                  itemCount: _searchSuggestions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final suggestion = _searchSuggestions[index];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.storefront_rounded),
                      title: Text(
                        suggestion.mainText,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        suggestion.secondaryText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        _onSearchSuggestionSelected(suggestion);
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }

  Future<void> _openFiltersSheet() async {
    final serviceLabels = kServiceTypeOptions
        .map((option) => option.label)
        .toSet();
    var localServiceType = _filterServiceType.trim();
    if (!serviceLabels.contains(localServiceType)) {
      localServiceType = '';
    }

    var localBarberia = _filterBarberia;
    var localPeluqueria = _filterPeluqueria;
    var localRegisteredOnly = _filterRegisteredOnly;
    var localOpenNow = _filterOpenNowOnly;
    var localAvailabilityDays = _filterAvailabilityDays;
    var localUseRange = _filterUsePriceRange;
    var localRadius = _searchCircleRadiusMeters;
    var localPriceValue = _clampOfferPrice(_filterPriceValue ?? _maxOfferPrice);
    var localPriceRange = RangeValues(
      _clampOfferPrice(_filterMinPrice ?? _minOfferPrice),
      _clampOfferPrice(_filterMaxPrice ?? _maxOfferPrice),
    );
    if (localPriceRange.start > localPriceRange.end) {
      localPriceRange = RangeValues(localPriceRange.end, localPriceRange.start);
    }
    if (localServiceType.isEmpty) {
      localUseRange = false;
    }
    final priceDivisions = ((_maxOfferPrice - _minOfferPrice) / _offerPriceStep)
        .round();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Widget buildSection({
              required String title,
              required List<Widget> children,
            }) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 30, 30, 30),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...children,
                  ],
                ),
              );
            }

            return SafeArea(
              top: false,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 23, 23, 23),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Filtros de búsqueda',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 18),
                      buildSection(
                        title: 'Tipos de local',
                        children: [
                          SwitchListTile.adaptive(
                            value: localBarberia,
                            onChanged: (value) {
                              setModalState(() {
                                localBarberia = value;
                              });
                            },
                            activeColor: _primaryColor,
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Barbería',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          SwitchListTile.adaptive(
                            value: localPeluqueria,
                            onChanged: (value) {
                              setModalState(() {
                                localPeluqueria = value;
                              });
                            },
                            activeColor: _primaryColor,
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Peluquería',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          SwitchListTile.adaptive(
                            value: localRegisteredOnly,
                            onChanged: (value) {
                              setModalState(() {
                                localRegisteredOnly = value;
                              });
                            },
                            activeColor: _primaryColor,
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Sólo locales registrados en BarbApp',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      buildSection(
                        title: 'Disponibilidad',
                        children: [
                          SwitchListTile.adaptive(
                            value: localOpenNow,
                            onChanged: (value) {
                              setModalState(() {
                                localOpenNow = value;
                              });
                            },
                            activeColor: _primaryColor,
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Sólo locales abiertos',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<int>(
                            value: localAvailabilityDays,
                            dropdownColor: const Color.fromARGB(
                              255,
                              30,
                              30,
                              30,
                            ),
                            style: const TextStyle(color: Colors.white),
                            iconEnabledColor: Colors.white70,
                            decoration: InputDecoration(
                              labelText: 'Reservas disponibles en menos de',
                              labelStyle: const TextStyle(
                                color: Colors.white70,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.white24,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: _primaryColor),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 0,
                                child: Text('Sin filtro'),
                              ),
                              DropdownMenuItem(value: 1, child: Text('1 día')),
                              DropdownMenuItem(value: 2, child: Text('2 días')),
                              DropdownMenuItem(value: 3, child: Text('3 días')),
                              DropdownMenuItem(value: 4, child: Text('4 días')),
                              DropdownMenuItem(value: 5, child: Text('5 días')),
                              DropdownMenuItem(value: 6, child: Text('6 días')),
                              DropdownMenuItem(value: 7, child: Text('7 días')),
                            ],
                            onChanged: (value) {
                              setModalState(() {
                                localAvailabilityDays = value ?? 0;
                              });
                            },
                          ),
                        ],
                      ),
                      buildSection(
                        title: 'Servicios por precios',
                        children: [
                          DropdownButtonFormField<String>(
                            value: localServiceType,
                            dropdownColor: const Color.fromARGB(
                              255,
                              30,
                              30,
                              30,
                            ),
                            style: const TextStyle(color: Colors.white),
                            iconEnabledColor: Colors.white70,
                            decoration: InputDecoration(
                              labelText: 'Tipo de servicio',
                              labelStyle: const TextStyle(
                                color: Colors.white70,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.white24,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: _primaryColor),
                              ),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: '',
                                child: Text('Todos los servicios'),
                              ),
                              ...kServiceTypeOptions.map((option) {
                                return DropdownMenuItem<String>(
                                  value: option.label,
                                  child: Row(
                                    children: [
                                      Icon(
                                        option.icon,
                                        color: Colors.white70,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(option.label),
                                    ],
                                  ),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setModalState(() {
                                localServiceType = value ?? '';
                                if (localServiceType.isEmpty) {
                                  localUseRange = false;
                                  localPriceValue = _maxOfferPrice;
                                  localPriceRange = RangeValues(
                                    _minOfferPrice,
                                    _maxOfferPrice,
                                  );
                                }
                              });
                            },
                          ),
                          if (localServiceType.isNotEmpty)
                            SwitchListTile.adaptive(
                              value: localUseRange,
                              onChanged: (value) {
                                setModalState(() {
                                  localUseRange = value;
                                });
                              },
                              activeColor: _primaryColor,
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                'Usar rango de precios',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          if (localServiceType.isNotEmpty &&
                              !localUseRange) ...[
                            Text(
                              'Precio máximo: ${localPriceValue.toStringAsFixed(0)} €',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            Slider(
                              value: localPriceValue,
                              min: _minOfferPrice,
                              max: _maxOfferPrice,
                              divisions: priceDivisions,
                              label: '${localPriceValue.toStringAsFixed(0)} €',
                              activeColor: _primaryColor,
                              onChanged: (value) {
                                setModalState(() {
                                  localPriceValue = value;
                                });
                              },
                            ),
                          ],
                          if (localServiceType.isNotEmpty && localUseRange) ...[
                            RangeSlider(
                              values: localPriceRange,
                              min: _minOfferPrice,
                              max: _maxOfferPrice,
                              divisions: priceDivisions,
                              labels: RangeLabels(
                                '${localPriceRange.start.toStringAsFixed(0)} €',
                                '${localPriceRange.end.toStringAsFixed(0)} €',
                              ),
                              activeColor: _primaryColor,
                              onChanged: (value) {
                                setModalState(() {
                                  localPriceRange = value;
                                });
                              },
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Min: ${localPriceRange.start.toStringAsFixed(0)} €',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                Text(
                                  'Max: ${localPriceRange.end.toStringAsFixed(0)} €',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      buildSection(
                        title: 'Distancia de la búsqueda',
                        children: [
                          Slider(
                            value: localRadius,
                            min: _minSearchRadiusMeters.toDouble(),
                            max: _maxSearchRadiusMeters.toDouble(),
                            divisions:
                                (_maxSearchRadiusMeters -
                                    _minSearchRadiusMeters) ~/
                                _radiusStepMeters,
                            label: '${localRadius.round()} m',
                            activeColor: _primaryColor,
                            onChanged: (value) {
                              setModalState(() {
                                localRadius = value;
                              });
                            },
                          ),
                          Row(
                            children: const [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Colors.white54,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Si aumentas mucho el radio, es posible que no se encuentren todos los locales disponibles (máximo 120).',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setModalState(() {
                                  localBarberia = true;
                                  localPeluqueria = true;
                                  localRegisteredOnly = false;
                                  localOpenNow = false;
                                  localAvailabilityDays = 0;
                                  localUseRange = false;
                                  localRadius = _defaultSearchRadiusMeters
                                      .toDouble();
                                  localServiceType = '';
                                  localPriceValue = _maxOfferPrice;
                                  localPriceRange = RangeValues(
                                    _minOfferPrice,
                                    _maxOfferPrice,
                                  );
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white24),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              child: const Text('Restablecer'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                var appliedBarberia = localBarberia;
                                var appliedPeluqueria = localPeluqueria;
                                if (!appliedBarberia && !appliedPeluqueria) {
                                  appliedBarberia = true;
                                  appliedPeluqueria = true;
                                }

                                final hasServiceType = localServiceType
                                    .trim()
                                    .isNotEmpty;
                                final applyUseRange =
                                    hasServiceType && localUseRange;
                                final applyPriceValue =
                                    hasServiceType && !localUseRange
                                    ? localPriceValue
                                    : null;
                                final applyMinPrice = applyUseRange
                                    ? localPriceRange.start
                                    : null;
                                final applyMaxPrice = applyUseRange
                                    ? localPriceRange.end
                                    : null;

                                setState(() {
                                  _filterBarberia = appliedBarberia;
                                  _filterPeluqueria = appliedPeluqueria;
                                  _filterRegisteredOnly = localRegisteredOnly;
                                  _filterOpenNowOnly = localOpenNow;
                                  _filterAvailabilityDays =
                                      localAvailabilityDays;
                                  _filterUsePriceRange = applyUseRange;
                                  _filterServiceType = hasServiceType
                                      ? localServiceType.trim()
                                      : '';
                                  _filterPriceValue = applyPriceValue;
                                  _filterMinPrice = applyMinPrice;
                                  _filterMaxPrice = applyMaxPrice;
                                  _searchCircleRadiusMeters = localRadius;
                                });

                                Navigator.pop(context);
                                _refreshBusinessesAroundCurrentView();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  side: const BorderSide(
                                    color: Colors.white,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: const Text('Aplicar filtros'),
                            ),
                          ),
                        ],
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

  Future<void> _loadFavoriteBusinessIds() async {
    try {
      final favoriteIds = await FavoriteService.getFavoriteBusinessIds();

      if (!mounted) {
        return;
      }

      setState(() {
        _favoriteBusinessIds
          ..clear()
          ..addAll(favoriteIds);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _favoriteBusinessIds.clear();
      });
    }
  }

  Future<void> _toggleFavoriteBusiness(String businessId) async {
    final placeId = businessId.trim();
    if (placeId.isEmpty) {
      return;
    }

    final wasFavorite = _favoriteBusinessIds.contains(placeId);

    setState(() {
      if (wasFavorite) {
        _favoriteBusinessIds.remove(placeId);
      } else {
        _favoriteBusinessIds.add(placeId);
      }
    });

    try {
      if (wasFavorite) {
        await FavoriteService.removeFavoriteBusiness(placeId);
      } else {
        await FavoriteService.addFavoriteBusiness(placeId);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        if (wasFavorite) {
          _favoriteBusinessIds.add(placeId);
        } else {
          _favoriteBusinessIds.remove(placeId);
        }
      });

      InputDecorations.showTopSnackBarError(
        context,
        'No se pudo actualizar locales guardados.',
      );
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
    final isRegistered = _registeredBusinessesByPlaceId.containsKey(
      business.id,
    );
    return isRegistered ? _registeredPinIcon : _unregisteredPinIcon;
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
    if (_isLoadingNearbyBusinesses) {
      if (mounted) {
        InputDecorations.showTopSnackBarWarning(
          context,
          'Debes de esperar a que calcule todos los negocios cercanos para volver a utilizarlo.',
        );
      }
      return;
    }

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

  _HairBusiness? _resolveBusinessForRoute({LatLng? origin}) {
    final base = origin ?? _searchCenter;
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
        base.latitude,
        base.longitude,
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

  Future<LatLng?> _getUserLocationOrigin() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        InputDecorations.showTopSnackBarError(
          context,
          'Activa la ubicacion para calcular la ruta.',
        );
      }
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        InputDecorations.showTopSnackBarError(
          context,
          'Permiso de ubicacion requerido para calcular la ruta.',
        );
      }
      return null;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return LatLng(position.latitude, position.longitude);
    } catch (_) {
      if (mounted) {
        InputDecorations.showTopSnackBarError(
          context,
          'No se pudo obtener la ubicacion actual.',
        );
      }
      return null;
    }
  }

  Future<void> _openGoogleMapsRoute({_HairBusiness? targetBusiness}) async {
    final origin = await _getUserLocationOrigin();
    if (origin == null) {
      return;
    }

    final business = targetBusiness ?? _resolveBusinessForRoute(origin: origin);

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
      'origin': '${origin.latitude},${origin.longitude}',
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

  bool _shouldUseEnglishForLocale() {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    return locale.languageCode.toLowerCase() != 'es';
  }

  bool _shouldUseEnglishForCountry(String? countryCode) {
    if (countryCode == null || countryCode.trim().isEmpty) {
      return _shouldUseEnglishForLocale();
    }
    return !_spanishCountryCodes.contains(countryCode.toUpperCase());
  }

  Future<String?> _fetchCountryCodeForSearchCenter(String apiKey) async {
    final lat = _searchCenter.latitude;
    final lng = _searchCenter.longitude;
    final uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json'
      '?latlng=$lat,$lng'
      '&result_type=country'
      '&key=$apiKey',
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        return null;
      }

      final body = jsonDecode(response.body);
      final results = body is Map<String, dynamic>
          ? body['results'] as List<dynamic>?
          : null;
      if (results == null) {
        return null;
      }

      for (final result in results) {
        final components = result is Map<String, dynamic>
            ? result['address_components'] as List<dynamic>?
            : null;
        if (components == null) {
          continue;
        }
        for (final component in components) {
          final map = component is Map<String, dynamic> ? component : null;
          final types = map?['types'] as List<dynamic>?;
          if (types == null || !types.contains('country')) {
            continue;
          }
          final shortName = map?['short_name']?.toString().trim();
          if (shortName != null && shortName.isNotEmpty) {
            return shortName;
          }
        }
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  Future<void> _syncKeywordLocaleForSearch() async {
    final apiKey = dotenv.env['google_maps_api_key'];
    if (apiKey == null || apiKey.isEmpty) {
      _useEnglishKeywords = _shouldUseEnglishForLocale();
      return;
    }

    final now = DateTime.now();
    if (_lastCountryOrigin != null && _lastCountryLookupAt != null) {
      final distance = Geolocator.distanceBetween(
        _lastCountryOrigin!.latitude,
        _lastCountryOrigin!.longitude,
        _searchCenter.latitude,
        _searchCenter.longitude,
      );
      if (distance < 50000 &&
          now.difference(_lastCountryLookupAt!) < const Duration(hours: 12)) {
        return;
      }
    }

    final countryCode = await _fetchCountryCodeForSearchCenter(apiKey);
    final resolvedCountryCode = countryCode ?? _lastCountryCode;
    _lastCountryCode = resolvedCountryCode;
    _lastCountryOrigin = _searchCenter;
    _lastCountryLookupAt = now;
    _useEnglishKeywords = _shouldUseEnglishForCountry(resolvedCountryCode);
  }

  List<String> _activeBusinessKeywords() {
    final keywords = <String>[];
    if (_filterPeluqueria) {
      keywords.add(_useEnglishKeywords ? 'hair salon' : 'peluqueria');
    }
    if (_filterBarberia) {
      keywords.add(_useEnglishKeywords ? 'barber shop' : 'barberia');
    }

    return keywords.isEmpty
        ? (_useEnglishKeywords ? _businessKeywordsEn : _businessKeywordsEs)
        : keywords;
  }

  List<String> _activePlaceTypes() {
    final types = <String>[];
    if (_filterBarberia) {
      types.add('barber_shop');
    }
    if (_filterPeluqueria) {
      types.add('hair_care');
    }

    return types.isEmpty ? _placeTypes : types;
  }

  double _clampOfferPrice(double value) {
    return value.clamp(_minOfferPrice, _maxOfferPrice).toDouble();
  }

  bool get _hasServicePriceFilter {
    if (_filterServiceType.trim().isNotEmpty) {
      return true;
    }

    if (_filterUsePriceRange) {
      return _filterMinPrice != null || _filterMaxPrice != null;
    }

    return _filterPriceValue != null;
  }

  bool get _requiresRegisteredBusinesses {
    return _filterRegisteredOnly ||
        _hasServicePriceFilter ||
        _filterAvailabilityDays > 0;
  }

  String? _businessIdForPlaceId(String placeId) {
    final raw = _registeredBusinessesByPlaceId[placeId]?['businessId'];
    return raw?.toString();
  }

  Future<BookingBusinessDetails?> _getBusinessDetails(String businessId) async {
    final cached = _businessDetailsCache[businessId];
    if (cached != null) {
      return cached;
    }

    try {
      final details = await BusinessService.getBusinessDetails(
        businessId: businessId,
      );
      _businessDetailsCache[businessId] = details;
      return details;
    } catch (_) {
      return null;
    }
  }

  bool _matchesServicePriceFilter(BookingBusinessOffer offer) {
    final serviceQuery = _filterServiceType.trim().toLowerCase();
    if (serviceQuery.isNotEmpty) {
      final offerType = offer.serviceType.toLowerCase();
      if (offerType != serviceQuery) {
        return false;
      }
    }

    if (_filterUsePriceRange) {
      if (_filterMinPrice == null && _filterMaxPrice == null) {
        return true;
      }

      final minPrice = _filterMinPrice ?? 0;
      final maxPrice = _filterMaxPrice ?? double.infinity;
      if (offer.price < minPrice || offer.price > maxPrice) {
        return false;
      }
    } else if (_filterPriceValue != null) {
      if (offer.price > _filterPriceValue!) {
        return false;
      }
    }

    return true;
  }

  Future<List<_HairBusiness>> _applyFilters(
    List<_HairBusiness> businesses,
  ) async {
    var filtered = businesses;

    if (_filterOpenNowOnly) {
      filtered = filtered
          .where((business) => business.openNow == true)
          .toList(growable: false);
    }

    if (_requiresRegisteredBusinesses) {
      final registeredIds = _registeredBusinessesByPlaceId.keys.toSet();
      filtered = filtered
          .where((business) => registeredIds.contains(business.id))
          .toList(growable: false);
    }

    if (_hasServicePriceFilter) {
      filtered = await _filterByServiceAndPrice(filtered);
    }

    if (_filterAvailabilityDays > 0) {
      filtered = await _filterByAvailability(filtered, _filterAvailabilityDays);
    }

    return filtered;
  }

  Future<List<_HairBusiness>> _filterByServiceAndPrice(
    List<_HairBusiness> businesses,
  ) async {
    final matches = <_HairBusiness>[];

    for (final business in businesses) {
      final businessId = _businessIdForPlaceId(business.id);
      if (businessId == null) {
        continue;
      }

      final details = await _getBusinessDetails(businessId);
      if (details == null || details.offers.isEmpty) {
        continue;
      }

      final offerMatches = details.offers.any(
        (offer) => _matchesServicePriceFilter(offer),
      );
      if (offerMatches) {
        matches.add(business);
      }
    }

    return matches;
  }

  Future<List<_HairBusiness>> _filterByAvailability(
    List<_HairBusiness> businesses,
    int days,
  ) async {
    final matches = <_HairBusiness>[];
    final formatter = DateFormat('yyyy-MM-dd');
    final today = DateTime.now();

    for (final business in businesses) {
      final businessId = _businessIdForPlaceId(business.id);
      if (businessId == null) {
        continue;
      }

      final details = await _getBusinessDetails(businessId);
      if (details == null || details.offers.isEmpty) {
        continue;
      }

      final hasAvailability = await _hasAvailabilityWithinDays(
        details,
        days,
        today,
        formatter,
      );

      if (hasAvailability) {
        matches.add(business);
      }
    }

    return matches;
  }

  Future<bool> _hasAvailabilityWithinDays(
    BookingBusinessDetails details,
    int days,
    DateTime baseDate,
    DateFormat formatter,
  ) async {
    for (var offset = 0; offset < days; offset += 1) {
      final date = baseDate.add(Duration(days: offset));
      final dateString = formatter.format(date);

      for (var index = 0; index < details.offers.length; index += 1) {
        try {
          final availability = await BusinessService.getBusinessAvailability(
            businessId: details.id,
            date: dateString,
            offerIndex: index,
          );

          final hasSlot = availability.slots.any((slot) => slot.remaining > 0);
          if (hasSlot) {
            return true;
          }
        } catch (_) {
          continue;
        }
      }
    }

    return false;
  }

  Future<void> _loadHairBusinesses() async {
    final apiKey = dotenv.env['google_maps_api_key'];
    if (apiKey == null || apiKey.isEmpty) {
      return;
    }

    await _syncKeywordLocaleForSearch();

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

      await _syncRegisteredBusinesses(
        businessesById.keys,
        updateMarkers: false,
      );

      final filteredBusinesses = await _applyFilters(businesses);

      if (!mounted) {
        return;
      }

      setState(() {
        _hairBusinessesById
          ..clear()
          ..addEntries(
            filteredBusinesses.map(
              (business) => MapEntry(business.id, business),
            ),
          );

        _hairSalonMarkers = _buildMarkersFromBusinesses(filteredBusinesses);
        _nearbyFoundCount = filteredBusinesses.length;
        _hasCompletedNearbySearch = true;
        _searchAreaCircles = {_buildSearchCircle(searchOrigin)};
      });

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
    final radius = _searchCircleRadiusMeters.round().toString();

    return Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
      '?location=${_searchCenter.latitude},${_searchCenter.longitude}'
      '&radius=$radius'
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
    final keywords = _activeBusinessKeywords();
    final types = _activePlaceTypes();

    for (final keyword in keywords) {
      for (final type in types) {
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

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final registeredBusiness = _registeredBusinessesByPlaceId[placeId];
            final isRegistered = registeredBusiness != null;

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
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 80),
                    child: const Text(
                      'No se pudo cargar el detalle del local.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }

                final business = snapshot.data!;
                final isFavorite = _favoriteBusinessIds.contains(business.id);
                final businessId =
                    registeredBusiness?['businessId']?.toString().trim() ?? '';
                final shouldShowOffers = isRegistered && businessId.isNotEmpty;

                final firstHoursLine =
                    (business.openingHours != null &&
                        business.openingHours!.isNotEmpty)
                    ? business.openingHours!.first
                    : 'Horario no disponible';

                final titleColor = isRegistered ? _primaryColor : Colors.white;
                final secondaryTextColor = Colors.white70;
                final iconColor = isRegistered ? _primaryColor : Colors.white;
                final containerColor = _registeredSheetBackgroundColor;
                final infoCardColor = _registeredCardColor;
                final stateColor = business.openNow == null
                    ? Color.fromARGB(255, 205, 205, 205)
                    : (business.openNow! ? Colors.green : Colors.red);

                final photos = business.photoReferences ?? const <String>[];

                /// MÁXIMO DE TARJETA
                final maxSheetHeight = MediaQuery.of(context).size.height * 0.8;

                return SafeArea(
                  top: false,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: maxSheetHeight),
                      child: Container(
                        decoration: BoxDecoration(
                          color: containerColor,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                          border: isRegistered
                              ? Border(
                                  top: BorderSide(
                                    color: _primaryColor,
                                    width: 3,
                                  ),
                                  left: BorderSide(
                                    color: _primaryColor,
                                    width: 3,
                                  ),
                                  right: BorderSide(
                                    color: _primaryColor,
                                    width: 3,
                                  ),
                                )
                              : null,
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
                                        ? _primaryColor
                                        : const Color.fromARGB(
                                            255,
                                            205,
                                            205,
                                            205,
                                          ),
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
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  18,
                                  20,
                                  24,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Row(
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
                                                  padding: EdgeInsets.only(
                                                    left: 8,
                                                    top: 2,
                                                  ),
                                                  child: Icon(
                                                    Icons.verified_rounded,
                                                    color: _primaryColor,
                                                    size: 28,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: isFavorite
                                              ? 'Quitar de locales guardados'
                                              : 'Añadir en locales guardados',
                                          onPressed: () {
                                            _toggleFavoriteBusiness(
                                              business.id,
                                            );

                                            /// Fuerza rebuild del modal
                                            setModalState(() {});
                                          },
                                          icon: Icon(
                                            isFavorite
                                                ? Icons.bookmark_rounded
                                                : Icons
                                                      .bookmark_outline_rounded,
                                            size: 35,
                                            color: isFavorite
                                                ? _primaryColor
                                                : secondaryTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (isRegistered) ...[
                                      const SizedBox(height: 2),
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
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Row(
                                              children: _buildRatingStars(
                                                business.rating!,
                                                size: 23,
                                              ),
                                            ),
                                            const SizedBox(width: 27),
                                            Text(
                                              business.rating!.toStringAsFixed(
                                                1,
                                              ),
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
                                            iconColor: stateColor,
                                            textColor: stateColor,
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
                                    const SizedBox(height: 16),

                                    if (shouldShowOffers) ...[
                                      _buildOffersSection(
                                        businessId: businessId,
                                        cardColor: infoCardColor,
                                        titleColor: titleColor,
                                        subtitleColor: secondaryTextColor,
                                        iconColor: iconColor,
                                      ),
                                      const SizedBox(height: 16),
                                    ],

                                    Row(
                                      children: [
                                        Expanded(
                                          child: SizedBox(
                                            height: 48,
                                            child: OutlinedButton.icon(
                                              onPressed: () async {
                                                _selectedBusinessForRoute =
                                                    business;
                                                await _openGoogleMapsRoute(
                                                  targetBusiness: business,
                                                );
                                              },
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.white,
                                                side: const BorderSide(
                                                  color: Colors.white54,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                ),
                                              ),
                                              icon: const Icon(
                                                Icons.directions_rounded,
                                                size: 20,
                                              ),
                                              label: const Text(
                                                'Calcular ruta',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (isRegistered) ...[
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: SizedBox(
                                              height: 48,
                                              child: ElevatedButton.icon(
                                                onPressed: () {
                                                  final businessId =
                                                      registeredBusiness?['businessId']
                                                          ?.toString()
                                                          .trim() ??
                                                      '';

                                                  if (businessId.isEmpty) {
                                                    InputDecorations.showTopSnackBarError(
                                                      context,
                                                      'No se pudo abrir la reserva.',
                                                    );
                                                    return;
                                                  }

                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          ReservationFlowPage(
                                                            initialBusinessId:
                                                                businessId,
                                                            initialBusinessName:
                                                                registeredBusiness?['name']
                                                                    ?.toString(),
                                                          ),
                                                    ),
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      _primaryColor,
                                                  foregroundColor: Colors.white,
                                                  disabledBackgroundColor:
                                                      _primaryColor,
                                                  disabledForegroundColor:
                                                      Colors.white,
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          14,
                                                        ),
                                                    side: const BorderSide(
                                                      color: Colors.white,
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                ),
                                                icon: const Icon(
                                                  Icons.calendar_month_rounded,
                                                  size: 20,
                                                ),
                                                label: const Text(
                                                  'Reservar',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
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

  IconData _iconForServiceType(String serviceType) {
    for (final option in kServiceTypeOptions) {
      if (option.label == serviceType) {
        return option.icon;
      }
    }
    return Icons.content_cut;
  }

  String _formatOfferTitle(BookingBusinessOffer offer) {
    final serviceType = offer.serviceType.trim();
    final name = offer.name.trim();

    if (serviceType.isEmpty) {
      return name.isEmpty ? 'Oferta' : name;
    }

    if (name.isEmpty) {
      return serviceType;
    }

    return '($serviceType) $name';
  }

  Widget _buildOfferRow({
    required BookingBusinessOffer offer,
    required Color titleColor,
    required Color subtitleColor,
    required Color iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          _iconForServiceType(offer.serviceType),
          color: iconColor,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatOfferTitle(offer),
                style: TextStyle(
                  color: subtitleColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '${offer.price.toStringAsFixed(2)} €',
                    style: TextStyle(
                      color: titleColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (offer.durationMinutes > 0) ...[
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.access_time,
                      color: Colors.white54,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${offer.durationMinutes} min',
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOffersSection({
    required String businessId,
    required Color cardColor,
    required Color titleColor,
    required Color subtitleColor,
    required Color iconColor,
  }) {
    final maxHeight = MediaQuery.of(context).size.height * 0.34;
    Widget buildOffersContent(List<BookingBusinessOffer> offers) {
      if (offers.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            'Sin ofertas disponibles.',
            style: TextStyle(color: Colors.white70),
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ofertas',
              style: TextStyle(
                color: titleColor,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: offers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _buildOfferRow(
                    offer: offers[index],
                    titleColor: titleColor,
                    subtitleColor: subtitleColor,
                    iconColor: iconColor,
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    final cached = _businessDetailsCache[businessId];
    if (cached != null) {
      return buildOffersContent(cached.offers);
    }

    return FutureBuilder<BookingBusinessDetails?>(
      future: _getBusinessDetails(businessId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: const [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _primaryColor,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Cargando ofertas...',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          );
        }

        final offers = snapshot.data?.offers ?? const <BookingBusinessOffer>[];
        return buildOffersContent(offers);
      },
    );
  }

  Widget _buildWelcomeItem({
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _maybeShowWelcomeTab() async {
    if (_welcomeTabShown) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final shouldShow = prefs.getBool(_welcomePrefsKey) ?? false;
    if (!shouldShow || !mounted) {
      return;
    }

    _welcomeTabShown = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _showWelcomeTab();
    });
  }

  Future<void> _dismissWelcomeTab() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_welcomePrefsKey, false);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _showWelcomeTab() {
    const subtitle =
        'Esta app sobre negocios de peluquería y barbería contiene múltiples herramientas para ayudar a descubrir infinidad de locales, observar sus ofertas desde cualquier lugar y poder reservar en locales registrados.';

    final items = <Map<String, dynamic>>[
      {
        'title': 'Calendario',
        'description': 'Consulta y gestiona tus reservas.',
        'icon': Icons.calendar_month,
      },
      {
        'title': 'Favoritos',
        'description': 'Guarda locales para acceder rápido a ellos.',
        'icon': Icons.bookmark_rounded,
      },
      {
        'title': 'Mapa',
        'description': 'Descubre negocios cercanos y sus ofertas.',
        'icon': Icons.map,
      },
      {
        'title': 'Notificaciones',
        'description': 'Recibe avisos de reservas y novedades.',
        'icon': Icons.notifications,
      },
      {
        'title': 'Perfil',
        'description': 'Actualiza tus datos y preferencias.',
        'icon': Icons.person,
      },
    ];

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color.fromARGB(255, 23, 23, 23),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: Stack(
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      const Text(
                        '¡Bienvenid@ a BarbApp!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        subtitle,
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                        textAlign: TextAlign.justify,
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Guía rápida',
                        style: TextStyle(
                          color: _primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...items.map((item) {
                        return _buildWelcomeItem(
                          title: item['title'] ?? '',
                          description: item['description'] ?? '',
                          icon: item['icon'] as IconData? ?? Icons.info,
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: IconButton(
                  onPressed: _dismissWelcomeTab,
                  icon: const Icon(Icons.close, color: Colors.white),
                  tooltip: 'Cerrar',
                ),
              ),
            ],
          ),
        );
      },
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

  /// Cierra la sesión del usuario autenticado.
  ///
  /// [context] es el contexto de navegación (`BuildContext`).
  ///
  /// Elimina todos los datos almacenados en [SharedPreferences]
  /// y redirige a la página de login.
  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    // Elimina los datos de la sesión
    await prefs.clear();

    Navigator.pushReplacementNamed(context, "/login");
  }

  /// Obtiene el token JWT almacenado del usuario.
  ///
  /// Retorna un `String` con el token o `null` si no existe en local.
  /// El token se utiliza para autenticar todas las solicitudes al backend.
  Future<String?> getUserToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  /// Obtiene el número de notificaciones no leídas.
  ///
  /// Lee el valor almacenado en [SharedPreferences] para obtener
  /// rápidamente el conteo de notificaciones sin leer.
  /// Retorna un `int` con el número de notificaciones no leídas.
  Future<int> getUnreadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("unread_notifications") ?? 0;
  }

  /// Obtiene los datos del usuario desde el backend.
  ///
  /// Requiere un token JWT válido en [SharedPreferences].
  /// Retorna un `Map<String, dynamic>` con los datos del usuario
  /// (email, nombre, apellido, rol).
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
  /// Navega a diferentes páginas según el índice y actualiza el estado de selección.
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const FavoritesPage()),
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
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );
        break;
    }
  }

  /// Obtiene el rol del usuario desde [SharedPreferences].
  ///
  /// Los roles disponibles son: 0=cliente, 1=propietario, 2=admin.
  /// Retorna un `int` con el rol o `null` si no se encuentra almacenado.
  Future<int?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("role");
  }

  @override
  void initState() {
    super.initState();

    _searchFocusNode.addListener(() {
      if (!mounted) {
        return;
      }

      if (!_searchFocusNode.hasFocus) {
        _clearSearchSuggestions();
      } else {
        setState(() {});
      }
    });

    initNotifications();
    _initializeNearbySearch();
    _loadFavoriteBusinessIds();
    _maybeShowWelcomeTab();
  }

  void initNotifications() async {
    await UserService.updateUnreadNotifications(); // API
    int unread = await getUnreadNotifications(); // local

    setState(() {
      this.unread = unread;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSearchActive = _isSearchButtonActive;
    final isSearchPressed = _isSearchButtonPressed;
    return Scaffold(
      // BARRA INFERIOR CON LOS ICONOS
      bottomNavigationBar: InputDecorations.mainBottomNavBar(
        context: context,
        currentIndex: 2,
        owner: false,
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
            onTap: (_) {
              if (!mounted) {
                return;
              }
              _searchFocusNode.unfocus();
              _clearSearchSuggestions();
            },
            initialCameraPosition: _lastCameraPosition,
            markers: _hairSalonMarkers,
            circles: _searchAreaCircles,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
          ),

          if (_isLoadingNearbyBusinesses && !_isSearchOverlayVisible)
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

          if (!_isLoadingNearbyBusinesses &&
              _hasCompletedNearbySearch &&
              !_isSearchOverlayVisible)
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
                  const SizedBox(width: 16),

                  // 👉 INPUT
                  Expanded(
                    child: TextSelectionTheme(
                      data: const TextSelectionThemeData(
                        cursorColor: Color.fromARGB(255, 23, 23, 23),
                        selectionHandleColor: Color.fromARGB(255, 23, 23, 23),
                        selectionColor: Color.fromARGB(80, 23, 23, 23),
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        cursorColor: const Color.fromARGB(255, 23, 23, 23),
                        textInputAction: TextInputAction.search,
                        onChanged: _onSearchQueryChanged,
                        onSubmitted: (_) {
                          _handleSearchTap();
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              _searchFocusNode.requestFocus();
                            }
                          });
                        },
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                        ),
                        decoration: const InputDecoration(
                          hintText: "Buscar locales",
                          hintStyle: TextStyle(color: Colors.grey),
                          isDense: true,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),

                  GestureDetector(
                    onTap: _handleSearchTap,
                    onLongPress: _handleSearchTap,
                    onLongPressStart: (_) {
                      final query = _searchController.text.trim();
                      if (query.length < 2 || !mounted) {
                        return;
                      }
                      setState(() {
                        _isSearchButtonPressed = true;
                      });
                    },
                    onLongPressEnd: (_) {
                      if (!mounted) {
                        return;
                      }
                      setState(() {
                        _isSearchButtonPressed = false;
                      });
                    },
                    onLongPressCancel: () {
                      if (!mounted) {
                        return;
                      }
                      setState(() {
                        _isSearchButtonPressed = false;
                      });
                    },
                    child: Container(
                      width: 64,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: isSearchPressed
                            ? _searchButtonHoldColor
                            : (isSearchActive
                                  ? _primaryColor
                                  : const Color.fromARGB(255, 215, 216, 219)),
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(30),
                        ),
                      ),
                      child: const Icon(
                        Icons.search,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_isSearchOverlayVisible) _buildSearchSuggestionsPanel(),

          Positioned(
            left: 16,
            bottom: 15,
            child: Column(
              children: [
                const SizedBox(height: 10),
                _buildMapControlButton(
                  icon: Icons.sync_rounded,
                  tooltip:
                      'Recalcular negocios según localización actual del mapa',
                  onPressed: _refreshBusinessesAroundCurrentView,
                  inverted: true,
                ),
                const SizedBox(height: 10),
                _buildMapControlButton(
                  icon: Icons.tune_rounded,
                  tooltip: 'Cambiar filtros de búsqueda',
                  onPressed: () {
                    _openFiltersSheet();
                  },
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
                const SizedBox(height: 10),
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

class _AutocompletePlaceSuggestion {
  const _AutocompletePlaceSuggestion({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
    required this.location,
  });

  final String placeId;
  final String mainText;
  final String secondaryText;
  final LatLng location;
}
