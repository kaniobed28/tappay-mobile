/// Models for payments and settled transactions.
library;

/// How the payer completes this payment.
///
/// `redirect` — finish on the provider's hosted checkout page (card/bank, e.g. Paystack).
/// `push`     — the provider sent an approval prompt to their phone (mobile money, e.g.
///              MTN MoMo); there is nothing to open, so the app waits and polls.
enum CheckoutKind {
  redirect,
  push;

  static CheckoutKind parse(Object? value) =>
      value == 'push' ? CheckoutKind.push : CheckoutKind.redirect;
}

class PaymentResult {
  final String transactionId;
  final String reference;
  final CheckoutKind checkout;
  final String? authorizationUrl;

  /// What to tell the payer while a `push` payment awaits approval.
  final String? instruction;
  final int amount;
  final String currency;
  final String status;

  PaymentResult({
    required this.transactionId,
    required this.reference,
    required this.checkout,
    required this.authorizationUrl,
    required this.amount,
    required this.currency,
    required this.status,
    this.instruction,
  });

  factory PaymentResult.fromJson(Map<String, dynamic> j) => PaymentResult(
        transactionId: j['transactionId'] as String,
        reference: j['reference'] as String,
        // Older backends answer without a `checkout` field; a checkout URL means redirect.
        checkout: j.containsKey('checkout')
            ? CheckoutKind.parse(j['checkout'])
            : (j['authorizationUrl'] == null ? CheckoutKind.push : CheckoutKind.redirect),
        authorizationUrl: j['authorizationUrl'] as String?,
        instruction: j['instruction'] as String?,
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
