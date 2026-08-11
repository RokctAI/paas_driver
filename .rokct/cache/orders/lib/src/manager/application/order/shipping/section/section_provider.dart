import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'section_state.dart';
import 'section_notifier.dart';
import 'package:orders_sdk/src/manager/domain/interface/pos_sections_tables.dart';

final sectionProvider = StateNotifierProvider<SectionNotifier, SectionState>(
  (ref) => SectionNotifier(resolvePosSectionsTablesFacade()),
);
