import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
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
      home: const ModernRouteMapScreen(),
    );
  }
}

class ModernRouteMapScreen extends StatefulWidget {
  const ModernRouteMapScreen({super.key});

  @override
  State<ModernRouteMapScreen> createState() => _ModernRouteMapScreenState();
}

class _ModernRouteMapScreenState extends State<ModernRouteMapScreen> {
  final MapController _mapController = MapController();
  final Distance _distanceCalculator = const Distance();

  PUVRoute _selectedRoute = sampleRoutes[0];
  double _tripDistanceKm = 3.5;
  bool _isDiscounted = false;

  // Realtime GPS State
  LatLng? _currentLocation;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isLocating = false;
  bool _autoCenter = true;

  @override
  void initState() {
    super.initState();
    _startLiveGpsTracking();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startLiveGpsTracking() async {
    setState(() => _isLocating = true);

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _isLocating = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLocating = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _isLocating = false);
      return;
    }

    // High accuracy GPS Stream for realtime phone navigation
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 3, // Updates every 3 meters moved
    );

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        final newPoint = LatLng(position.latitude, position.longitude);
        setState(() {
          _currentLocation = newPoint;
          _isLocating = false;

          // Dynamically compute real distance to the destination terminal
          final dest = _selectedRoute.pathCoordinates.last;
          final metersToDest = _distanceCalculator.as(LengthUnit.Meter, newPoint, dest);
          _tripDistanceKm = (metersToDest / 1000).clamp(0.5, 30.0);
        });

        if (_autoCenter) {
          _mapController.move(newPoint, _mapController.camera.zoom);
        }
      },
      onError: (err) {
        setState(() => _isLocating = false);
      },
    );
  }

  void _onSelectRoute(PUVRoute route) {
    setState(() {
      _selectedRoute = route;
      if (_currentLocation != null) {
        final dest = route.pathCoordinates.last;
        final meters = _distanceCalculator.as(LengthUnit.Meter, _currentLocation!, dest);
        _tripDistanceKm = (meters / 1000).clamp(0.5, 30.0);
      }
    });
    _mapController.move(route.pathCoordinates.first, 14.5);
  }

  void _reCenterToUser() {
    if (_currentLocation != null) {
      setState(() => _autoCenter = true);
      _mapController.move(_currentLocation!, 16.0);
    } else {
      _startLiveGpsTracking();
    }
  }

  @override
  Widget build(BuildContext context) {
    double fare = _selectedRoute.computeFare(
      _tripDistanceKm,
      isDiscounted: _isDiscounted,
    );

    return Scaffold(
      body: Stack(
        children: [
          // 1. Watermark-Free Esri Dark Map Canvas
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedRoute.pathCoordinates.first,
              initialZoom: 14.5,
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

              // PUV Route Line
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _selectedRoute.pathCoordinates,
                    strokeWidth: 6.0,
                    color: _selectedRoute.vehicleType == VehicleType.tricycle
                        ? const Color(0xFF06B6D4)
                        : const Color(0xFFF59E0B),
                  ),
                ],
              ),

              // Route & Realtime GPS Markers
              MarkerLayer(
                markers: [
                  // Origin Terminal Marker
                  Marker(
                    point: _selectedRoute.pathCoordinates.first,
                    width: 44,
                    height: 44,
                    child: _buildGlowMarker(Icons.directions_bus, const Color(0xFF10B981)),
                  ),

                  // Destination Terminal Marker
                  Marker(
                    point: _selectedRoute.pathCoordinates.last,
                    width: 44,
                    height: 44,
                    child: _buildGlowMarker(Icons.flag, const Color(0xFFEF4444)),
                  ),

                  // Realtime User GPS Location Marker
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

          // 2. Top Floating Navigation Header
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: _buildGlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    child: const Icon(Icons.alt_route, color: Colors.black, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "JEEP ROUTE PH • LIVE GPS",
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                        Text(
                          _selectedRoute.signboard,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _buildTypePill(_selectedRoute.vehicleType),
                ],
              ),
            ).animate().slideY(begin: -0.5, end: 0, duration: 400.ms).fadeIn(),
          ),

          // 3. Floating GPS "Recenter" Action Button
          Positioned(
            right: 16,
            bottom: 275,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: const Color(0xFF1E293B),
              foregroundColor: _autoCenter ? const Color(0xFF06B6D4) : Colors.white70,
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: _autoCenter ? const Color(0xFF06B6D4) : Colors.white24,
                ),
              ),
              onPressed: _reCenterToUser,
              child: _isLocating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF06B6D4)),
                    )
                  : Icon(_autoCenter ? Icons.my_location : Icons.location_searching),
            ),
          ),

          // 4. Bottom Control Card with Dynamic Fare Calculation
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: _buildGlassContainer(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Horizontal Route Selection Pills
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: sampleRoutes.map((route) {
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
                              fontSize: 13,
                            ),
                            onSelected: (_) => _onSelectRoute(route),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Distance & Discount Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _currentLocation != null ? Icons.gps_fixed : Icons.straighten,
                            size: 15,
                            color: _currentLocation != null ? const Color(0xFF06B6D4) : Colors.white54,
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
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFFF59E0B),
                      inactiveTrackColor: Colors.white12,
                      thumbColor: Colors.white,
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: _tripDistanceKm,
                      min: 0.5,
                      max: 20.0,
                      divisions: 39,
                      onChanged: (val) => setState(() {
                        _tripDistanceKm = val;
                      }),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Dynamic Realtime Fare Output
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.35)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withOpacity(0.12),
                          blurRadius: 18,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("CALCULATED FARE", style: TextStyle(fontSize: 10, letterSpacing: 1.2, color: Colors.white54)),
                            Text(_selectedRoute.name, style: const TextStyle(fontSize: 13, color: Colors.white)),
                          ],
                        ),
                        Text(
                          "₱${fare.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 26,
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

  Widget _buildTypePill(VehicleType type) {
    final isJeep = type == VehicleType.traditionalJeep;
    final isModern = type == VehicleType.modernJeep;
    final color = isModern ? const Color(0xFF10B981) : (isJeep ? const Color(0xFFF59E0B) : const Color(0xFF06B6D4));
    final label = isModern ? "MPUV" : (isJeep ? "JEEP" : "TRIKE");

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900),
      ),
    );
  }
}
