import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'delivery_zone_state.dart';
import 'delivery_zone_notifier.dart';
import '../../../domain/di/dependency_manager.dart';

final deliveryZoneProvider =
    StateNotifierProvider<DeliveryZoneNotifier, DeliveryZoneState>(
  (ref) => DeliveryZoneNotifier(userRepository),
);
