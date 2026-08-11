// Ported from paas_manager lib/application/notification/notification_state.dart
// (comms_sdk manager consume, fork plan S-3 / migration bucket b), models
// swapped for their base_sdk twins (NotificationModel lives in base's
// notification_response.dart; CountNotificationModel in
// count_of_notifications_data.dart).
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:base_sdk/src/models/data/count_of_notifications_data.dart';
import 'package:base_sdk/src/models/response/notification_response.dart';

part 'notification_state.freezed.dart';

@freezed
class NotificationState with _$NotificationState {
  const factory NotificationState({
    @Default([]) List<NotificationModel> notifications,
    @Default(null) CountNotificationModel? countOfNotifications,
    @Default(false) bool isReadAllLoading,
    @Default(false) bool isAllNotificationsLoading,
  }) = _NotificationState;

  const NotificationState._();
}
