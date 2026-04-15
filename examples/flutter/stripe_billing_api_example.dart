// Example Flutter web client for the Pixfit Stripe backend.
//
// This file is intentionally outside lib/ so it does not affect your current
// Flutter build until you decide to wire it into PaywallScreen.
//
// Needed packages when you integrate this into lib/:
//   http: ^1.2.2
//   url_launcher: ^6.3.1

import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class PixfitBillingStatus {
  const PixfitBillingStatus({
    required this.anonymousUserId,
    required this.credits,
    required this.isPro,
    required this.subscriptionStatus,
  });

  final String anonymousUserId;
  final int credits;
  final bool isPro;
  final String? subscriptionStatus;

  factory PixfitBillingStatus.fromJson(Map<String, dynamic> json) {
    return PixfitBillingStatus(
      anonymousUserId: json['anonymousUserId'] as String,
      credits: json['credits'] as int? ?? 0,
      isPro: json['isPro'] as bool? ?? false,
      subscriptionStatus: json['subscriptionStatus'] as String?,
    );
  }
}

class PixfitBillingApi {
  PixfitBillingApi({required this.apiBaseUrl});

  final String apiBaseUrl;
  static const _anonymousUserIdKey = 'pixfit_anonymous_user_id';

  Future<String> getOrCreateAnonymousUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_anonymousUserIdKey);

    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final generated = _generateAnonymousUserId();
    await prefs.setString(_anonymousUserIdKey, generated);
    return generated;
  }

  Future<PixfitBillingStatus> bootstrap() async {
    final anonymousUserId = await getOrCreateAnonymousUserId();
    final response = await http.post(
      Uri.parse('$apiBaseUrl/api/users/bootstrap'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'anonymousUserId': anonymousUserId}),
    );

    _throwIfBadResponse(response);

    final status = PixfitBillingStatus.fromJson(jsonDecode(response.body));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_anonymousUserIdKey, status.anonymousUserId);
    return status;
  }

  Future<PixfitBillingStatus> fetchStatus() async {
    final anonymousUserId = await getOrCreateAnonymousUserId();
    final response = await http.get(
      Uri.parse('$apiBaseUrl/api/me?anonymousUserId=$anonymousUserId'),
    );

    _throwIfBadResponse(response);
    return PixfitBillingStatus.fromJson(jsonDecode(response.body));
  }

  Future<void> startCheckout({required String plan}) async {
    final anonymousUserId = await getOrCreateAnonymousUserId();
    final response = await http.post(
      Uri.parse('$apiBaseUrl/api/checkout/session'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'anonymousUserId': anonymousUserId,
        'plan': plan, // starter or pro
      }),
    );

    _throwIfBadResponse(response);

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final checkoutUrl = data['checkoutUrl'] as String?;

    if (checkoutUrl == null || checkoutUrl.isEmpty) {
      throw StateError('Checkout URL ontbreekt');
    }

    final opened = await launchUrl(
      Uri.parse(checkoutUrl),
      webOnlyWindowName: '_self',
    );

    if (!opened) {
      throw StateError('Checkout kon niet geopend worden');
    }
  }

  String _generateAnonymousUserId() {
    final random = Random.secure();
    final values = List<int>.generate(16, (_) => random.nextInt(256));
    final suffix = values
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join();
    return 'anon_$suffix';
  }

  void _throwIfBadResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw StateError(
      'Pixfit billing API error: ${response.statusCode} ${response.body}',
    );
  }
}
