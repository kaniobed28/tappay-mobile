/// Models for merchant profiles and their takings.
library;

class MerchantModel {
  final String id;
  final String businessName;
  final String currency;

  MerchantModel({required this.id, required this.businessName, required this.currency});

  factory MerchantModel.fromJson(Map<String, dynamic> j) => MerchantModel(
        id: j['id'] as String,
        businessName: j['businessName'] as String,
        currency: (j['currency'] ?? 'GHS') as String,
      );
}
class AnalyticsModel {
  final String currency;
  final int today;
  final int week;
  final int month;
  final int count;
  final int totalVolume;
  final int avgPayment;

  AnalyticsModel({
    required this.currency,
    required this.today,
    required this.week,
    required this.month,
    required this.count,
    required this.totalVolume,
    required this.avgPayment,
  });

  factory AnalyticsModel.fromJson(Map<String, dynamic> j) => AnalyticsModel(
        currency: (j['currency'] ?? 'GHS') as String,
        today: (j['today'] as num?)?.toInt() ?? 0,
        week: (j['week'] as num?)?.toInt() ?? 0,
        month: (j['month'] as num?)?.toInt() ?? 0,
        count: (j['count'] as num?)?.toInt() ?? 0,
        totalVolume: (j['totalVolume'] as num?)?.toInt() ?? 0,
        avgPayment: (j['avgPayment'] as num?)?.toInt() ?? 0,
      );
}
