// Migration stage M2 note: this widget still rides the HOST app/splash
// providers and the host SettingsRepository, deliberately - the surviving
// host auth vertical (login language switcher) writes to the same
// providers, and splitting the two onto base_sdk's twins mid-migration
// would break locale switching. The retarget onto base_sdk's
// app_provider/settings facade happens with the auth flip (M3), after
// which this file aligns with base_sdk's templates/app_widget.dart.
//
// The double-startup that used to live here (setUpDependencies +
// LocalStorage.init inside the FutureBuilder, both already awaited by
// main() before runApp) was dropped in M2: registerSingleton is unguarded,
// so the second setUpDependencies() call threw on startup.
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../application/providers.dart';
import '../domain/di/dependency_manager.dart';
import '../infrastructure/services/services.dart';

class AppWidget extends ConsumerWidget {
  const AppWidget({super.key});

  Future fetchSetting() async {
    final connect = await Connectivity().checkConnectivity();
    if (!connect.contains(ConnectivityResult.none)) {
      settingsRepository.getGlobalSettings();
      await settingsRepository.getLanguages();
      await settingsRepository.getTranslations();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: Future.wait([
        if (LocalStorage.getTranslations().isEmpty) fetchSetting(),
      ]),
      builder: (context, AsyncSnapshot<List<dynamic>> snap) {
        return ScreenUtilInit(
          useInheritedMediaQuery: true,
          designSize: const Size(375, 812),
          builder: (context, child) {
            return RefreshConfiguration(
              footerBuilder: () => const ClassicFooter(
                idleIcon: SizedBox(),
                idleText: '',
              ),
              child: MaterialApp.router(
                theme: ThemeData(useMaterial3: false),
                debugShowCheckedModeBanner: false,
                routerDelegate: appRouter.delegate(),
                routeInformationParser: appRouter.defaultRouteParser(),
                locale: Locale(
                  ref.watch(appProvider).activeLanguage?.locale ?? 'en',
                ),
                themeMode: ThemeMode.light,
              ),
            );
          },
        );
      },
    );
  }
}
