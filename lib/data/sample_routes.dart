import 'package:latlong2/latlong.dart';
import '../models/puv_route.dart';

enum PhilippineRegion {
  metroManila,
  metroCebu,
  metroDavao,
  northernLuzon,
}

class TransitStop {
  final String name;
  final LatLng position;
  final double distanceKmFromOrigin;

  const TransitStop({
    required this.name,
    required this.position,
    required this.distanceKmFromOrigin,
  });
}

class NationwideRoute {
  final String id;
  final String name;
  final String signboard;
  final PhilippineRegion region;
  final TransitCategory category;
  final String originTerminal;
  final String destTerminal;
  final List<TransitStop> stops;
  final List<LatLng> pathCoordinates;

  const NationwideRoute({
    required this.id,
    required this.name,
    required this.signboard,
    required this.region,
    required this.category,
    required this.originTerminal,
    required this.destTerminal,
    required this.stops,
    required this.pathCoordinates,
  });
}

class LandmarkNode {
  final String name;
  final String city;
  final LatLng coordinates;

  const LandmarkNode({
    required this.name,
    required this.city,
    required this.coordinates,
  });
}

// Searchable Landmark Nodes for Auto-Complete & Origin/Destination Pairing
final List<LandmarkNode> searchableLandmarks = [
  const LandmarkNode(name: "Philcoa Terminal", city: "Quezon City", coordinates: LatLng(14.6536, 121.0531)),
  const LandmarkNode(name: "UP Diliman Campus", city: "Quezon City", coordinates: LatLng(14.6585, 121.0722)),
  const LandmarkNode(name: "SM North EDSA", city: "Quezon City", coordinates: LatLng(14.6560, 121.0280)),
  const LandmarkNode(name: "Trinoma / North Ave", city: "Quezon City", coordinates: LatLng(14.6530, 121.0325)),
  const LandmarkNode(name: "Araneta Center-Cubao", city: "Quezon City", coordinates: LatLng(14.6195, 121.0514)),
  const LandmarkNode(name: "Maginhawa Food Street", city: "Quezon City", coordinates: LatLng(14.6492, 121.0615)),
  const LandmarkNode(name: "Monumento Circle", city: "Caloocan", coordinates: LatLng(14.6575, 120.9839)),
  const LandmarkNode(name: "PITX Metro Terminal", city: "Parañaque", coordinates: LatLng(14.5097, 120.9912)),
  const LandmarkNode(name: "Taft Ave Station", city: "Pasay", coordinates: LatLng(14.5378, 121.0014)),
  const LandmarkNode(name: "Ayala Center Makati", city: "Makati", coordinates: LatLng(14.5492, 121.0282)),
  const LandmarkNode(name: "Cebu IT Park", city: "Cebu City", coordinates: LatLng(10.3298, 123.9064)),
  const LandmarkNode(name: "Colon Street", city: "Cebu City", coordinates: LatLng(10.2975, 123.9001)),
  const LandmarkNode(name: "Toril Public Market", city: "Davao City", coordinates: LatLng(7.0185, 125.4988)),
  const LandmarkNode(name: "Roxas Night Market", city: "Davao City", coordinates: LatLng(7.0722, 125.6110)),
  const LandmarkNode(name: "Baguio City Plaza", city: "Baguio City", coordinates: LatLng(16.4135, 120.5955)),
  const LandmarkNode(name: "Mines View Park", city: "Baguio City", coordinates: LatLng(16.4245, 120.6275)),
];

