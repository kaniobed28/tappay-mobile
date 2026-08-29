/// Models for peer-to-peer money requests.
library;

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
