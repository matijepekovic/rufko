// Local notification functionality is stubbed out because the
// flutter_local_notifications and timezone packages are not
// included in this environment. The methods remain so the rest
// of the application can call them without errors.

class NotificationService {
  static Future<void> init() async {
    // No-op stub
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    // No-op stub
  }

  static Future<void> cancel(int id) async {
    // No-op stub
  }
}
