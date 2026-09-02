import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
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

  final TextEditingController _originCtrl = TextEditingController(text: "My Current Location");
  final TextEditingController _destCtrl = TextEditingController(text: "UP Diliman Campus");
  LatLng? _searchOriginPoint;
  LatLng? _searchDestPoint;

  final PhilippineRegion _selectedRegion = PhilippineRegion.metroManila;
  late NationwideRoute _selectedRoute;
  double _tripDistanceKm = 3.5;
  bool _isDiscounted = false;

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
    _searchDestPoint = _selectedRoute.pathCoordinates.last;
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _originCtrl.dispose();
    _destCtrl.dispose();
    super.dispose();
  }

  List<NationwideRoute> get _currentRegionRoutes {
    return sampleNationwideRoutes.where((r) => r.region == _selectedRegion).toList();
  }

  void _calculateTripFromSearch() {
    LatLng origin = _searchOriginPoint ?? (_currentLocation ?? _selectedRoute.pathCoordinates.first);
    LatLng dest = _searchDestPoint ?? _selectedRoute.pathCoordinates.last;

    final meters = _distanceCalculator.as(LengthUnit.Meter, origin, dest);
    setState(() {
      _tripDistanceKm = (meters / 1000).clamp(0.5, 300.0);
    });

    _mapController.move(origin, 14.0);
  }

  Future<void> _useCurrentLocationAsOrigin() async {
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
      _showMessage("Location permission permanently denied in device settings.");
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final userPt = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _currentLocation = userPt;
        _searchOriginPoint = userPt;
        _originCtrl.text = "My Current Location (GPS)";
        _isLocating = false;
      });
      _calculateTripFromSearch();
      _showMessage("Origin updated to live GPS location.");
    } catch (_) {
      setState(() => _isLocating = false);
      _showMessage("Could not fetch GPS coordinates.");
    }
  }

  void _chooseLandmark(BuildContext sheetContext, {required bool isOrigin, required LandmarkNode node}) {
    setState(() {
      if (isOrigin) {
        _originCtrl.text = node.name;
        _searchOriginPoint = node.coordinates;
      } else {
        _destCtrl.text = node.name;
        _searchDestPoint = node.coordinates;
      }
    });
    Navigator.pop(sheetContext);
    _calculateTripFromSearch();
  }

  void _openSearchDialog(bool isOrigin) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isOrigin ? "Select Origin Terminal / Landmark" : "Select Destination Terminal / Landmark",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFF59E0B)),
              ),
              const SizedBox(height: 12),
              if (isOrigin)
                ListTile(
                  leading: const Icon(Icons.my_location, color: Color(0xFF06B6D4)),
                  title: const Text("Use My Current GPS Location", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _useCurrentLocationAsOrigin();
                  },
                ),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: searchableLandmarks.length,
                  itemBuilder: (ctx, i) {
                    final node = searchableLandmarks[i];
                    return ListTile(
                      leading: const Icon(Icons.place_outlined, color: Colors.white70),
                      title: Text(node.name, style: const TextStyle(color: Colors.white)),
                      subtitle: Text(node.city, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                      onTap: () => _chooseLandmark(sheetContext, isOrigin: isOrigin, node: node),
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
      _showMessage("Location permission permanently denied in device settings.");
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

          final dest = _searchDestPoint ?? _selectedRoute.pathCoordinates.last;
          final metersToDest = _distanceCalculator.as(LengthUnit.Meter, newPoint, dest);
          _tripDistanceKm = (metersToDest / 1000).clamp(0.5, 30.0);
        });

        if (_autoCenter) {
          _mapController.move(newPoint, _mapController.camera.zoom);
        }
      },
      onError: (_) {
        setState(() {
          _isLocating = false;
          _isNavigating = false;
        });
        _showMessage("GPS stream disconnected.");
      },
    );
  }

  Future<void> _openGoogleMapsNavigation() async {
    final dest = _searchDestPoint ?? _selectedRoute.pathCoordinates.last;
    final destLat = dest.latitude;
    final destLng = dest.longitude;

    String urlStr;
    if (_currentLocation != null) {
      final originLat = _currentLocation!.latitude;
      final originLng = _currentLocation!.longitude;
      urlStr = "https://www.google.com/maps/dir/?api=1&origin=$originLat,$originLng&destination=$destLat,$destLng&travelmode=transit";
    } else {
      urlStr = "https://www.google.com/maps/dir/?api=1&destination=$destLat,$destLng&travelmode=transit";
    }

    final uri = Uri.parse(urlStr);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showMessage("Could not launch Google Maps.");
    }
  }

  void _shareLiveLocation() {
    if (_currentLocation == null) {
      _showMessage("Turn on GPS first to capture live coordinates.");
      return;
    }
    final shareUrl = "https://maps.google.com/?q=${_currentLocation!.latitude},${_currentLocation!.longitude}";
    Clipboard.setData(ClipboardData(text: shareUrl));
    _showMessage("Live pin copied! Paste into Messenger or SMS.");
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

  @override
  Widget build(BuildContext context) {
    final tariff = nationwideFares[_selectedRoute.category] ?? nationwideFares[TransitCategory.traditionalJeep]!;
    final fare = tariff.calculateFare(_tripDistanceKm, isDiscounted: _isDiscounted);
    final routeColor = _getRouteColor(_selectedRoute.category);

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedRoute.pathCoordinates.first,
              initialZoom: 14.0,
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
                    strokeWidth: 5.5,
                    color: routeColor,
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

          Positioned(
            top: 0,
            left: 16,
            right: 16,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: _buildGlassContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.trip_origin, color: Color(0xFF10B981), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _openSearchDialog(true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: Text(
                                  _originCtrl.text,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(Icons.my_location, color: Color(0xFF06B6D4), size: 20),
                            tooltip: "Use Current GPS Location",
                            onPressed: _useCurrentLocationAsOrigin,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Color(0xFFEF4444), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _openSearchDialog(false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: Text(
                                  _destCtrl.text,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().slideY(begin: -0.4, end: 0, duration: 400.ms).fadeIn(),
          ),

          Positioned(
            right: 16,
            bottom: 390,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: "gmaps_btn",
                  mini: true,
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: const Color(0xFF10B981),
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFF10B981)),
                  ),
                  onPressed: _openGoogleMapsNavigation,
                  child: const Icon(Icons.directions, size: 22),
                ),
                const SizedBox(height: 10),
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

          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: _buildGlassContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: InkWell(
                          onTap: _toggleNavigation,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 11),
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
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isNavigating ? Icons.stop_circle_outlined : Icons.navigation,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _isNavigating ? "STOP GPS" : "START LIVE GPS",
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: InkWell(
                          onTap: _openGoogleMapsNavigation,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF059669)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.map, color: Colors.white, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  "G-MAPS",
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "SUGGESTED MODES OF TRANSPORTATION",
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.1, color: Color(0xFFF59E0B)),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _currentRegionRoutes.map((route) {
                        final isSelected = route.id == _selectedRoute.id;
                        final rule = nationwideFares[route.category] ?? nationwideFares[TransitCategory.traditionalJeep]!;
                        final cost = rule.calculateFare(_tripDistanceKm, isDiscounted: _isDiscounted);

                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedRoute = route;
                                _searchDestPoint = route.pathCoordinates.last;
                              });
                              _calculateTripFromSearch();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFFF59E0B) : Colors.white12,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    route.signboard,
                                    style: TextStyle(
                                      color: isSelected ? Colors.black : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    "₱${cost.toStringAsFixed(2)}",
                                    style: TextStyle(
                                      color: isSelected ? Colors.black : const Color(0xFF06B6D4),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${_tripDistanceKm.toStringAsFixed(1)} KM TRIP DISTANCE",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white70),
                      ),
                      Row(
                        children: [
                          const Text("20% Disc.", style: TextStyle(fontSize: 11, color: Colors.white60)),
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
                  Container(
                    margin: const EdgeInsets.top(6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.35)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${tariff.label.toUpperCase()} ESTIMATE",
                                style: const TextStyle(fontSize: 9, letterSpacing: 1.1, color: Colors.white54, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "${_originCtrl.text} ➔ ${_destCtrl.text}",
                                style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "₱${fare.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 22,
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
