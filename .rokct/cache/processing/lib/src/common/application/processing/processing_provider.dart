import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import '../../domain/interface/processing_repository_facade.dart';
import 'processing_notifier.dart';
import 'processing_state.dart';

final processingProvider =
    StateNotifierProvider<ProcessingNotifier, ProcessingSdkState>(
  (ref) => ProcessingNotifier(GetIt.I.get<ProcessingRepositoryFacade>()),
);
