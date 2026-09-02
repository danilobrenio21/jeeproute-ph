import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'models/puv_route.dart';
import 'data/sample_routes.dart';

void main() => runApp(const JeepRouteModernApp());

class JeepRouteModernApp extends StatelessWidget {
  const JeepRouteModernApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JeepRoute PH',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF59E0B),
          secondary: Color(0xFF06B6D4),
          surface: Color(0xFF1E293B),
        ),
      ),
      home: const NationwideRouteMapScreen(),
    );
  }
}

class NationwideRouteMapScreen extends StatefulWidget {
  const NationwideRouteMapScreen({super.key});

  @override
  State<NationwideRouteMapScreen> createState() => _NationwideRouteMapScreenState();
}

class _NationwideRouteMapScreenState extends State<NationwideRouteMapScreen> {
  final MapController _mapController = MapController();
  final Distance _distanceCalculator = const Distance();

  // Region and Route State
  PhilippineRegion _selectedRegion = PhilippineRegion.metroManila;
  late NationwideRoute _selectedRoute;
  double _tripDistanceKm = 3.5;
  bool _isDiscounted = false;

  // Realtime GPS Tracking State
  bool _isNavigating = false;
  bool _isLocating = false;
  LatLng? _currentLocation;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _autoCenter = true;

  @override
  void initState() {
    super.initState();
    _selectedRoute = sampleNationwideRoutes.firstWhere(
      (r) => r.region == _selectedRegion,
      orElse: () => sampleNationwideRoutes.first,
    );
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  List<NationwideRoute> get _currentRegionRoutes {
    return sampleNationwideRoutes.where((r) => r.region == _selectedRegion).toList();
  }

  void _onRegionChanged(PhilippineRegion region) {
    setState(() {
      _selectedRegion = region;
      final matchedRoutes = _currentRegionRoutes;
      if (matchedRoutes.isNotEmpty) {
        _selectedRoute = matchedRoutes.first;
        _mapController.move(_selectedRoute.pathCoordinates.first, 13.5);
      }
    });
  }

  void _onSelectRoute(NationwideRoute route) {
    setState(() {
      _selectedRoute = route;
      if (_currentLocation != null) {
        final dest = route.pathCoordinates.last;
        final meters = _distanceCalculator.as(LengthUnit.Meter, _currentLocation!, dest);
        _tripDistanceKm = (meters / 1000).clamp(0.5, 300.0);
      }
    });
    _mapController.move(route.pathCoordinates.first, 14.0);
  }

  Future<void> _toggleNavigation() async {
    if (_isNavigating) {
      await _positionStreamSubscription?.cancel();
      setState(() {
        _isNavigating = false;
        _isLocating = false;
        _currentLocation = null;
      });
      _showMessage("Live navigation paused.");
      return;
    }

    setState(() => _isLocating = true);

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _isLocating = false);
      _showMessage("Enable GPS location services on your device.");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLocating = false);
        _showMessage("Location permission denied.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _isLocating = false);
      _showMessage("Location access permanently blocked in device settings.");
      return;
    }

