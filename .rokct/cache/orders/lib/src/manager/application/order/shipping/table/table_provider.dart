import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'table_state.dart';
import 'table_notifier.dart';
import 'package:orders_sdk/src/manager/domain/interface/pos_sections_tables.dart';

final tableProvider = StateNotifierProvider<TableNotifier, TableState>(
  (ref) => TableNotifier(resolvePosSectionsTablesFacade()),
);
