import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class DeviceNotificationService {
  DeviceNotificationService._();

  static final DeviceNotificationService instance =
      DeviceNotificationService._();

  static const _channelId = 'meeting_notifications';
  static const _channelName = 'Meeting notifications';
  static const _channelDescription =
      'New meeting alerts and reminders one day before meetings';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _initialized = false;

  Future<void> initialize() async {
    final supportedPlatform =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    if (_initialized || kIsWeb || !supportedPlatform) return;

    tz.initializeTimeZones();
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } catch (_) {
      // tz.local remains usable when a platform cannot report its timezone.
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings: settings);

    if (defaultTargetPlatform == TargetPlatform.android) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    _initialized = true;
  }

  Future<void> showMeetingCreated({
    required int meetingId,
    required String title,
    required DateTime meetingDateTime,
  }) async {
    await initialize();
    if (!_initialized) return;

    await _plugin.show(
      id: _createdNotificationId(meetingId),
      title: 'New meeting created',
      body: '$title is scheduled for ${_formatDateTime(meetingDateTime)}.',
      notificationDetails: _details,
      payload: 'meeting:$meetingId',
    );
  }

  Future<void> scheduleMeetingReminder({
    required int meetingId,
    required String title,
    required DateTime meetingDateTime,
  }) async {
    await initialize();
    if (!_initialized || !meetingDateTime.isAfter(DateTime.now())) return;

    final reminderTime = meetingDateTime.subtract(const Duration(days: 1));
    if (!reminderTime.isAfter(DateTime.now())) {
      final reminderKey = 'meeting_reminder_shown_$meetingId';
      if (await _storage.read(key: reminderKey) == 'true') return;
      await _plugin.show(
        id: _reminderNotificationId(meetingId),
        title: 'Meeting within 24 hours',
        body: '$title starts at ${_formatDateTime(meetingDateTime)}.',
        notificationDetails: _details,
        payload: 'meeting:$meetingId',
      );
      await _storage.write(key: reminderKey, value: 'true');
      return;
    }

    await _plugin.zonedSchedule(
      id: _reminderNotificationId(meetingId),
      title: 'Meeting tomorrow',
      body: '$title starts at ${_formatDateTime(meetingDateTime)}.',
      scheduledDate: tz.TZDateTime.from(reminderTime, tz.local),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'meeting:$meetingId',
    );
  }

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  int _createdNotificationId(int meetingId) => (meetingId * 2) & 0x7fffffff;

  int _reminderNotificationId(int meetingId) =>
      ((meetingId * 2) + 1) & 0x7fffffff;

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour == 0
        ? 12
        : local.hour > 12
        ? local.hour - 12
        : local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} $hour:$minute $period';
  }
}
