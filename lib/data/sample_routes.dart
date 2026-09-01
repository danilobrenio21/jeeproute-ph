import 'package:latlong2/latlong.dart';
import '../models/puv_route.dart';

final List<PUVRoute> sampleRoutes = [
  PUVRoute(
    id: "QC-JEEP-01",
    name: "Philcoa - UP Diliman Campus",
    signboard: "UP CAMPUS - IKOT",
    vehicleType: VehicleType.traditionalJeep,
    baseFare: 13.00,
    baseDistanceKm: 4.0,
    perKmRate: 1.80,
    originTerminal: "Philcoa Jeepney Terminal",
    destTerminal: "UP Diliman Vinzons Hall",
    pathCoordinates: const [
      LatLng(14.6542, 121.0531),
      LatLng(14.6560, 121.0590),
      LatLng(14.6538, 121.0684),
      LatLng(14.6585, 121.0722),
    ],
  ),
  PUVRoute(
    id: "QC-MPUV-02",
    name: "Cubao - SM North EDSA via East Ave",
    signboard: "CUBAO - SM NORTH",
    vehicleType: VehicleType.modernJeep,
    baseFare: 15.00,
    baseDistanceKm: 4.0,
    perKmRate: 2.20,
    originTerminal: "Araneta City Transport Hub",
    destTerminal: "SM North EDSA PUV Terminal",
    pathCoordinates: const [
      LatLng(14.6195, 121.0514),
      LatLng(14.6367, 121.0450),
      LatLng(14.6499, 121.0370),
      LatLng(14.6560, 121.0280),
    ],
  ),
  PUVRoute(
    id: "QC-TRIKE-03",
    name: "Maginhawa Street Inner Loop",
    signboard: "SIKATUNA TODA",
    vehicleType: VehicleType.tricycle,
    baseFare: 20.00,
    baseDistanceKm: 1.5,
    perKmRate: 5.00,
    originTerminal: "V. Luna Extension",
    destTerminal: "CP Garcia Junction",
    pathCoordinates: const [
      LatLng(14.6468, 121.0588),
      LatLng(14.6482, 121.0605),
      LatLng(14.6501, 121.0632),
    ],
  ),
];
