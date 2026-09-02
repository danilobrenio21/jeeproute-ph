import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

// --- DATA MODELS & FARE RULES ---
enum TransitCategory {
  traditionalJeep,
  modernJeep,
  edsaCarousel,
  ordinaryBus,
  airconBus,
  mrt3,
  lrt1,
  tricycle,
}

class TransitRule {
  final String label;
  final double baseFare;
  final double baseDistanceKm;
  final double perKmRate;
  final double? maxCap;

  const TransitRule({
    required this.label,
    required this.baseFare,
    required this.baseDistanceKm,
    required this.perKmRate,
    this.maxCap,
  });

  double calculate(double distanceKm, {bool isDiscounted = false}) {
    double total = baseFare;
    if (distanceKm > baseDistanceKm) {
      total += (distanceKm - baseDistanceKm) * perKmRate;
    }
    if (maxCap != null && total > maxCap!) {
      total = maxCap!;
    }
    if (isDiscounted) {
      total *= 0.80;
    }
    return double.parse(total.toStringAsFixed(2));
  }
}

final Map<TransitCategory, TransitRule> tariffTable = {
  TransitCategory.traditionalJeep: const TransitRule(
    label: "Traditional Jeep",
    baseFare: 13.0,
    baseDistanceKm: 4.0,
    perKmRate: 1.80,
  ),
  TransitCategory.modernJeep: const TransitRule(
    label: "Modern PUV",
    baseFare: 15.0,
    baseDistanceKm: 4.0,
    perKmRate: 2.20,
  ),
  TransitCategory.edsaCarousel: const TransitRule(
    label: "EDSA Carousel",
    baseFare: 15.0,
    baseDistanceKm: 5.0,
    perKmRate: 2.65,
    maxCap: 75.50,
  ),
  TransitCategory.ordinaryBus: const TransitRule(
    label: "Ordinary Bus",
    baseFare: 15.0,
    baseDistanceKm: 5.0,
    perKmRate: 2.65,
  ),
  TransitCategory.airconBus: const TransitRule(
    label: "Aircon Bus",
    baseFare: 17.0,
    baseDistanceKm: 5.0,
    perKmRate: 3.10,
  ),
  TransitCategory.mrt3: const TransitRule(
    label: "MRT-3",
    baseFare: 13.0,
    baseDistanceKm: 2.0,
    perKmRate: 1.00,
    maxCap: 28.0,
  ),
  TransitCategory.lrt1: const TransitRule(
    label: "LRT-1",
    baseFare: 15.0,
    baseDistanceKm: 2.0,
    perKmRate: 1.21,
    maxCap: 45.0,
  ),
  TransitCategory.tricycle: const TransitRule(
    label: "Tricycle",
    baseFare: 15.0,
    baseDistanceKm: 1.0,
    perKmRate: 3.00,
  ),
};

class PlaceNode {
  final String name;
  final String city;
  final LatLng position;

  const PlaceNode({required this.name, required this.city, required this.position});
}

final List<PlaceNode> landmarkCatalog = [
  const PlaceNode(name: "Philcoa Terminal", city: "Quezon City", position: LatLng(14.6536, 121.0531)),
  const PlaceNode(name: "UP Diliman Campus", city: "Quezon City", position: LatLng(14.6585, 121.0722)),
  const PlaceNode(name: "SM North EDSA", city: "Quezon City", position: LatLng(14.6560, 121.0280)),
  const PlaceNode(name: "Trinoma / North Ave", city: "Quezon City", position: LatLng(14.6530, 121.0325)),
  const PlaceNode(name: "Araneta Center-Cubao", city: "Quezon City", position: LatLng(14.6195, 121.0514)),
  const PlaceNode(name: "Maginhawa Street", city: "Quezon City", position: LatLng(14.6492, 121.0615)),
  const PlaceNode(name: "Monumento Circle", city: "Caloocan", position: LatLng(14.6575, 120.9839)),
  const PlaceNode(name: "PITX Terminal", city: "Parañaque", position: LatLng(14.5097, 120.9912)),
  const PlaceNode(name: "Ayala Center Makati", city: "Makati", position: LatLng(14.5492, 121.0282)),
  const PlaceNode(name: "Cebu IT Park", city: "Cebu City", position: LatLng(10.3298, 123.9064)),
  const PlaceNode(name: "Colon Street Downtown", city: "Cebu City", position: LatLng(10.2975, 123.9001)),
  const PlaceNode(name: "Toril Public Market", city: "Davao City", position: LatLng(7.0185, 125.4988)),
  const PlaceNode(name: "Roxas Night Market", city: "Davao City", position: LatLng(7.0722, 125.6110)),
];

class AppRouteItem {
  final String id;
  final String signboard;
  final TransitCategory category;
  final List<LatLng> path;

