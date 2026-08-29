/// Models for the tap/QR session hand-off.
library;

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
