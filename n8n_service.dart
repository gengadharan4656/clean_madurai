import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

/// N8N Service handles:
/// 1. Automatic garbage collector message triggers
/// 2. Daily morning scheduled messages to all collectors
/// 3. Complaint notifications to relevant collectors
/// 4. Ward-level status updates
class N8nService {
  // Replace with your actual n8n webhook URLs
  static const String _baseWebhookUrl =
      'https://your-n8n-instance.app.n8n.cloud/webhook';

  static const String _morningAlertWebhook = '$_baseWebhookUrl/morning-alert';
  static const String _complaintWebhook = '$_baseWebhookUrl/complaint-trigger';
  static const String _collectorTriggerWebhook =
      '$_baseWebhookUrl/collector-trigger';
  static const String _wardStatusWebhook = '$_baseWebhookUrl/ward-status';
  static const String _pickupConfirmWebhook =
      '$_baseWebhookUrl/pickup-confirm';

  // Public task name constants so _callbackDispatcher (top-level) can access them
  static const String taskDailyMorning = 'dailyMorningMessage';
  static const String taskGarbageAlert = 'garbageAlert';

  // ─────────────────────────────────────────────────────────────
  // 1. SCHEDULE DAILY MORNING MESSAGES (runs every day at 6 AM)
  // ─────────────────────────────────────────────────────────────
  static Future<void> scheduleDailyMorningMessages() async {
    await Workmanager().initialize(
      _callbackDispatcher,
      isInDebugMode: false,
    );

    // Register periodic task for 6 AM daily message
    await Workmanager().registerPeriodicTask(
      taskDailyMorning,
      taskDailyMorning,
      frequency: const Duration(hours: 24),
      initialDelay: _calculateDelayTo6AM(),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      inputData: {
        'time': '06:00',
        'type': 'morning_alert',
      },
    );
  }

  static Duration _calculateDelayTo6AM() {
    final now = DateTime.now();
    var targetTime = DateTime(now.year, now.month, now.day, 6, 0, 0);
    if (targetTime.isBefore(now)) {
      targetTime = targetTime.add(const Duration(days: 1));
    }
    return targetTime.difference(now);
  }

