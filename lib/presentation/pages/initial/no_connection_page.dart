import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:driver/infrastructure/services/services.dart';
import 'package:driver/presentation/routes/app_router.gr.dart';
import 'package:driver/presentation/styles/style.dart';

@RoutePage()
class NoConnectionPage extends ConsumerWidget {
  const NoConnectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Style.white,
      body: Padding(
        padding: REdgeInsets.symmetric(horizontal: 16, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              FlutterRemix.wifi_off_fill,
              size: 120,
              color: Style.black,
            ),
            const SizedBox(height: 20),
            Text(
              AppHelpers.getTranslation(TrKeys.noInternetConnection),
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                color: Style.black,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                context.replaceRoute(const SplashRoute());
              },
              child: const Icon(
                FlutterRemix.restart_fill,
                color: Style.black,
                size: 40,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