  const AppRouteItem({
    required this.id,
    required this.signboard,
    required this.category,
    required this.path,
  });
}

final List<AppRouteItem> appRoutes = [
  const AppRouteItem(
    id: "NCR-01",
    signboard: "UP CAMPUS - IKOT",
    category: TransitCategory.traditionalJeep,
    path: [
      LatLng(14.6536, 121.0531),
      LatLng(14.6548, 121.0610),
      LatLng(14.6552, 121.0682),
      LatLng(14.6534, 121.0700),
      LatLng(14.6585, 121.0722),
    ],
  ),
  const AppRouteItem(
    id: "NCR-02",
    signboard: "EDSA CAROUSEL",
    category: TransitCategory.edsaCarousel,
    path: [
      LatLng(14.6575, 120.9839),
      LatLng(14.6530, 121.0325),
      LatLng(14.6195, 121.0514),
      LatLng(14.5878, 121.0567),
      LatLng(14.5492, 121.0282),
      LatLng(14.5097, 120.9912),
    ],
  ),
  const AppRouteItem(
    id: "NCR-03",
    signboard: "MRT-3 EXPRESS",
    category: TransitCategory.mrt3,
    path: [
      LatLng(14.6523, 121.0323),
      LatLng(14.6352, 121.0435),
      LatLng(14.6195, 121.0514),
      LatLng(14.5880, 121.0563),
      LatLng(14.5378, 121.0014),
    ],
  ),
  const AppRouteItem(
    id: "NCR-04",
    signboard: "SIKATUNA TODA",
    category: TransitCategory.tricycle,
    path: [
      LatLng(14.6468, 121.0588),
      LatLng(14.6485, 121.0608),
      LatLng(14.6515, 121.0652),
    ],
  ),
  const AppRouteItem(
    id: "CEB-01",
    signboard: "CEBU 17B MODERN",
    category: TransitCategory.modernJeep,
    path: [
      LatLng(10.3298, 123.9064),
      LatLng(10.3175, 123.9056),
      LatLng(10.2975, 123.9001),
    ],
  ),
];

// --- APP ROOT ---
void main() => runApp(const JeepRouteApp());

class JeepRouteApp extends StatelessWidget {
  const JeepRouteApp({super.key});

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
      home: const MainMapScreen(),
    );
  }
}

class MainMapScreen extends StatefulWidget {
  const MainMapScreen({super.key});

  @override
  State<MainMapScreen> createState() => _MainMapScreenState();
}

class _MainMapScreenState extends State<MainMapScreen> {
  final MapController _map = MapController();
  final Distance _dist = const Distance();

  String _originName = "Philcoa Terminal";
  String _destName = "UP Diliman Campus";
  LatLng _originPt = const LatLng(14.6536, 121.0531);
  LatLng _destPt = const LatLng(14.6585, 121.0722);

  AppRouteItem _currentRoute = appRoutes[0];
  double _distanceKm = 4.2;
  bool _discount = false;

  bool _navigating = false;
  LatLng? _userPos;
  StreamSubscription<Position>? _posStream;

  @override
  void dispose() {
    _posStream?.cancel();
    super.dispose();
  }

  void _recalc() {
    final meters = _dist.as(LengthUnit.Meter, _originPt, _destPt);
    setState(() {
      _distanceKm = (meters / 1000).clamp(0.5, 300.0);
    });
    _map.move(_originPt, 14.0);
  }