  // ─────────────────────────────────────────────────────────────
  // 2. TRIGGER MORNING MESSAGE TO ALL COLLECTORS
  // ─────────────────────────────────────────────────────────────
  static Future<bool> sendMorningAlert({
    required String ward,
    required List<Map<String, dynamic>> collectors,
    required Map<String, dynamic> routeData,
  }) async {
    try {
      final payload = {
        'type': 'morning_alert',
        'timestamp': DateTime.now().toIso8601String(),
        'ward': ward,
        'date': DateFormat('dd MMM yyyy').format(DateTime.now()),
        'day': DateFormat('EEEE').format(DateTime.now()),
        'collectors': collectors,
        'route_data': routeData,
        'message_template':
            '🌅 Good Morning! Today\'s waste collection route is ready. Ward: $ward. Please start your route by 7:00 AM. Have a clean day!',
        'channels': ['whatsapp', 'sms'],
      };

      final response = await http
          .post(
            Uri.parse(_morningAlertWebhook),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer \${_getN8nApiKey()}',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));

      return response.statusCode == 200;
    } catch (e) {
      print('N8N morning alert error: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 3. TRIGGER GARBAGE COLLECTOR ON COMPLAINT
  // ─────────────────────────────────────────────────────────────
  static Future<bool> triggerGarbageCollector({
    required String complaintId,
    required String location,
    required String ward,
    required double latitude,
    required double longitude,
    required String imageUrl,
    required String severity, // 'low', 'medium', 'high', 'critical'
    required String reportedBy,
    String? collectorPhone,
    String? collectorName,
  }) async {
    try {
      final payload = {
        'type': 'complaint_trigger',
        'complaint_id': complaintId,
        'timestamp': DateTime.now().toIso8601String(),
        'location': location,
        'ward': ward,
        'coordinates': {'lat': latitude, 'lng': longitude},
        'image_url': imageUrl,
        'severity': severity,
        'reported_by': reportedBy,
        'collector': {
          'name': collectorName ?? 'Ward $ward Collector',
          'phone': collectorPhone ?? '',
        },
        'message':
            '🚨 Garbage Alert! New complaint reported at $location, Ward $ward. Severity: ${severity.toUpperCase()}. Please attend immediately. Complaint ID: $complaintId',
        'whatsapp_message':
            '*🗑️ GARBAGE ALERT - Ward $ward*\n\n📍 Location: $location\n⚠️ Severity: ${severity.toUpperCase()}\n📸 Image attached\n🕐 Reported: ${DateFormat('hh:mm a, dd MMM').format(DateTime.now())}\n\nPlease attend and mark as resolved.',
        'channels': ['whatsapp', 'sms', 'push'],
        'priority': severity == 'critical' ? 'urgent' : 'normal',
      };

      final response = await http
          .post(
            Uri.parse(_complaintWebhook),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        await _logN8nTrigger('complaint', complaintId);
        return true;
      }
      return false;
    } catch (e) {
      print('N8N complaint trigger error: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 4. SEND PICKUP COMPLETION NOTIFICATION
  // ─────────────────────────────────────────────────────────────
  static Future<bool> notifyPickupComplete({
    required String collectorId,
    required String ward,
    required String beforeImageUrl,
    required String afterImageUrl,
    required int pointsAwarded,
    required String residentPhone,
  }) async {
    try {
      final payload = {
        'type': 'pickup_complete',
        'collector_id': collectorId,
        'ward': ward,
        'timestamp': DateTime.now().toIso8601String(),
        'before_image': beforeImageUrl,
        'after_image': afterImageUrl,
        'points_awarded': pointsAwarded,
        'resident_phone': residentPhone,
        'message':
            '✅ Garbage collected! Ward $ward pickup complete. $pointsAwarded civic points awarded. Thank you for helping keep Madurai clean! 🌿',
      };

      final response = await http
          .post(
            Uri.parse(_pickupConfirmWebhook),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));

      return response.statusCode == 200;
    } catch (e) {
      print('N8N pickup complete error: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 5. SEND WARD STATUS UPDATE
  // ─────────────────────────────────────────────────────────────
  static Future<bool> sendWardStatusUpdate({
    required String ward,
    required int cleanScore,
    required int complaintsOpen,
    required int complaintsResolved,
  }) async {
    try {
      final payload = {
        'type': 'ward_status',
        'ward': ward,
        'timestamp': DateTime.now().toIso8601String(),
        'clean_score': cleanScore,
        'complaints_open': complaintsOpen,
        'complaints_resolved': complaintsResolved,
        'status': cleanScore >= 80
            ? 'excellent'
            : cleanScore >= 60
                ? 'good'
                : cleanScore >= 40
                    ? 'average'
                    : 'poor',
      };

      final response = await http
          .post(
            Uri.parse(_wardStatusWebhook),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));

      return response.statusCode == 200;
    } catch (e) {
      print('N8N ward status error: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────
  static Future<void> _logN8nTrigger(String type, String id) async {
    final prefs = await SharedPreferences.getInstance();
    final logs = prefs.getStringList('n8n_logs') ?? [];
    logs.add(
        jsonEncode({'type': type, 'id': id, 'ts': DateTime.now().toIso8601String()}));
    if (logs.length > 100) logs.removeAt(0);
    await prefs.setStringList('n8n_logs', logs);
  }

  static String _getN8nApiKey() {
    // Load from secure storage in production
    return 'YOUR_N8N_API_KEY';
  }

  // Test webhook connection
  static Future<bool> testWebhookConnection() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseWebhookUrl/health'))
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

// ─────────────────────────────────────────────────────────────
// WORKMANAGER BACKGROUND CALLBACK
// ─────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
void _callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case N8nService.taskDailyMorning:
        // Fetch today's collectors from Firestore and send morning messages
        await N8nService.sendMorningAlert(
          ward: inputData?['ward'] ?? 'All Wards',
          collectors: [],
          routeData: {},
        );
        break;

      case N8nService.taskGarbageAlert:
        // Handle alert task
        break;
    }
    return Future.value(true);
  });
}
