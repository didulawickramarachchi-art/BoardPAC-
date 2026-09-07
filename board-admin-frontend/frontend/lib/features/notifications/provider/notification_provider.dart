import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../../../core/notifications/device_notification_service.dart';
import '../data/notification_repository.dart';
import '../model/notification_model.dart';
import '../model/notification_request.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.read(dioProvider));
});

final notificationListProvider =
    StateNotifierProvider.family<
      NotificationNotifier,
      AsyncValue<List<NotificationModel>>,
      int
    >((ref, userId) {
      return NotificationNotifier(
        ref.read(notificationRepositoryProvider),
        userId,
      )..load();
    });

class NotificationNotifier
    extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  final NotificationRepository repository;
  final int userId;
  bool _hasLoaded = false;
  Set<int> _knownIds = <int>{};

  NotificationNotifier(this.repository, this.userId)
    : super(const AsyncLoading());

  Future<void> load() async {
    try {
      final notifications = await repository.getForUser(userId);
      if (!mounted) return;
      if (_hasLoaded) {
        for (final notification in notifications.where(
          (item) =>
              !_knownIds.contains(item.id) &&
              (item.type == 'COMMENT_CREATED' || item.type == 'COMMENT_REPLY'),
        )) {
          unawaited(
            DeviceNotificationService.instance.showBoardNotification(
              notificationId: notification.id,
              title: notification.title,
              body: notification.message,
              payload: notification.relatedPaperId == null
                  ? 'meeting:${notification.relatedMeetingId}'
                  : 'paper:${notification.relatedPaperId}',
            ),
          );
        }
      }
      _knownIds = notifications.map((item) => item.id).toSet();
      _hasLoaded = true;
      state = AsyncData(notifications);
    } catch (e) {
      if (!mounted) return;
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> createAnnouncement(NotificationRequest request) async {
    await repository.createAnnouncement(request);
    if (!mounted) return;
    await load();
  }

  Future<void> markAllRead() async {
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(
        current
            .map(
              (notification) => NotificationModel(
                id: notification.id,
                title: notification.title,
                message: notification.message,
                type: notification.type,
                read: true,
                relatedMeetingId: notification.relatedMeetingId,
                relatedPaperId: notification.relatedPaperId,
                relatedCommentId: notification.relatedCommentId,
                relatedAttachmentId: notification.relatedAttachmentId,
                createdByUserId: notification.createdByUserId,
                createdByName: notification.createdByName,
                createdByProfilePictureUrl:
                    notification.createdByProfilePictureUrl,
                replies: notification.replies,
                reactionCounts: notification.reactionCounts,
                currentReaction: notification.currentReaction,
                createdAt: notification.createdAt,
              ),
            )
            .toList(),
      );
    }

    try {
      await repository.markAllRead(userId);
    } catch (_) {
      if (!mounted) return;
      await load();
    }
  }

  Future<void> clear() async {
    await repository.clearForUser(userId);
    if (!mounted) return;
    state = const AsyncData([]);
  }

  Future<void> reply(int notificationId, String message) async {
    final updated = await repository.reply(notificationId, message);
    if (!mounted) return;
    _replace(updated);
  }

  Future<void> react(int notificationId, String reactionType) async {
    final updated = await repository.react(notificationId, reactionType);
    if (!mounted) return;
    _replace(updated);
  }

  void _replace(NotificationModel updated) {
    final current = state.valueOrNull;
    if (current == null) {
      state = AsyncData([updated]);
      return;
    }
    state = AsyncData(
      current
          .map(
            (notification) =>
                notification.id == updated.id ? updated : notification,
          )
          .toList(),
    );
  }
}
