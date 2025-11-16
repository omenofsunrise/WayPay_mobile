class MainClientStatsModel {
  final int? clientsCount;
  final int? queuesCount;
  final int? creditApplicationsCount;
  final int? creditsCount;
  final int? blacklistCount;
  final int? blackCatalogCount;

  const MainClientStatsModel({
    this.clientsCount,
    this.queuesCount,
    this.creditApplicationsCount,
    this.creditsCount,
    this.blacklistCount,
    this.blackCatalogCount,
  });

  factory MainClientStatsModel.fromJson(Map<String, dynamic> json) {
    return MainClientStatsModel(
      clientsCount: (json['getClientsCount'] as num?)?.toInt(),
      queuesCount: (json['getQueuesCount'] as num?)?.toInt(),
      creditApplicationsCount:
          (json['getCreditApplicationsCount'] as num?)?.toInt(),
      creditsCount: (json['getCreditsCount'] as num?)?.toInt(),
      blacklistCount: (json['getBlacklistCount'] as num?)?.toInt(),
      blackCatalogCount: (json['getBlackCatalogCount'] as num?)?.toInt(),
    );
  }
}
