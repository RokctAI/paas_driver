// Aligned with base_sdk's templates/app_widget.dart (migration stage M3):
// the settings/translations warmup now rides base_sdk's SettingsRepository
// facade and app provider instead of the deleted host providers and
// repositories (the host auth vertical they served died with the auth
// flip). Kept host-owned (tracked) until the final untrack commit (M4); the
// body must stay in sync with the template so a fresh compose produces the
// identical widget.
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/application/app_widget/app_provider.dart';
import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/domain/interface/settings.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:driver/presentation/routes/app_router.dart';

class AppWidget extends ConsumerWidget {
  const AppWidget({super.key});

  static final _appRouter = AppRouter();

  Future<void> _fetchSettings() async {
    // Settings live behind comms_sdk's registration; apps composed without
    // it simply skip the remote settings fetch.
    if (!getIt.isRegistered<SettingsRepositoryFacade>()) return;
    final connect = await Connectivity().checkConnectivity();
    if (connect.contains(ConnectivityResult.mobile) ||
        connect.contains(ConnectivityResult.ethernet) ||
        connect.contains(ConnectivityResult.wifi)) {
      settingsRepository.getGlobalSettings();
      await settingsRepository.getLanguages();
      await settingsRepository.getMobileTranslations();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.refresh(appProvider);
    return FutureBuilder(
      future: Future.wait([
        if (LocalStorage.getTranslations().isEmpty) _fetchSettings(),
      ]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        return ScreenUtilInit(
          useInheritedMediaQuery: false,
          designSize: const Size(375, 812),
          builder: (context, child) {
            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              routerDelegate: _appRouter.delegate(),
              routeInformationParser: _appRouter.defaultRouteParser(),
              locale: Locale(state.activeLanguage?.locale ?? 'en'),
              theme: ThemeData(useMaterial3: false),
              themeMode: state.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            );
          },
        );
      },
    );
  }
}
