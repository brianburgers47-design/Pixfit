// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_config.dart';
import 'anonymous_user_service.dart';

class EntitlementSnapshot {
  const EntitlementSnapshot({
    required this.anonymousUserId,
    required this.credits,
    required this.isPro,
    required this.plan,
    required this.subscriptionStatus,
  });

  final String anonymousUserId;
  final int credits;
  final bool isPro;
  final String plan;
  final String? subscriptionStatus;

  factory EntitlementSnapshot.fromJson(Map<String, dynamic> json) {
    return EntitlementSnapshot(
      anonymousUserId: json['anonymousUserId'] as String? ?? '',
      credits: json['credits'] as int? ?? 0,
      isPro: json['isPro'] as bool? ?? false,
      plan: json['plan'] as String? ?? 'free',
      subscriptionStatus: json['subscriptionStatus'] as String?,
    );
  }
}

class ConsumeExportResult {
  const ConsumeExportResult({
    required this.allowed,
    required this.credits,
    required this.isPro,
    required this.plan,
    required this.subscriptionStatus,
    this.reason,
  });

  final bool allowed;
  final int credits;
  final bool isPro;
  final String plan;
  final String? subscriptionStatus;
  final String? reason;

  factory ConsumeExportResult.fromJson(Map<String, dynamic> json) {
    return ConsumeExportResult(
      allowed: json['allowed'] as bool? ?? false,
      credits: json['credits'] as int? ?? 0,
      isPro: json['isPro'] as bool? ?? false,
      plan: json['plan'] as String? ?? 'free',
      subscriptionStatus: json['subscriptionStatus'] as String?,
      reason: json['reason'] as String?,
    );
  }
}

class EntitlementService extends ChangeNotifier {
  EntitlementService._();

  static final EntitlementService instance = EntitlementService._();

  final AnonymousUserService _anonymousUserService =
      const AnonymousUserService();

  String? _anonymousUserId;
  int _credits = 0;
  bool _isPro = false;
  String _plan = 'free';
  String? _subscriptionStatus;
  bool _isLoading = false;
  bool _isCheckingOut = false;
  String? _errorMessage;

  String? get anonymousUserId => _anonymousUserId;
  int get credits => _credits;
  bool get isPro => _isPro;
  String get plan => _plan;
  String? get subscriptionStatus => _subscriptionStatus;
  bool get isLoading => _isLoading;
  bool get isCheckingOut => _isCheckingOut;
  String? get errorMessage => _errorMessage;

  String get displayPlanLabel {
    switch (_plan) {
      case 'pro':
        return 'Pro';
      case 'starter':
        return 'Starter';
      case 'free':
      default:
        return 'Free';
    }
  }

  bool get isBackendReachable => _errorMessage != 'Backend not reachable';

  Future<void> bootstrap() async {
    print('ENTITLEMENT INIT START');
    _setLoading(true);

    try {
      print('BEFORE ANONYMOUS USER INIT');
      final anonymousUserId = await _anonymousUserService
          .getOrCreateAnonymousUserId();
      print('AFTER ANONYMOUS USER INIT');
      print('CALLING /api/users/bootstrap');
      final response = await http.post(
        AppConfig.apiUri('/api/users/bootstrap'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'anonymousUserId': anonymousUserId}),
      );
      print('AFTER /api/users/bootstrap');

      final snapshot = _parseSnapshot(response);
      print('BEFORE APPLY ENTITLEMENT SNAPSHOT');
      await _applySnapshot(snapshot, persistAnonymousUserId: true);
      print('AFTER APPLY ENTITLEMENT SNAPSHOT');
      _errorMessage = null;
    } catch (error) {
      _errorMessage = 'Backend not reachable';
      debugPrint('Pixfit entitlement bootstrap failed: $error');
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refresh() async {
    final anonymousUserId = await _anonymousUserService
        .getOrCreateAnonymousUserId();

    try {
      final response = await http.get(
        AppConfig.apiUri(
          '/api/me',
          queryParameters: {'anonymousUserId': anonymousUserId},
        ),
      );

      final snapshot = _parseSnapshot(response);
      await _applySnapshot(snapshot, persistAnonymousUserId: true);
      _errorMessage = null;
    } catch (error) {
      _errorMessage = 'Backend not reachable';
      debugPrint('Pixfit entitlement refresh failed: $error');
      notifyListeners();
    }
  }

  Future<void> startCheckout(String plan) async {
    if (plan != 'starter' && plan != 'pro') {
      throw ArgumentError.value(plan, 'plan', 'Use starter or pro');
    }

    _isCheckingOut = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final anonymousUserId = await _anonymousUserService
          .getOrCreateAnonymousUserId();
      final response = await http.post(
        AppConfig.apiUri('/api/checkout/session'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'anonymousUserId': anonymousUserId, 'plan': plan}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError(
          'Checkout kon niet gestart worden: ${response.statusCode}',
        );
      }

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
    } catch (error) {
      _errorMessage = 'Checkout kon niet gestart worden';
      debugPrint('Pixfit checkout failed: $error');
      notifyListeners();
      rethrow;
    } finally {
      _isCheckingOut = false;
      notifyListeners();
    }
  }

  Future<ConsumeExportResult> consumeExport() async {
    final anonymousUserId = await _anonymousUserService
        .getOrCreateAnonymousUserId();
    final response = await http.post(
      AppConfig.apiUri('/api/exports/consume'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'anonymousUserId': anonymousUserId}),
    );

    if (response.statusCode < 200 || response.statusCode >= 500) {
      throw StateError(
        'Export entitlement check failed: ${response.statusCode}',
      );
    }

    final result = ConsumeExportResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );

    _anonymousUserId = anonymousUserId;
    _credits = result.credits;
    _isPro = result.isPro;
    _plan = result.plan;
    _subscriptionStatus = result.subscriptionStatus;
    _errorMessage = null;
    notifyListeners();

    return result;
  }

  EntitlementSnapshot _parseSnapshot(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Entitlement API error: ${response.statusCode}');
    }

    return EntitlementSnapshot.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> _applySnapshot(
    EntitlementSnapshot snapshot, {
    required bool persistAnonymousUserId,
  }) async {
    _anonymousUserId = snapshot.anonymousUserId;
    _credits = snapshot.credits;
    _isPro = snapshot.isPro;
    _plan = snapshot.plan;
    _subscriptionStatus = snapshot.subscriptionStatus;

    if (persistAnonymousUserId && snapshot.anonymousUserId.isNotEmpty) {
      await _anonymousUserService.saveAnonymousUserId(snapshot.anonymousUserId);
    }

    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
