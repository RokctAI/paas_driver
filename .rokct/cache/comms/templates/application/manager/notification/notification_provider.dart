// Ported from paas_manager lib/application/notification/notification_provider.dart
// (comms_sdk manager consume, fork plan S-3 / migration bucket b).
// Resolution via base_sdk's injection getters: NotificationRepositoryFacade
// is registered by CommsSdkDependencies.register in the generated
// main.dart sdk-di block.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:base_sdk/src/di/injection.dart';

import 'notification_notifier.dart';
import 'notification_state.dart';

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>(
  (ref) => NotificationNotifier(notificationRepo),
);