final List<NationwideRoute> sampleNationwideRoutes = [
  // 1. Philcoa - UP Diliman
  NationwideRoute(
    id: "NCR-JEEP-01",
    name: "Philcoa - UP Diliman Campus",
    signboard: "UP CAMPUS - IKOT",
    region: PhilippineRegion.metroManila,
    category: TransitCategory.traditionalJeep,
    originTerminal: "Philcoa Terminal",
    destTerminal: "UP Diliman Campus",
    stops: const [
      TransitStop(name: "Philcoa Terminal", position: LatLng(14.6536, 121.0531), distanceKmFromOrigin: 0.0),
      TransitStop(name: "University Ave / CP Garcia", position: LatLng(14.6548, 121.0610), distanceKmFromOrigin: 1.1),
      TransitStop(name: "UP Oblation Plaza", position: LatLng(14.6552, 121.0682), distanceKmFromOrigin: 2.2),
      TransitStop(name: "Palma Hall (AS)", position: LatLng(14.6534, 121.0700), distanceKmFromOrigin: 3.1),
      TransitStop(name: "Vinzons Hall End Terminal", position: LatLng(14.6585, 121.0722), distanceKmFromOrigin: 4.2),
    ],
    pathCoordinates: const [
      LatLng(14.6536, 121.0531),
      LatLng(14.6541, 121.0558),
      LatLng(14.6545, 121.0585),
      LatLng(14.6548, 121.0610),
      LatLng(14.6550, 121.0652),
      LatLng(14.6552, 121.0682),
      LatLng(14.6540, 121.0692),
      LatLng(14.6534, 121.0700),
      LatLng(14.6547, 121.0718),
      LatLng(14.6585, 121.0722),
    ],
  ),

  // 2. EDSA Busway Carousel
  NationwideRoute(
    id: "NCR-CAROUSEL-02",
    name: "EDSA Busway Carousel",
    signboard: "EDSA CAROUSEL",
    region: PhilippineRegion.metroManila,
    category: TransitCategory.edsaCarousel,
    originTerminal: "Monumento Circle",
    destTerminal: "PITX Metro Terminal",
    stops: const [
      TransitStop(name: "Monumento Station", position: LatLng(14.6575, 120.9839), distanceKmFromOrigin: 0.0),
      TransitStop(name: "North Ave / TriNoma", position: LatLng(14.6530, 121.0325), distanceKmFromOrigin: 6.2),
      TransitStop(name: "Quezon Ave Station", position: LatLng(14.6431, 121.0392), distanceKmFromOrigin: 7.8),
      TransitStop(name: "Araneta Center-Cubao", position: LatLng(14.6195, 121.0514), distanceKmFromOrigin: 11.0),
      TransitStop(name: "Ortigas Busway", position: LatLng(14.5878, 121.0567), distanceKmFromOrigin: 15.3),
      TransitStop(name: "Ayala Center Makati", position: LatLng(14.5492, 121.0282), distanceKmFromOrigin: 20.8),
      TransitStop(name: "PITX Bay 4", position: LatLng(14.5097, 120.9912), distanceKmFromOrigin: 28.1),
    ],
    pathCoordinates: const [
      LatLng(14.6575, 120.9839),
      LatLng(14.6568, 120.9995),
      LatLng(14.6549, 121.0180),
      LatLng(14.6530, 121.0325),
      LatLng(14.6431, 121.0392),
      LatLng(14.6320, 121.0450),
      LatLng(14.6195, 121.0514),
      LatLng(14.6040, 121.0545),
      LatLng(14.5878, 121.0567),
      LatLng(14.5700, 121.0520),
      LatLng(14.5492, 121.0282),
      LatLng(14.5378, 121.0014),
      LatLng(14.5200, 120.9940),
      LatLng(14.5097, 120.9912),
    ],
  ),

  // 3. MRT-3 Express
  NationwideRoute(
    id: "NCR-MRT3-03",
    name: "MRT-3 Railway Line",
    signboard: "MRT-3 EXPRESS",
    region: PhilippineRegion.metroManila,
    category: TransitCategory.mrt3,
    originTerminal: "Trinoma / North Ave",
    destTerminal: "Taft Ave Station",
    stops: const [
      TransitStop(name: "North Avenue Station", position: LatLng(14.6523, 121.0323), distanceKmFromOrigin: 0.0),
      TransitStop(name: "GMA-Kamuning", position: LatLng(14.6352, 121.0435), distanceKmFromOrigin: 2.1),
      TransitStop(name: "Araneta Center-Cubao", position: LatLng(14.6195, 121.0514), distanceKmFromOrigin: 4.0),
      TransitStop(name: "Shaw Boulevard", position: LatLng(14.5815, 121.0538), distanceKmFromOrigin: 8.5),
      TransitStop(name: "Buendia Makati", position: LatLng(14.5540, 121.0345), distanceKmFromOrigin: 12.0),
      TransitStop(name: "Taft Ave Station", position: LatLng(14.5378, 121.0014), distanceKmFromOrigin: 16.9),
    ],
    pathCoordinates: const [
      LatLng(14.6523, 121.0323),
      LatLng(14.6438, 121.0385),
      LatLng(14.6352, 121.0435),
      LatLng(14.6195, 121.0514),
      LatLng(14.6050, 121.0550),
      LatLng(14.5880, 121.0563),
      LatLng(14.5815, 121.0538),
      LatLng(14.5680, 121.0450),
      LatLng(14.5540, 121.0345),
      LatLng(14.5490, 121.0280),
      LatLng(14.5378, 121.0014),
    ],
  ),

  // 4. Maginhawa TODA Trike
  NationwideRoute(
    id: "NCR-TRIKE-05",
    name: "Maginhawa TODA Inner Route",
    signboard: "SIKATUNA TODA",
    region: PhilippineRegion.metroManila,
    category: TransitCategory.tricycle,
    originTerminal: "Maginhawa Food Street",
    destTerminal: "Philcoa Terminal",
    stops: const [
      TransitStop(name: "Maginhawa Food Street", position: LatLng(14.6468, 121.0588), distanceKmFromOrigin: 0.0),
      TransitStop(name: "V. Luna Junction", position: LatLng(14.6492, 121.0615), distanceKmFromOrigin: 0.8),
      TransitStop(name: "Philcoa Terminal", position: LatLng(14.6536, 121.0531), distanceKmFromOrigin: 1.8),
    ],
    pathCoordinates: const [
      LatLng(14.6468, 121.0588),
      LatLng(14.6475, 121.0598),
      LatLng(14.6485, 121.0608),
      LatLng(14.6492, 121.0615),
      LatLng(14.6510, 121.0560),
      LatLng(14.6536, 121.0531),
    ],
  ),

  // 5. Cebu Modern PUV
  NationwideRoute(
    id: "CEB-MPUV-01",
    name: "Cebu IT Park - Colon Obelisk Modern PUV",
    signboard: "17B / 17D CEBU",
    region: PhilippineRegion.metroCebu,
    category: TransitCategory.modernJeep,
    originTerminal: "Cebu IT Park",
    destTerminal: "Colon Street",
    stops: const [
      TransitStop(name: "Cebu IT Park", position: LatLng(10.3298, 123.9064), distanceKmFromOrigin: 0.0),
      TransitStop(name: "Ayala Center Cebu Hub", position: LatLng(10.3175, 123.9056), distanceKmFromOrigin: 1.8),
      TransitStop(name: "Colon Street", position: LatLng(10.2975, 123.9001), distanceKmFromOrigin: 5.4),
    ],
    pathCoordinates: const [
      LatLng(10.3298, 123.9064),
      LatLng(10.3245, 123.9060),
      LatLng(10.3175, 123.9056),
      LatLng(10.3114, 123.8938),
      LatLng(10.2975, 123.9001),
    ],
  ),
];