  Future<void> _fetchGPS() async {
    bool on = await Geolocator.isLocationServiceEnabled();
    if (!on) return;
    LocationPermission p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
    if (p == LocationPermission.denied || p == LocationPermission.deniedForever) return;

    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _userPos = LatLng(pos.latitude, pos.longitude);
      _originPt = _userPos!;
      _originName = "Current GPS Location";
    });
    _recalc();
  }

  Future<void> _toggleNav() async {
    if (_navigating) {
      await _posStream?.cancel();
      setState(() {
        _navigating = false;
        _userPos = null;
      });
      return;
    }

    bool on = await Geolocator.isLocationServiceEnabled();
    if (!on) return;
    LocationPermission p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
    if (p == LocationPermission.denied || p == LocationPermission.deniedForever) return;

    setState(() => _navigating = true);
    _posStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation, distanceFilter: 3),
    ).listen((p) {
      final pt = LatLng(p.latitude, p.longitude);
      setState(() {
        _userPos = pt;
        final meters = _dist.as(LengthUnit.Meter, pt, _destPt);
        _distanceKm = (meters / 1000).clamp(0.5, 300.0);
      });
      _map.move(pt, _map.camera.zoom);
    });
  }

  Future<void> _launchMaps() async {
    final url = "https://www.google.com/maps/dir/?api=1&origin=${_originPt.latitude},${_originPt.longitude}&destination=${_destPt.latitude},${_destPt.longitude}&travelmode=transit";
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openSelectModal(bool isOrigin) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isOrigin ? "Choose Origin" : "Choose Destination",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
              ),
              const SizedBox(height: 10),
              if (isOrigin)
                ListTile(
                  leading: const Icon(Icons.my_location, color: Color(0xFF06B6D4)),
                  title: const Text("Use Current Location", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _fetchGPS();
                  },
                ),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: landmarkCatalog.length,
                  itemBuilder: (c, i) {
                    final node = landmarkCatalog[i];
                    return ListTile(
                      title: Text(node.name, style: const TextStyle(color: Colors.white)),
                      subtitle: Text(node.city, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                      onTap: () {
                        setState(() {
                          if (isOrigin) {
                            _originName = node.name;
                            _originPt = node.position;
                          } else {
                            _destName = node.name;
                            _destPt = node.position;
                          }
                        });
                        Navigator.pop(ctx);
                        _recalc();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final rule = tariffTable[_currentRoute.category] ?? tariffTable[TransitCategory.traditionalJeep]!;
    final fare = rule.calculate(_distanceKm, isDiscounted: _discount);

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _originPt,
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}',
                userAgentPackageName: 'com.jeeproute.ph',
                maxZoom: 16,
              ),
              PolylineLayer(
                polylines: [
                  Polyline(points: _currentRoute.path, strokeWidth: 5.5, color: const Color(0xFFF59E0B)),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _originPt,
                    width: 36,
                    height: 36,
                    child: const Icon(Icons.trip_origin, color: Color(0xFF10B981), size: 30),
                  ),
                  Marker(
                    point: _destPt,
                    width: 36,
                    height: 36,
                    child: const Icon(Icons.location_on, color: Color(0xFFEF4444), size: 36),
                  ),
                  if (_userPos != null)
                    Marker(
                      point: _userPos!,
                      width: 22,
                      height: 22,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF06B6D4),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Safe Top Search Bar
          Positioned(
            top: 0,
            left: 14,
            right: 14,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      color: const Color(0xFF1E293B).withOpacity(0.85),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.trip_origin, color: Color(0xFF10B981), size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _openSelectModal(true),
                                  child: Text(_originName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12), overflow: TextOverflow.ellipsis),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.my_location, color: Color(0xFF06B6D4), size: 18),
                                onPressed: _fetchGPS,
                              )
                            ],
                          ),
                          const Divider(height: 10, color: Colors.white12),
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Color(0xFFEF4444), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _openSelectModal(false),
                                  child: Text(_destName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12), overflow: TextOverflow.ellipsis),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom Planning Sheet
          Positioned(
            left: 14,
            right: 14,
            bottom: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  color: const Color(0xFF1E293B).withOpacity(0.88),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _navigating ? const Color(0xFFDC2626) : const Color(0xFF06B6D4),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _toggleNav,
                              icon: Icon(_navigating ? Icons.stop : Icons.navigation, size: 16),
                              label: Text(_navigating ? "STOP GPS" : "START LIVE GPS", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _launchMaps,
                            icon: const Icon(Icons.map, size: 16),
                            label: const Text("G-MAPS", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: appRoutes.map((r) {
                            final isSel = r.id == _currentRoute.id;
                            final rRule = tariffTable[r.category]!;
                            final c = rRule.calculate(_distanceKm, isDiscounted: _discount);
                            return Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: ChoiceChip(
                                label: Text("${r.signboard} ₱${c.toStringAsFixed(2)}"),
                                selected: isSel,
                                selectedColor: const Color(0xFFF59E0B),
                                labelStyle: TextStyle(color: isSel ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                onSelected: (_) {
                                  setState(() => _currentRoute = r);
                                  _map.move(r.path.first, 14.0);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("${_distanceKm.toStringAsFixed(1)} KM TRIP", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white70)),
                          Row(
                            children: [
                              const Text("20% Disc.", style: TextStyle(fontSize: 11, color: Colors.white60)),
                              Switch(
                                value: _discount,
                                activeColor: const Color(0xFFF59E0B),
                                onChanged: (v) => setState(() => _discount = v),
                              ),
                            ],
                          ),
                        ],
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("${rule.label.toUpperCase()} FARE", style: const TextStyle(fontSize: 9, color: Colors.white54, fontWeight: FontWeight.bold)),
                                Text("$_originName ➔ $_destName", style: const TextStyle(fontSize: 11, color: Colors.white), overflow: TextOverflow.ellipsis),
                              ],
                            ),
                            Text("₱${fare.toStringAsFixed(2)}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFFF59E0B))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
