import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class AnonymousUserService {
  const AnonymousUserService();

  static const String _anonymousUserIdKey = 'pixfit_anonymous_user_id';

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

  Future<void> saveAnonymousUserId(String anonymousUserId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_anonymousUserIdKey, anonymousUserId);
  }

  String _generateAnonymousUserId() {
    final random = Random.secure();
    final values = List<int>.generate(16, (_) => random.nextInt(256));
    final suffix = values
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join();
    return 'anon_$suffix';
  }
}
