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

/// The counterparty on a money request (requester or payer), trimmed to display fields.
class RequestParty {
  final String id;
  final String? displayName;
  final String? email;
  final String? phone;

  RequestParty({required this.id, this.displayName, this.email, this.phone});

  /// A human-friendly label, preferring name, then email, then phone.
  String get label => (displayName?.trim().isNotEmpty ?? false)
      ? displayName!.trim()
      : (email ?? phone ?? 'TapPay user');

  factory RequestParty.fromJson(Map<String, dynamic> j) => RequestParty(
        id: j['id'] as String,
        displayName: j['displayName'] as String?,
        email: j['email'] as String?,
        phone: j['phone'] as String?,
      );
}

/// A targeted "please pay me" request. The requester is the payee; the payer is asked to pay.
class PaymentRequestModel {
  final String id;
  final int amount; // minor units
  final String currency;
  final String? note;
  final String status; // PENDING | PAID | CANCELLED | DECLINED
  final String? transactionId;
  final String requesterId;
  final String payerId;
  final RequestParty? requester;
  final RequestParty? payer;
  final DateTime createdAt;

  PaymentRequestModel({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.requesterId,
    required this.payerId,
    required this.createdAt,
    this.note,
    this.transactionId,
    this.requester,
    this.payer,
  });

  bool get isPending => status == 'PENDING';

  factory PaymentRequestModel.fromJson(Map<String, dynamic> j) => PaymentRequestModel(
        id: j['id'] as String,
        amount: (j['amount'] as num).toInt(),
        currency: (j['currency'] ?? 'GHS') as String,
        note: j['note'] as String?,
        status: (j['status'] ?? 'PENDING') as String,
        transactionId: j['transactionId'] as String?,
        requesterId: j['requesterId'] as String,
        payerId: j['payerId'] as String,
        requester: j['requester'] is Map
            ? RequestParty.fromJson(Map<String, dynamic>.from(j['requester'] as Map))
            : null,
        payer: j['payer'] is Map
            ? RequestParty.fromJson(Map<String, dynamic>.from(j['payer'] as Map))
            : null,
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

class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String body;
  final bool read;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> j) => NotificationModel(
        id: j['id'] as String,
        type: (j['type'] ?? '') as String,
        title: (j['title'] ?? '') as String,
        body: (j['body'] ?? '') as String,
        read: (j['read'] ?? false) as bool,
        createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? '') ?? DateTime.now(),
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
