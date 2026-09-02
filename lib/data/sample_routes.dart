import 'package:latlong2/latlong.dart';
import '../models/puv_route.dart';

enum PhilippineRegion {
  metroManila,
  metroCebu,
  metroDavao,
  northernLuzon,
}

class NationwideRoute {
  final String id;
  final String name;
  final String signboard;
  final PhilippineRegion region;
  final TransitCategory category;
  final String originTerminal;
  final String destTerminal;
  final List<LatLng> pathCoordinates;

  const NationwideRoute({
    required this.id,
    required this.name,
    required this.signboard,
    required this.region,
    required this.category,
    required this.originTerminal,
    required this.destTerminal,
    required this.pathCoordinates,
  });
}

final List<NationwideRoute> sampleNationwideRoutes = [
  // --- METRO MANILA ---
  NationwideRoute(
    id: "NCR-JEEP-01",
    name: "Philcoa - UP Diliman Campus",
    signboard: "UP CAMPUS - IKOT",
    region: PhilippineRegion.metroManila,
    category: TransitCategory.traditionalJeep,
    originTerminal: "Philcoa Terminal",
    destTerminal: "UP Diliman Campus",
    pathCoordinates: const [
      LatLng(14.6542, 121.0531),
      LatLng(14.6560, 121.0590),
      LatLng(14.6538, 121.0684),
      LatLng(14.6585, 121.0722),
    ],
  ),
  NationwideRoute(
    id: "NCR-CAROUSEL-02",
    name: "EDSA Carousel (Monumento - PITX)",
    signboard: "EDSA CAROUSEL",
    region: PhilippineRegion.metroManila,
    category: TransitCategory.edsaCarousel,
    originTerminal: "Monumento Concourse",
    destTerminal: "PITX Gate 4",
    pathCoordinates: const [
      LatLng(14.6575, 120.9839),
      LatLng(14.6521, 121.0323),
      LatLng(14.6195, 121.0514),
      LatLng(14.5878, 121.0567),
      LatLng(14.5378, 121.0014),
      LatLng(14.5097, 120.9912),
    ],
  ),
  NationwideRoute(
    id: "NCR-MRT3-03",
    name: "MRT-3 (North Ave to Taft Ave)",
    signboard: "MRT-3 FULL LOOP",
    region: PhilippineRegion.metroManila,
    category: TransitCategory.mrt3,
    originTerminal: "North Avenue Station",
    destTerminal: "Taft Avenue Station",
    pathCoordinates: const [
      LatLng(14.6523, 121.0323),
      LatLng(14.6360, 121.0428),
      LatLng(14.6195, 121.0514),
      LatLng(14.5880, 121.0563),
      LatLng(14.5539, 121.0267),
      LatLng(14.5378, 121.0014),
    ],
  ),
  NationwideRoute(
    id: "NCR-LRT1-04",
    name: "LRT-1 (FPJ Station to Dr. Santos)",
    signboard: "LRT-1 CAVITE EXT.",
    region: PhilippineRegion.metroManila,
    category: TransitCategory.lrt1,
    originTerminal: "Fernando Poe Jr. Station",
    destTerminal: "Dr. Santos Station (Sucat)",
    pathCoordinates: const [
      LatLng(14.6572, 121.0189),
      LatLng(14.6033, 120.9822),
      LatLng(14.5633, 120.9950),
      LatLng(14.5350, 121.0003),
      LatLng(14.4988, 120.9930),
    ],
  ),
  NationwideRoute(
    id: "NCR-TRIKE-05",
    name: "Maginhawa TODA Inner Route",
    signboard: "SIKATUNA TODA",
    region: PhilippineRegion.metroManila,
    category: TransitCategory.tricycle,
    originTerminal: "V. Luna Extension",
    destTerminal: "CP Garcia Junction",
    pathCoordinates: const [
      LatLng(14.6468, 121.0588),
      LatLng(14.6482, 121.0605),
      LatLng(14.6501, 121.0632),
    ],
  ),

  // --- METRO CEBU ---
  NationwideRoute(
    id: "CEB-MPUV-01",
    name: "IT Park - Ayala - Colon Modern PUV",
    signboard: "17B / 17D MODERN",
    region: PhilippineRegion.metroCebu,
    category: TransitCategory.modernJeep,
    originTerminal: "Cebu IT Park Hub",
    destTerminal: "Colon Obelisk Downtown",
    pathCoordinates: const [
      LatLng(10.3298, 123.9064),
      LatLng(10.3175, 123.9056),
      LatLng(10.3114, 123.8988),
      LatLng(10.2975, 123.9001),
    ],
  ),
  NationwideRoute(
    id: "CEB-BUS-02",
    name: "Cebu South Bus Terminal - Carcar",
    signboard: "CEBU - CARCAR AIRCON",
    region: PhilippineRegion.metroCebu,
    category: TransitCategory.airconBus,
    originTerminal: "Cebu South Bus Terminal",
    destTerminal: "Carcar City Rotunda",
    pathCoordinates: const [
      LatLng(10.3006, 123.8920),
      LatLng(10.2580, 123.8400),
      LatLng(10.1585, 123.7145),
      LatLng(10.1065, 123.6397),
    ],
  ),

  // --- METRO DAVAO ---
  NationwideRoute(
    id: "DAV-JEEP-01",
    name: "Toril - Roxas Night Market via McArthur",
    signboard: "TORIL - ROXAS",
    region: PhilippineRegion.metroDavao,
    category: TransitCategory.traditionalJeep,
    originTerminal: "Toril Public Market",
    destTerminal: "Roxas Night Market / Ateneo",
    pathCoordinates: const [
      LatLng(7.0185, 125.4988),
      LatLng(7.0450, 125.5450),
      LatLng(7.0650, 125.5890),
      LatLng(7.0722, 125.6110),
    ],
  ),
  NationwideRoute(
    id: "DAV-MPUV-02",
    name: "Sasa Port - Matina Gallera Peak",
    signboard: "SASA - MATINA MPUV",
    region: PhilippineRegion.metroDavao,
    category: TransitCategory.modernJeep,
    originTerminal: "Sasa Ferry Terminal",
    destTerminal: "Matina Crossing Hub",
    pathCoordinates: const [
      LatLng(7.1265, 125.6601),
      LatLng(7.0980, 125.6300),
      LatLng(7.0680, 125.6020),
      LatLng(7.0540, 125.5790),
    ],
  ),

  // --- NORTHERN LUZON ---
  NationwideRoute(
    id: "NL-BUS-01",
    name: "Cubao - Baguio Express Point",
    signboard: "CUBAO - BAGUIO LUX",
    region: PhilippineRegion.northernLuzon,
    category: TransitCategory.airconBus,
    originTerminal: "Cubao Bus Terminal",
    destTerminal: "Gov. Pack Rd. Baguio",
    pathCoordinates: const [
      LatLng(14.6195, 121.0514),
      LatLng(15.4865, 120.5980),
      LatLng(15.9750, 120.5700),
      LatLng(16.4023, 120.5960),
    ],
  ),
  NationwideRoute(
    id: "NL-JEEP-02",
    name: "Baguio Plaza - Mines View Park Loop",
    signboard: "MINES VIEW PARK",
    region: PhilippineRegion.northernLuzon,
    category: TransitCategory.traditionalJeep,
    originTerminal: "Baguio City Plaza Hub",
    destTerminal: "Mines View Park Ridge",
    pathCoordinates: const [
      LatLng(16.4135, 120.5955),
      LatLng(16.4150, 120.6100),
      LatLng(16.4245, 120.6275),
    ],
  ),
];
