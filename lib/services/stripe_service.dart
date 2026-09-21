import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'api_client.dart';

class StripeService {
  StripeService._();
  static final StripeService instance = StripeService._();

  bool _initialized = false;

  /// Initialize Stripe with publishable key
  Future<void> initialize({String? publishableKey}) async {
    if (_initialized && publishableKey == null) return;
    try {
      String key = publishableKey ?? '';
      if (key.isEmpty) {
        // Fetch dynamically from backend
        final config = await ApiClient.instance.get('/payments/stripe/config');
        key = config['publishableKey']?.toString() ?? '';
      }

      if (key.isNotEmpty && !key.contains('placeholder')) {
        Stripe.publishableKey = key;
        Stripe.merchantIdentifier = 'merchant.com.skillpay';
        await Stripe.instance.applySettings();
        _initialized = true;
      }
    } catch (e) {
      debugPrint('Stripe initialization notice: $e');
    }
  }

  /// Process Stripe PaymentSheet for a given booking or job
  Future<bool> processPayment({
    String? bookingId,
    String? jobId,
    String? artisanId,
    double? amount,
    String customerName = 'SkillPay Customer',
  }) async {
    try {
      // 1. Create PaymentIntent on backend
      final payload = <String, dynamic>{
        if (bookingId != null && bookingId.isNotEmpty) 'bookingId': bookingId,
        if (jobId != null && jobId.isNotEmpty) 'jobId': jobId,
        if (artisanId != null && artisanId.isNotEmpty) 'artisanId': artisanId,
        if (amount != null && amount > 0) 'amount': amount,
      };

      final response = await ApiClient.instance.post(
        '/payments/stripe/create-intent',
        body: payload,
      );

      final clientSecret = response['clientSecret']?.toString();
      final publishableKey = response['publishableKey']?.toString();

      if (clientSecret == null || clientSecret.isEmpty) {
        throw Exception('Failed to obtain client secret from payment service');
      }

      // 2. Ensure Stripe SDK is configured with the key
      if (publishableKey != null && publishableKey.isNotEmpty) {
        Stripe.publishableKey = publishableKey;
        await Stripe.instance.applySettings();
      }

      // 3. Initialize Stripe Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'SkillPay',
          style: ThemeMode.light,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Color(0xFFFFC107),
            ),
          ),
        ),
      );

      // 4. Present Payment Sheet to user
      await Stripe.instance.presentPaymentSheet();
      return true;
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        debugPrint('User cancelled Stripe payment sheet');
        return false;
      }
      debugPrint('Stripe payment failed: ${e.error.localizedMessage}');
      rethrow;
    } catch (e) {
      debugPrint('Error processing payment: $e');
      rethrow;
    }
  }
}
