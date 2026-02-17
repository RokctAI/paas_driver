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
      await settingsRepository.getGlobalSettings();
      await settingsRepository.getLanguages();
      await settingsRepository.getTranslations();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: Future.wait([
        setUpDependencies(),
        if (LocalStorage.getTranslations().isEmpty) fetchSetting(),
      ]),
      builder: (context, AsyncSnapshot<List<dynamic>> snap) {
        return ScreenUtilInit(
          useInheritedMediaQuery: true,
          designSize: const Size(375, 812),
          builder: (context, child) {
            return RefreshConfiguration(
              footerBuilder: () =>
                  const ClassicFooter(idleIcon: SizedBox(), idleText: ''),
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
