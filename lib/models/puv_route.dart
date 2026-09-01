import 'package:latlong2/latlong.dart';

enum VehicleType { traditionalJeep, modernJeep, tricycle }

class PUVRoute {
  final String id;
  final String name;
  final String signboard;
  final VehicleType vehicleType;
  final double baseFare;
  final double baseDistanceKm;
  final double perKmRate;
  final List<LatLng> pathCoordinates;
  final String originTerminal;
  final String destTerminal;

  PUVRoute({
    required this.id,
    required this.name,
    required this.signboard,
    required this.vehicleType,
    required this.baseFare,
    required this.baseDistanceKm,
    required this.perKmRate,
    required this.pathCoordinates,
    required this.originTerminal,
    required this.destTerminal,
  });

  double computeFare(double distanceKm, {bool isDiscounted = false}) {
    double total = baseFare;
    if (distanceKm > baseDistanceKm) {
      double excessKm = distanceKm - baseDistanceKm;
      total += excessKm * perKmRate;
    }
    if (isDiscounted) {
      total = total * 0.80;
    }
    return double.parse(total.toStringAsFixed(2));
  }
}