    setState(() => _isNavigating = true);

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 3,
    );

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        final newPoint = LatLng(position.latitude, position.longitude);
        setState(() {
          _currentLocation = newPoint;
          _isLocating = false;

          final dest = _selectedRoute.pathCoordinates.last;
          final metersToDest = _distanceCalculator.as(LengthUnit.Meter, newPoint, dest);
          _tripDistanceKm = (metersToDest / 1000).clamp(0.5, 300.0);
        });

        if (_autoCenter) {
          _mapController.move(newPoint, _mapController.camera.zoom);
        }
      },
      onError: (err) {
        setState(() {
          _isLocating = false;
          _isNavigating = false;
        });
        _showMessage("GPS stream interrupted.");
      },
    );
  }

  void _shareLiveLocation() {
    if (_currentLocation == null) {
      _showMessage("Acquire GPS coordinates first by starting navigation.");
      return;
    }
    final shareUrl = "https://maps.google.com/?q=${_currentLocation!.latitude},${_currentLocation!.longitude}";
    Clipboard.setData(ClipboardData(text: shareUrl));
    _showMessage("GPS Pin link copied! Paste into Messenger, SMS, or Telegram.");
  }

  void _reCenterToUser() {
    if (_currentLocation != null) {
      setState(() => _autoCenter = true);
      _mapController.move(_currentLocation!, 16.0);
    } else {
      _toggleNavigation();
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _getRegionName(PhilippineRegion reg) {
    switch (reg) {
      case PhilippineRegion.metroManila:
        return "Metro Manila";
      case PhilippineRegion.metroCebu:
        return "Metro Cebu";
      case PhilippineRegion.metroDavao:
        return "Metro Davao";
      case PhilippineRegion.northernLuzon:
        return "Northern Luzon";
    }
  }

  @override
  Widget build(BuildContext context) {
    final tariff = nationwideFares[_selectedRoute.category] ?? nationwideFares[TransitCategory.traditionalJeep]!;
    final fare = tariff.calculateFare(_tripDistanceKm, isDiscounted: _isDiscounted);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Esri Watermark-Free Base Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedRoute.pathCoordinates.first,
              initialZoom: 13.5,
              onPositionChanged: (pos, hasGesture) {
                if (hasGesture && _autoCenter) {
                  setState(() => _autoCenter = false);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}',
                userAgentPackageName: 'com.jeeproute.ph',
                maxZoom: 16,
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _selectedRoute.pathCoordinates,
                    strokeWidth: 6.0,
                    color: _getRouteColor(_selectedRoute.category),
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedRoute.pathCoordinates.first,
                    width: 44,
                    height: 44,
                    child: _buildGlowMarker(Icons.directions_bus, const Color(0xFF10B981)),
                  ),
                  Marker(
                    point: _selectedRoute.pathCoordinates.last,
                    width: 44,
                    height: 44,
                    child: _buildGlowMarker(Icons.flag, const Color(0xFFEF4444)),
                  ),
                  if (_currentLocation != null)
                    Marker(
                      point: _currentLocation!,
                      width: 52,
                      height: 52,
                      child: _buildUserLiveLocationMarker(),
                    ),
                ],
              ),
            ],
          ),

          // 2. Top Navigation & Regional Selector
          Positioned(
            top: 48,
            left: 16,
            right: 16,
            child: Column(
              children: [
                _buildGlassContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.alt_route, color: Colors.black, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isNavigating ? "LIVE GPS ACTIVE • NATIONWIDE" : "JEEPROUTE PH • PHILIPPINES",
                              style: TextStyle(
                                fontSize: 9,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w900,
                                color: _isNavigating ? const Color(0xFF06B6D4) : const Color(0xFFF59E0B),
                              ),
                            ),
                            Text(
                              _selectedRoute.signboard,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      _buildTypePill(_selectedRoute.category),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Regional Pill Selector
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: PhilippineRegion.values.map((reg) {
                      final isSelected = reg == _selectedRegion;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: GestureDetector(
                          onTap: () => _onRegionChanged(reg),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFF1E293B).withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? const Color(0xFFF59E0B) : Colors.white24,
                              ),
                            ),
                            child: Text(
                              _getRegionName(reg),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.black : Colors.white70,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ).animate().slideY(begin: -0.4, end: 0, duration: 400.ms).fadeIn(),
          ),

          // 3. Floating Action Controls
          Positioned(
            right: 16,
            bottom: 350,
            child: Column(
              children: [
                if (_isNavigating) ...[
                  FloatingActionButton(
                    heroTag: "share_btn",
                    mini: true,
                    backgroundColor: const Color(0xFF1E293B),
                    foregroundColor: const Color(0xFF06B6D4),
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFF06B6D4)),
                    ),
                    onPressed: _shareLiveLocation,
                    child: const Icon(Icons.share_location, size: 20),
                  ),
                  const SizedBox(height: 10),
                ],
                FloatingActionButton(
                  heroTag: "center_btn",
                  mini: true,
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: _autoCenter && _isNavigating ? const Color(0xFF06B6D4) : Colors.white70,
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: _autoCenter && _isNavigating ? const Color(0xFF06B6D4) : Colors.white24,
                    ),
                  ),
                  onPressed: _reCenterToUser,
                  child: _isLocating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF06B6D4)),
                        )
                      : Icon(_autoCenter && _isNavigating ? Icons.my_location : Icons.location_searching),
                ),
              ],
            ),
          ),

          // 4. Bottom Control Sheet
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: _buildGlassContainer(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Start / Stop Live GPS Navigation Button
                  InkWell(
                    onTap: _toggleNavigation,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isNavigating
                              ? [const Color(0xFFDC2626), const Color(0xFF991B1B)]
                              : [const Color(0xFF06B6D4), const Color(0xFF0891B2)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: (_isNavigating ? const Color(0xFFDC2626) : const Color(0xFF06B6D4)).withOpacity(0.4),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isNavigating ? Icons.stop_circle_outlined : Icons.navigation,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isNavigating ? "STOP LIVE NAVIGATION" : "START NAVIGATION & TURN ON GPS",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Route Selection Chips for Region
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _currentRegionRoutes.map((route) {
                        final isSelected = route.id == _selectedRoute.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(route.signboard),
                            selected: isSelected,
                            selectedColor: const Color(0xFFF59E0B),
                            backgroundColor: const Color(0xFF1E293B),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.black : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            onSelected: (_) => _onSelectRoute(route),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Distance & Discount Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isNavigating ? Icons.gps_fixed : Icons.straighten,
                            size: 15,
                            color: _isNavigating ? const Color(0xFF06B6D4) : Colors.white54,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "${_tripDistanceKm.toStringAsFixed(1)} KM TO DESTINATION",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Text("20% Disc.", style: TextStyle(fontSize: 12, color: Colors.white60)),
                          const SizedBox(width: 4),
                          Switch(
                            value: _isDiscounted,
                            activeColor: const Color(0xFFF59E0B),
                            onChanged: (val) => setState(() => _isDiscounted = val),
                          ),
                        ],
                      ),
                    ],
                  ),

                  if (!_isNavigating)
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFFF59E0B),
                        inactiveTrackColor: Colors.white12,
                        thumbColor: Colors.white,
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: _tripDistanceKm.clamp(0.5, 30.0),
                        min: 0.5,
                        max: 30.0,
                        divisions: 59,
                        onChanged: (val) => setState(() => _tripDistanceKm = val),
                      ),
                    ),

                  const SizedBox(height: 10),

                  // Tariff Card Display
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.35)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${tariff.label.toUpperCase()} RATE",
                              style: const TextStyle(fontSize: 10, letterSpacing: 1.2, color: Colors.white54, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _selectedRoute.name,
                              style: const TextStyle(fontSize: 12, color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        Text(
                          "₱${fare.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().slideY(begin: 0.5, end: 0, duration: 400.ms).fadeIn(),
          ),
        ],
      ),
    );
  }

  Color _getRouteColor(TransitCategory cat) {
    switch (cat) {
      case TransitCategory.traditionalJeep:
        return const Color(0xFFF59E0B);
      case TransitCategory.modernJeep:
        return const Color(0xFF10B981);
      case TransitCategory.edsaCarousel:
        return const Color(0xFFEC4899);
      case TransitCategory.ordinaryBus:
      case TransitCategory.airconBus:
        return const Color(0xFF3B82F6);
      case TransitCategory.mrt3:
      case TransitCategory.lrt1:
      case TransitCategory.lrt2:
      case TransitCategory.pnr:
        return const Color(0xFFA855F7);
      case TransitCategory.tricycle:
        return const Color(0xFF06B6D4);
    }
  }

  Widget _buildTypePill(TransitCategory cat) {
    final color = _getRouteColor(cat);
    String label = "PUV";
    switch (cat) {
      case TransitCategory.traditionalJeep:
        label = "JEEP";
        break;
      case TransitCategory.modernJeep:
        label = "MPUV";
        break;
      case TransitCategory.edsaCarousel:
        label = "CAROUSEL";
        break;
      case TransitCategory.ordinaryBus:
      case TransitCategory.airconBus:
        label = "BUS";
        break;
      case TransitCategory.mrt3:
        label = "MRT-3";
        break;
      case TransitCategory.lrt1:
        label = "LRT-1";
        break;
      case TransitCategory.lrt2:
        label = "LRT-2";
        break;
      case TransitCategory.pnr:
        label = "PNR";
        break;
      case TransitCategory.tricycle:
        label = "TRIKE";
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _buildUserLiveLocationMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF06B6D4).withOpacity(0.25),
          ),
        ).animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(0.8, 0.8), end: const Offset(1.4, 1.4), duration: 1500.ms).fadeOut(),
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: const Color(0xFF06B6D4),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF06B6D4).withOpacity(0.8),
                blurRadius: 12,
                spreadRadius: 3,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGlassContainer({required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.75),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGlowMarker(IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withOpacity(0.6), blurRadius: 12, spreadRadius: 2)],
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.black, size: 18),
        ),
      ),
    );
  }
}
