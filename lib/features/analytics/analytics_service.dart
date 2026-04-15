class AnalyticsService {
  static void track(String event, [Map<String, dynamic>? props]) {
    try {
      // ignore: avoid_print
      print('[event] $event ${props ?? {}}');
    } catch (_) {
      // Analytics should never break the app flow.
    }
  }
}
