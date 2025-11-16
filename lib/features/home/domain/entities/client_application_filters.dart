class ClientApplicationFilters {
  const ClientApplicationFilters({
    this.minCost,
    this.maxCost,
    this.minTerm,
    this.maxTerm,
    this.region,
    this.district,
  });

  final int? minCost;
  final int? maxCost;
  final int? minTerm;
  final int? maxTerm;
  final String? region;
  final String? district;

  bool get isEmpty =>
      minCost == null &&
      maxCost == null &&
      minTerm == null &&
      maxTerm == null &&
      (region == null || region!.isEmpty) &&
      (district == null || district!.isEmpty);

  ClientApplicationFilters copyWith({
    int? minCost,
    int? maxCost,
    int? minTerm,
    int? maxTerm,
    String? region,
    String? district,
  }) {
    return ClientApplicationFilters(
      minCost: minCost ?? this.minCost,
      maxCost: maxCost ?? this.maxCost,
      minTerm: minTerm ?? this.minTerm,
      maxTerm: maxTerm ?? this.maxTerm,
      region: region ?? this.region,
      district: district ?? this.district,
    );
  }
}
