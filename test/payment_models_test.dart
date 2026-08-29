import 'package:flutter_test/flutter_test.dart';
import 'package:tappay/features/payments/data/payment_models.dart';

/// A payment is completed either on a hosted checkout page or by approving a prompt on
/// the payer's phone. Reading that wrong sends the payer to a blank webview (or leaves
/// them waiting for a prompt that never comes), so the parsing is pinned here.
void main() {
  Map<String, dynamic> json(Map<String, dynamic> over) => {
        'transactionId': 'txn_1',
        'reference': 'tap_1',
        'amount': 4200,
        'currency': 'GHS',
        'status': 'PENDING',
        ...over,
      };

  test('reads a redirect checkout', () {
    final r = PaymentResult.fromJson(json({
      'checkout': 'redirect',
      'authorizationUrl': 'https://checkout.paystack.com/x',
    }));
    expect(r.checkout, CheckoutKind.redirect);
    expect(r.authorizationUrl, 'https://checkout.paystack.com/x');
  });

  test('reads a push checkout and its instruction', () {
    final r = PaymentResult.fromJson(json({
      'checkout': 'push',
      'authorizationUrl': null,
      'instruction': 'Approve the prompt on your MTN phone.',
    }));
    expect(r.checkout, CheckoutKind.push);
    expect(r.authorizationUrl, isNull);
    expect(r.instruction, 'Approve the prompt on your MTN phone.');
  });

  test('falls back to the checkout URL when the backend sends no kind', () {
    // An older backend, or one deployed before this field existed.
    final redirect = PaymentResult.fromJson(json({'authorizationUrl': 'https://x'}));
    expect(redirect.checkout, CheckoutKind.redirect);

    final push = PaymentResult.fromJson(json({'authorizationUrl': null}));
    expect(push.checkout, CheckoutKind.push);
  });

  test('treats an unknown kind as a redirect rather than hanging on a prompt', () {
    final r = PaymentResult.fromJson(json({'checkout': 'something-new', 'authorizationUrl': 'https://x'}));
    expect(r.checkout, CheckoutKind.redirect);
  });
}
