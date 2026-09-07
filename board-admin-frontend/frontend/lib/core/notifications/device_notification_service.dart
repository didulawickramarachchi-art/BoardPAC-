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
  static const _reminderOffsetsKey = 'meeting_reminder_offsets_minutes';

  Future<List<int>> reminderOffsets() async {
    final stored = await _storage.read(key: _reminderOffsetsKey);
    if (stored == null || stored.trim().isEmpty) return const [1440, 60];
    return stored
        .split(',')
        .map(int.tryParse)
        .whereType<int>()
        .where((v) => v > 0)
        .toList();
  }

  Future<void> setReminderOffsets(List<int> minutes) async {
    final values = minutes.toSet().where((v) => v > 0).toList()
      ..sort((a, b) => b.compareTo(a));
    await _storage.write(key: _reminderOffsetsKey, value: values.join(','));
  }

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

  Future<void> showBoardNotification({
    required int notificationId,
    required String title,
    required String body,
    String? payload,
  }) async {
    await initialize();
    if (!_initialized) return;
    await _plugin.show(
      id: (1000000 + notificationId) & 0x7fffffff,
      title: title,
      body: body,
      notificationDetails: _boardNotificationDetails,
      payload: payload,
    );
  }

  Future<void> scheduleMeetingReminder({
    required int meetingId,
    required String title,
    required DateTime meetingDateTime,
  }) async {
    await initialize();
    if (!_initialized || !meetingDateTime.isAfter(DateTime.now())) return;

    for (var index = 0; index < 5; index++) {
      await _plugin.cancel(id: _reminderNotificationId(meetingId, index));
    }

    final offsets = await reminderOffsets();
    for (var index = 0; index < offsets.length; index++) {
      final minutes = offsets[index];
      final reminderTime = meetingDateTime.subtract(Duration(minutes: minutes));
      if (!reminderTime.isAfter(DateTime.now())) continue;
      await _plugin.zonedSchedule(
        id: _reminderNotificationId(meetingId, index),
        title: _reminderTitle(minutes),
        body: '$title starts at ${_formatDateTime(meetingDateTime)}.',
        scheduledDate: tz.TZDateTime.from(reminderTime, tz.local),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'meeting:$meetingId',
      );
    }
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

  static const NotificationDetails _boardNotificationDetails =
      NotificationDetails(
        android: AndroidNotificationDetails(
          'boardpac_activity_notifications',
          'BoardPAC activity',
          channelDescription:
              'Comments, replies, approvals and BoardPAC activity',
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

  int _reminderNotificationId(int meetingId, int index) =>
      ((meetingId * 10) + index + 1) & 0x7fffffff;

  String _reminderTitle(int minutes) => minutes >= 1440
      ? 'Meeting in ${minutes ~/ 1440} day${minutes ~/ 1440 == 1 ? '' : 's'}'
      : minutes >= 60
      ? 'Meeting in ${minutes ~/ 60} hour${minutes ~/ 60 == 1 ? '' : 's'}'
      : 'Meeting in $minutes minutes';

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
