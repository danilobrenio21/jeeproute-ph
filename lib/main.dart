import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
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
  PUVRoute _selectedRoute = sampleRoutes[0];
  double _tripDistanceKm = 3.5;
  bool _isDiscounted = false;

  void _onSelectRoute(PUVRoute route) {
    setState(() => _selectedRoute = route);
    _mapController.move(route.pathCoordinates.first, 14.5);
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
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedRoute.pathCoordinates.first,
              initialZoom: 14.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.jeeproute.ph',
              ),
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
                ],
              ),
            ],
          ),
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
                          "JEEP ROUTE PH",
                          style: TextStyle(
                            fontSize: 12,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${_tripDistanceKm.toStringAsFixed(1)} KM TRIP",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white70),
                      ),
                      Row(
                        children: [
                          const Text("20% Student/PWD", style: TextStyle(fontSize: 12, color: Colors.white60)),
                          const SizedBox(width: 6),
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
                      min: 1.0,
                      max: 15.0,
                      divisions: 28,
                      onChanged: (val) => setState(() => _tripDistanceKm = val),
                    ),
                  ),
                  const SizedBox(height: 12),
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
                            const Text("ESTIMATED FARE", style: TextStyle(fontSize: 11, letterSpacing: 1.2, color: Colors.white54)),
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
