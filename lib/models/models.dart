/// A signed payment session — this is what travels over NFC / inside a QR code.
class SessionPayload {
  final String id;
  final String merchantId;
  final String merchantName;
  final int amount; // minor units
  final String currency;
  final String? description;
  final String nonce;
  final String channel;
  final String expiresAt;
  final String signature;

  SessionPayload({
    required this.id,
    required this.merchantId,
    required this.merchantName,
    required this.amount,
    required this.currency,
    required this.nonce,
    required this.channel,
    required this.expiresAt,
    required this.signature,
    this.description,
  });

  factory SessionPayload.fromJson(Map<String, dynamic> j) => SessionPayload(
        id: j['id'] as String,
        merchantId: j['merchantId'] as String,
        merchantName: (j['merchantName'] ?? 'Merchant') as String,
        amount: (j['amount'] as num).toInt(),
        currency: (j['currency'] ?? 'GHS') as String,
        description: j['description'] as String?,
        nonce: j['nonce'] as String,
        channel: (j['channel'] ?? 'NFC') as String,
        expiresAt: j['expiresAt'] as String,
        signature: j['signature'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'merchantId': merchantId,
        'merchantName': merchantName,
        'amount': amount,
        'currency': currency,
        'description': description,
        'nonce': nonce,
        'channel': channel,
        'expiresAt': expiresAt,
        'signature': signature,
      };
}

class PaymentResult {
  final String transactionId;
  final String reference;
  final String? authorizationUrl;
  final int amount;
  final String currency;
  final String status;

  PaymentResult({
    required this.transactionId,
    required this.reference,
    required this.authorizationUrl,
    required this.amount,
    required this.currency,
    required this.status,
  });

  factory PaymentResult.fromJson(Map<String, dynamic> j) => PaymentResult(
        transactionId: j['transactionId'] as String,
        reference: j['reference'] as String,
        authorizationUrl: j['authorizationUrl'] as String?,
        amount: (j['amount'] as num).toInt(),
        currency: (j['currency'] ?? 'GHS') as String,
        status: j['status'] as String,
      );
}

class TransactionModel {
  final String id;
  final String reference;
  final String? sessionId;
  final int amount;
  final String currency;
  final String status;
  final String? description;
  final String? payerId;
  final String payeeId;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.reference,
    required this.amount,
    required this.currency,
    required this.status,
    required this.payeeId,
    required this.createdAt,
    this.sessionId,
    this.description,
    this.payerId,
  });

  bool get isSuccess => status == 'SUCCESS';

  factory TransactionModel.fromJson(Map<String, dynamic> j) => TransactionModel(
        id: j['id'] as String,
        reference: j['reference'] as String,
        sessionId: j['sessionId'] as String?,
        amount: (j['amount'] as num).toInt(),
        currency: (j['currency'] ?? 'GHS') as String,
        status: j['status'] as String,
        description: j['description'] as String?,
        payerId: j['payerId'] as String?,
        payeeId: j['payeeId'] as String,
        createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? '') ?? DateTime.now(),
      );
}

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
