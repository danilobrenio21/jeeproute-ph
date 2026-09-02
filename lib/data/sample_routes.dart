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

final List<NationwideRoute> sampleNationwideRoutes = [
  // 1. Philcoa - UP Diliman Campus Loop (True road alignment along Commonwealth, University Ave, Academic Oval)
  NationwideRoute(
    id: "NCR-JEEP-01",
    name: "Philcoa - UP Diliman Campus",
    signboard: "UP CAMPUS - IKOT",
    region: PhilippineRegion.metroManila,
    category: TransitCategory.traditionalJeep,
    originTerminal: "Philcoa Jeep Terminal",
    destTerminal: "UP Diliman Vinzons Hall",
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

  // 2. EDSA Busway Carousel (Following the actual EDSA arterial corridor without cutting through buildings)
  NationwideRoute(
    id: "NCR-CAROUSEL-02",
    name: "EDSA Busway Carousel",
    signboard: "EDSA CAROUSEL",
    region: PhilippineRegion.metroManila,
    category: TransitCategory.edsaCarousel,
    originTerminal: "Monumento Concourse",
    destTerminal: "PITX Metro Terminal",
    stops: const [
      TransitStop(name: "Monumento Station", position: LatLng(14.6575, 120.9839), distanceKmFromOrigin: 0.0),
      TransitStop(name: "North Ave / TriNoma", position: LatLng(14.6530, 121.0325), distanceKmFromOrigin: 6.2),
      TransitStop(name: "Quezon Ave Station", position: LatLng(14.6431, 121.0392), distanceKmFromOrigin: 7.8),
      TransitStop(name: "Cubao Main Ave", position: LatLng(14.6195, 121.0514), distanceKmFromOrigin: 11.0),
      TransitStop(name: "Ortigas Busway", position: LatLng(14.5878, 121.0567), distanceKmFromOrigin: 15.3),
      TransitStop(name: "Ayala MRT Concourse", position: LatLng(14.5492, 121.0282), distanceKmFromOrigin: 20.8),
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

  // 3. MRT-3 Real Track Alignment (North Ave to Taft Ave)
  NationwideRoute(
    id: "NCR-MRT3-03",
    name: "MRT-3 Railway Line",
    signboard: "MRT-3 EXPRESS",
    region: PhilippineRegion.metroManila,
    category: TransitCategory.mrt3,
    originTerminal: "North Avenue Station",
    destTerminal: "Taft Avenue Station",
    stops: const [
      TransitStop(name: "North Avenue Station", position: LatLng(14.6523, 121.0323), distanceKmFromOrigin: 0.0),
      TransitStop(name: "GMA-Kamuning", position: LatLng(14.6352, 121.0435), distanceKmFromOrigin: 2.1),
      TransitStop(name: "Araneta-Cubao", position: LatLng(14.6195, 121.0514), distanceKmFromOrigin: 4.0),
      TransitStop(name: "Shaw Boulevard", position: LatLng(14.5815, 121.0538), distanceKmFromOrigin: 8.5),
      TransitStop(name: "Buendia Makati", position: LatLng(14.5540, 121.0345), distanceKmFromOrigin: 12.0),
      TransitStop(name: "Taft Avenue Terminal", position: LatLng(14.5378, 121.0014), distanceKmFromOrigin: 16.9),
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

  // 4. Maginhawa TODA (Realistic Street Curves via Maginhawa and V. Luna)
  NationwideRoute(
    id: "NCR-TRIKE-05",
    name: "Maginhawa TODA Inner Route",
    signboard: "SIKATUNA TODA",
    region: PhilippineRegion.metroManila,
    category: TransitCategory.tricycle,
    originTerminal: "V. Luna Ext. Terminal",
    destTerminal: "CP Garcia / Krus Na Ligas",
    stops: const [
      TransitStop(name: "V. Luna Ext TODA Terminal", position: LatLng(14.6468, 121.0588), distanceKmFromOrigin: 0.0),
      TransitStop(name: "Maginhawa Food Strip Middle", position: LatLng(14.6492, 121.0615), distanceKmFromOrigin: 0.8),
      TransitStop(name: "CP Garcia Junction Drop", position: LatLng(14.6515, 121.0652), distanceKmFromOrigin: 1.6),
    ],
    pathCoordinates: const [
      LatLng(14.6468, 121.0588),
      LatLng(14.6475, 121.0598),
      LatLng(14.6485, 121.0608),
      LatLng(14.6492, 121.0615),
      LatLng(14.6502, 121.0630),
      LatLng(14.6515, 121.0652),
    ],
  ),

  // 5. Metro Cebu Modern PUV Route (Cebu IT Park to Colon Obelisk via Osmeña Blvd)
  NationwideRoute(
    id: "CEB-MPUV-01",
    name: "Cebu IT Park - Colon Obelisk Modern PUV",
    signboard: "17B / 17D CEBU",
    region: PhilippineRegion.metroCebu,
    category: TransitCategory.modernJeep,
    originTerminal: "Cebu IT Park Transport Hub",
    destTerminal: "Colon Street Downtown Terminal",
    stops: const [
      TransitStop(name: "Cebu IT Park Hub", position: LatLng(10.3298, 123.9064), distanceKmFromOrigin: 0.0),
      TransitStop(name: "Ayala Center Cebu Hub", position: LatLng(10.3175, 123.9056), distanceKmFromOrigin: 1.8),
      TransitStop(name: "Fuente Osmeña Circle", position: LatLng(10.3114, 123.8938), distanceKmFromOrigin: 3.5),
      TransitStop(name: "Colon Obelisk Terminal", position: LatLng(10.2975, 123.9001), distanceKmFromOrigin: 5.4),
    ],
    pathCoordinates: const [
      LatLng(10.3298, 123.9064),
      LatLng(10.3245, 123.9060),
      LatLng(10.3175, 123.9056),
      LatLng(10.3140, 123.9010),
      LatLng(10.3114, 123.8938),
      LatLng(10.3040, 123.8960),
      LatLng(10.2975, 123.9001),
    ],
  ),
];
