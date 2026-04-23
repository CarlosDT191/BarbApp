import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/features/business/owner_business_page.dart';
import 'package:flutter_application_1/features/calendar/calendar_page.dart';
import 'package:flutter_application_1/features/home/home_page_client.dart';
import 'package:flutter_application_1/features/home/home_page_owner.dart';
import 'package:flutter_application_1/features/notifications/notification_page.dart';
import 'package:flutter_application_1/features/profile/profile_page.dart';
import 'package:flutter_application_1/models/decorations.dart';
import 'package:flutter_application_1/services/business_service.dart';
import 'package:flutter_application_1/services/favorite_service.dart';
import 'package:flutter_application_1/services/user_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  static const Color _primaryColor = Color.fromARGB(255, 200, 156, 125);
  static const Color _backgroundColor = Color.fromARGB(255, 23, 23, 23);
  static const Color _cardColor = Color.fromARGB(255, 30, 30, 30);

  int _selectedIndex = 1;
  int unread = 0;
  int? role = 0;
  bool _isLoading = true;

  final List<_FavoritePlace> _favoritePlaces = [];
  final Set<String> _favoriteBusinessIds = <String>{};
  final Map<String, Map<String, dynamic>> _registeredBusinessesByPlaceId = {};
  final Map<String, PageController> _photoControllersByPlaceId = {};

  @override
  void initState() {
    super.initState();
    initNotifications();
    _loadUserRole();
    _loadFavorites();
  }

  @override
  void dispose() {
    for (final controller in _photoControllersByPlaceId.values) {
      controller.dispose();
    }
    _photoControllersByPlaceId.clear();
    super.dispose();
  }

  Future<void> _loadUserRole() async {
    final loadedRole = await getUserRole();
    if (!mounted) {
      return;
    }

    setState(() {
      role = loadedRole;
    });
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

  Future<_FavoritePlace?> _fetchFavoritePlaceDetails(String placeId) async {
    final apiKey = dotenv.env['google_maps_api_key'];
    if (apiKey == null || apiKey.isEmpty) {
      return _FavoritePlace(
        id: placeId,
        name: 'Local favorito',
        address: 'Direccion no disponible',
      );
    }

    final uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json'
      '?place_id=$placeId'
      '&fields=name,formatted_address,opening_hours,current_opening_hours,formatted_phone_number,rating,user_ratings_total,photos'
      '&language=es'
      '&key=$apiKey',
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        return null;
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final result = decoded['result'] as Map<String, dynamic>?;
      if (result == null) {
        return null;
      }

      final openingHours =
          ((result['current_opening_hours']
                      as Map<String, dynamic>?)?['weekday_text']
                  as List<dynamic>?)
              ?.map((value) => value.toString())
              .toList() ??
          ((result['opening_hours'] as Map<String, dynamic>?)?['weekday_text']
                  as List<dynamic>?)
              ?.map((value) => value.toString())
              .toList();

      final photosRaw = result['photos'] as List<dynamic>?;
      final photoReferences = photosRaw
          ?.whereType<Map<String, dynamic>>()
          .map((photo) => photo['photo_reference']?.toString().trim() ?? '')
          .where((photoReference) => photoReference.isNotEmpty)
          .toList(growable: false);

      return _FavoritePlace(
        id: placeId,
        name: result['name']?.toString() ?? 'Local favorito',
        address:
            result['formatted_address']?.toString() ??
            'Direccion no disponible',
        openNow:
            (result['opening_hours'] as Map<String, dynamic>?)?['open_now']
                as bool?,
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

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final favoriteIds = await FavoriteService.getFavoriteBusinessIds();

      if (favoriteIds.isEmpty) {
        if (!mounted) {
          return;
        }

        setState(() {
          _favoriteBusinessIds.clear();
          _favoritePlaces.clear();
          _registeredBusinessesByPlaceId.clear();
          _isLoading = false;
        });
        return;
      }

      final registeredBusinesses =
          await BusinessService.getRegisteredBusinessesByPlaceIds(
            favoriteIds.toList(growable: false),
          );

      final detailFutures = favoriteIds
          .map((placeId) => _fetchFavoritePlaceDetails(placeId))
          .toList(growable: false);

      final fetchedPlaces = await Future.wait(detailFutures);
      final places = fetchedPlaces.whereType<_FavoritePlace>().toList();
      places.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _favoriteBusinessIds
          ..clear()
          ..addAll(favoriteIds);

        _favoritePlaces
          ..clear()
          ..addAll(places);

        _registeredBusinessesByPlaceId
          ..clear()
          ..addAll(registeredBusinesses);

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      InputDecorations.showTopSnackBarError(
        context,
        'No se pudo cargar favoritos: $e',
      );
    }
  }

  Future<void> _toggleFavoriteBusiness(
    String businessId, {
    bool removeFromListOnUnfavorite = true,
  }) async {
    final placeId = businessId.trim();
    if (placeId.isEmpty) {
      return;
    }

    final wasFavorite = _favoriteBusinessIds.contains(placeId);

    setState(() {
      if (wasFavorite) {
        _favoriteBusinessIds.remove(placeId);
        if (removeFromListOnUnfavorite) {
          _favoritePlaces.removeWhere((place) => place.id == placeId);
        }
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
          _loadFavorites();
        }
      });

      InputDecorations.showTopSnackBarError(
        context,
        'No se pudo actualizar favoritos.',
      );
    }
  }

  void _showSalonInfoSheet(String placeId) {
    final registeredBusiness = _registeredBusinessesByPlaceId[placeId];
    final isRegistered = registeredBusiness != null;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FutureBuilder<_FavoritePlace?>(
          future: _fetchFavoritePlaceDetails(placeId),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done &&
                !snapshot.hasData) {
              return const SizedBox(
                height: 170,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (!snapshot.hasData || snapshot.data == null) {
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

            final titleColor = isRegistered ? _primaryColor : Colors.white;
            final secondaryTextColor = Colors.white70;
            final iconColor = isRegistered ? _primaryColor : Colors.white;
            final containerColor = _backgroundColor;
            final infoCardColor = _cardColor;
            final photos = business.photoReferences ?? const <String>[];

            return SafeArea(
              top: false,
              child: Container(
                decoration: BoxDecoration(
                  color: containerColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  border: isRegistered ? Border(
                    top: BorderSide(color: _primaryColor, width: 3),
                    left: BorderSide(color: _primaryColor, width: 3),
                    right: BorderSide(color: _primaryColor, width: 3),
                  ) : null,
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
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Row(
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
                                  tooltip:
                                      _favoriteBusinessIds.contains(business.id)
                                      ? 'Quitar de favoritos'
                                      : 'Guardar en favoritos',
                                  onPressed: () async {
                                    await _toggleFavoriteBusiness(business.id);
                                    if (mounted &&
                                        !_favoriteBusinessIds.contains(
                                          business.id,
                                        )) {
                                      Navigator.of(context).pop();
                                    }
                                  },
                                  icon: Icon(
                                    _favoriteBusinessIds.contains(business.id)
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_outline_rounded,
                                    size: 35,
                                    color:
                                        _favoriteBusinessIds.contains(
                                          business.id,
                                        )
                                        ? _primaryColor
                                        : secondaryTextColor,
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
        ? _cardColor
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

  Widget _buildFavoriteListItem(_FavoritePlace place) {
    final isRegistered = _registeredBusinessesByPlaceId.containsKey(place.id);

    return GestureDetector(
      onTap: () => _showSalonInfoSheet(place.id),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          place.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (isRegistered) ...[
                        const SizedBox(width: 4),
                        const Padding(
                          padding: EdgeInsets.only(left: 5), // Espacio entre el símbolo de verificado y el nombre del local
                          child: Icon(
                            Icons.verified_rounded,
                            color: _primaryColor,
                            size: 20,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isRegistered
                        ? 'Registrado en BarbApp'
                        : 'No registrado en BarbApp',
                    style: TextStyle(
                      color: isRegistered ? _primaryColor : Colors.white60,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    place.address,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Quitar de favoritos',
              onPressed: () => _toggleFavoriteBusiness(place.id),
              icon: const Icon(
                Icons.favorite_rounded,
                color: _primaryColor,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> getUserToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<int?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('role');
  }

  Future<int> getUnreadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('unread_notifications') ?? 0;
  }

  void initNotifications() async {
    await UserService.updateUnreadNotifications();
    final loadedUnread = await getUnreadNotifications();

    if (!mounted) {
      return;
    }

    setState(() {
      unread = loadedUnread;
    });
  }

  void _onItemTapped(int index) async {
    setState(() {
      _selectedIndex = index;
    });

    final currentRole = await getUserRole() ?? 0;

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CalendarPage()),
        );
        break;
      case 1:
        if (currentRole == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OwnerBusinessPage()),
          );
        }
        break;
      case 2:
        if (currentRole == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePageOwner()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
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
    return Scaffold(
      backgroundColor: _backgroundColor,

      bottomNavigationBar: InputDecorations.mainBottomNavBar(
        context: context,
        currentIndex: _selectedIndex,
        owner: role == 1,
        onTap: _onItemTapped,
        unreadNotifications: unread,
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 90),
          const Text(
            'Favoritos',
            style: TextStyle(
              fontSize: 33,
              color: _primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'Locales guardados por ti',
            style: TextStyle(fontSize: 14, color: _primaryColor),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  )
                : _favoritePlaces.isEmpty
                ? const Center(
                    child: Text(
                      'No tienes locales favoritos guardados',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : RefreshIndicator(
                    color: _primaryColor,
                    onRefresh: _loadFavorites,
                    child: ListView.builder(
                      itemCount: _favoritePlaces.length,
                      itemBuilder: (context, index) {
                        final place = _favoritePlaces[index];
                        return _buildFavoriteListItem(place);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FavoritePlace {
  const _FavoritePlace({
    required this.id,
    required this.name,
    required this.address,
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
  final bool? openNow;
  final double? rating;
  final int? reviewCount;
  final List<String>? openingHours;
  final String? phone;
  final List<String>? photoReferences;
}
