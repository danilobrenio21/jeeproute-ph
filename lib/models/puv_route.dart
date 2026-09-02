enum TransitCategory {
  traditionalJeep,
  modernJeep,
  ordinaryBus,
  airconBus,
  edsaCarousel,
  tricycle,
  mrt3,
  lrt1,
  lrt2,
  pnr,
}

class NationwideTransitRule {
  final TransitCategory category;
  final String label;
  final double baseFare;
  final double baseDistanceKm;
  final double perKmRate;
  final double? maxCapFare;

  const NationwideTransitRule({
    required this.category,
    required this.label,
    required this.baseFare,
    required this.baseDistanceKm,
    required this.perKmRate,
    this.maxCapFare,
  });

  double calculateFare(double distanceKm, {bool isDiscounted = false}) {
    double total = baseFare;
    if (distanceKm > baseDistanceKm) {
      total += (distanceKm - baseDistanceKm) * perKmRate;
    }
    if (maxCapFare != null && total > maxCapFare!) {
      total = maxCapFare!;
    }
    if (isDiscounted) {
      total *= 0.80; // Statutory 20% discount for Students, PWDs, Seniors
    }
    return double.parse(total.toStringAsFixed(2));
  }
}

// Master Tariff Table
final Map<TransitCategory, NationwideTransitRule> nationwideFares = {
  TransitCategory.traditionalJeep: const NationwideTransitRule(
    category: TransitCategory.traditionalJeep,
    label: "Traditional PUJ",
    baseFare: 13.00,
    baseDistanceKm: 4.0,
    perKmRate: 1.80,
  ),
  TransitCategory.modernJeep: const NationwideTransitRule(
    category: TransitCategory.modernJeep,
    label: "Modern PUJ (MPUV)",
    baseFare: 15.00,
    baseDistanceKm: 4.0,
    perKmRate: 2.20,
  ),
  TransitCategory.ordinaryBus: const NationwideTransitRule(
    category: TransitCategory.ordinaryBus,
    label: "Ordinary City Bus",
    baseFare: 15.00,
    baseDistanceKm: 5.0,
    perKmRate: 2.65,
  ),
  TransitCategory.airconBus: const NationwideTransitRule(
    category: TransitCategory.airconBus,
    label: "Aircon City Bus",
    baseFare: 17.00,
    baseDistanceKm: 5.0,
    perKmRate: 3.10,
  ),
  TransitCategory.edsaCarousel: const NationwideTransitRule(
    category: TransitCategory.edsaCarousel,
    label: "EDSA Bus Carousel",
    baseFare: 15.00,
    baseDistanceKm: 5.0,
    perKmRate: 2.65,
    maxCapFare: 75.50,
  ),
  TransitCategory.tricycle: const NationwideTransitRule(
    category: TransitCategory.tricycle,
    label: "Tricycle (Standard LGU)",
    baseFare: 15.00,
    baseDistanceKm: 1.0,
    perKmRate: 3.00,
  ),
  TransitCategory.mrt3: const NationwideTransitRule(
    category: TransitCategory.mrt3,
    label: "MRT-3",
    baseFare: 13.00,
    baseDistanceKm: 2.0,
    perKmRate: 1.00,
    maxCapFare: 28.00,
  ),
  TransitCategory.lrt1: const NationwideTransitRule(
    category: TransitCategory.lrt1,
    label: "LRT-1",
    baseFare: 15.00,
    baseDistanceKm: 2.0,
    perKmRate: 1.21,
    maxCapFare: 45.00,
  ),
  TransitCategory.lrt2: const NationwideTransitRule(
    category: TransitCategory.lrt2,
    label: "LRT-2",
    baseFare: 15.00,
    baseDistanceKm: 2.0,
    perKmRate: 1.21,
    maxCapFare: 35.00,
  ),
  TransitCategory.pnr: const NationwideTransitRule(
    category: TransitCategory.pnr,
    label: "PNR Commuter",
    baseFare: 15.00,
    baseDistanceKm: 4.0,
    perKmRate: 1.10,
  ),
};
