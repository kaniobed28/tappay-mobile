import 'package:flutter/material.dart';
import 'package:tappay/core/network/api_error.dart';
import 'package:tappay/features/payments/data/payment_models.dart';
import 'package:tappay/features/payments/data/payments_api.dart';
import 'package:tappay/features/payments/presentation/awaiting_approval_screen.dart';
import 'package:tappay/features/payments/presentation/checkout_screen.dart';
import 'package:tappay/features/users/presentation/mobile_number_sheet.dart';

/// Starts a payment, recovering from the one failure the payer can fix themselves.
///
/// Mobile-money providers charge a phone number, which a Google-signed-in payer may not
/// have on file. Rather than failing with advice, we ask for the number and try again.
/// Returns null if the payer declined to add one.
Future<PaymentResult?> startPayment(
  BuildContext context,
  Future<PaymentResult> Function() start,
) async {
  try {
    return await start();
  } catch (e) {
    if (apiErrorCode(e) != payerPhoneRequired || !context.mounted) rethrow;
    if (!await askForMobileNumber(context)) return null;
    return start();
  }
}

/// Runs a started payment to its conclusion, whichever way the provider completes it:
/// a hosted checkout page (card/bank) or an approval prompt on the payer's own phone
/// (mobile money). Both entry points — tap/scan and paying a request — go through here,
/// so a new provider changes this one function and nothing else in the UI.
///
/// Returns the settled transaction, or null if the payer abandoned the payment.
/// Throws [CheckoutUnavailable] when the provider gave us nothing to continue with.
Future<TransactionModel?> runCheckout(
  NavigatorState navigator,
  PaymentsApi payments,
  PaymentResult payment,
) async {
  switch (payment.checkout) {
    case CheckoutKind.push:
      // Nothing to open: the prompt is already on the payer's handset. The waiting
      // screen polls until the payment settles and hands back the finished transaction.
      return navigator.push<TransactionModel>(
        MaterialPageRoute(builder: (_) => AwaitingApprovalScreen(payment: payment)),
      );

    case CheckoutKind.redirect:
      final url = payment.authorizationUrl;
      if (url == null) throw const CheckoutUnavailable();
      await navigator.push(MaterialPageRoute(builder: (_) => CheckoutScreen(url: url)));
      // The webview closes on the callback deep link; the server is the authority on
      // what actually happened, so read the transaction back rather than trusting it.
      return payments.getTransaction(payment.transactionId);
  }
}

/// The provider started a redirect checkout but returned no URL to send the payer to.
class CheckoutUnavailable implements Exception {
  const CheckoutUnavailable();

  @override
  String toString() => 'Provider did not return a checkout URL';
}
