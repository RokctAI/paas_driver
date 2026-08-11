// ignore_for_file: use_build_context_synchronously
import 'package:auto_route/auto_route.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/application/language/language_provider.dart';
import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:auth_sdk/src/common/presentation/pages/auth/register/register_page.dart';
// [refork] removed host router import
import 'package:auth_sdk/src/common/application/auth/login/login_provider.dart';
// [refork] embed via EmbeddedWidgets
import 'package:auth_sdk/src/common/presentation/pages/auth/login/login_screen.dart';

import 'package:base_sdk/src/presentation/theme/theme.dart';
import 'package:base_sdk/src/presentation/components/buttons/second_button.dart';
import 'package:base_sdk/src/navigation/embedded_widgets.dart';
import 'package:base_sdk/src/navigation/app_routes.dart';
// [refork] intro page embedded via EmbeddedWidgets registry
// [refork] embed via EmbeddedWidgets
// [refork] embed via EmbeddedWidgets

@RoutePage()
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  bool _showIntro = false;
  Widget? _introPage;
  late String splashImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(loginProvider.notifier).checkLanguage(context);
    });
    initDynamicLinks();
    // Initialize IntroPage — guarded: introPage() is only real when an
    // onboarding SDK is composed into this app and declares it in
    // "embedded_widgets". In hosts without one (e.g. manager/driver) the
    // registry's noSuchMethod throws a StateError, which used to crash the
    // login screen at init; those apps simply have no intro, so the Skip
    // affordance is hidden instead (see the Skip button below).
    try {
      _introPage = EmbeddedWidgets.I.introPage();
    } on StateError catch (e) {
      debugPrint('==> LoginPage: no intro page composed, hiding Skip: $e');
      _introPage = null;
    }

    // Determine which splash image to use based on the current date
    DateTime now = DateTime.now();
    DateTime startDate = DateTime(2024, 9, 1);
    DateTime endDate = DateTime(2024, 9, 10, 23, 59);

    if (now.isBefore(startDate)) {
      splashImage = "assets/images/splash1.png";
    } else if (now.isBefore(endDate)) {
      splashImage = "assets/images/splash2.png";
    } else {
      splashImage = "assets/images/splash.png"; // Default image
    }
  }

  Future<void> initDynamicLinks() async {
    // Firebase isn't initialized on every platform/dev environment this
    // page runs in (e.g. Windows dev builds deliberately skip it — see
    // supacharge/pubspec.yaml's win_dev_overrides). Accessing
    // FirebaseDynamicLinks.instance without Firebase.initializeApp() having
    // run throws "No Firebase App '[DEFAULT]' has been created" — dynamic
    // links just aren't available there, which is fine; login/register
    // itself doesn't depend on them.
    late final FirebaseDynamicLinks dynamicLinks;
    try {
      dynamicLinks = FirebaseDynamicLinks.instance;
    } catch (e) {
      debugPrint('==> LoginPage: Firebase not initialized, skipping dynamic links: $e');
      return;
    }
    dynamicLinks.onLink.listen((dynamicLinkData) {
      String link = dynamicLinkData.link.toString().substring(
            dynamicLinkData.link.toString().indexOf("shop") + 4,
          );
      if (link.toString().contains("product") ||
          link.toString().contains("shop")) {
        if (AppConstants.isDemo) {
          AppRoutes.I.replaceUiTypeRoute(context);
          return;
        }
        AppHelpers.goHome(context);
      }
    }).onError((error) {
      debugPrint(error.message);
    });

    final PendingDynamicLinkData? data =
        await FirebaseDynamicLinks.instance.getInitialLink();
    final Uri? deepLink = data?.link;

    if (deepLink.toString().contains("product") ||
        deepLink.toString().contains("shop")) {
      if (AppConstants.isDemo) {
        AppRoutes.I.replaceUiTypeRoute(context);
        return;
      }
      AppHelpers.goHome(context);
    }
  }

  void selectLanguage() {
    AppHelpers.showCustomModalBottomSheet(
      isDismissible: false,
      isDrag: false,
      context: context,
      modal: EmbeddedWidgets.I.languageScreen(
        onSave: () {
          Navigator.pop(context);
        },
      ),
      isDarkMode: false,
    );
  }

  void _showIntroPage() {
    if (_introPage == null) return;
    setState(() {
      _showIntro = true;
    });
  }

  // ignore: unused_element
  void _closeIntroPage() {
    setState(() {
      _showIntro = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(languageProvider);
    ref.listen(loginProvider, (previous, next) {
      if (!next.isSelectLanguage &&
          !((previous?.isSelectLanguage ?? false) == next.isSelectLanguage)) {
        // Only show language selection if we have more than one language
        final languageState = ref.read(languageProvider);
        if (languageState.list.length > 1) {
          selectLanguage();
        } else if (languageState.list.length == 1) {
          // If there's only one language, auto-select it
          ref.read(languageProvider.notifier).makeSelectedLang(context);
        }
      }
    });

    final bool isDarkMode = LocalStorage.getAppThemeMode();
    final bool isLtr = LocalStorage.getLangLtr();
    return Directionality(
      textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor:
            isDarkMode ? AppStyle.dontHaveAnAccBackDark : AppStyle.white,
        body: _showIntro && _introPage != null
            ? _introPage! // Show preloaded IntroPage if _showIntro is true
            : Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(splashImage),
                    fit: BoxFit.fill,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: REdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            /* Image.asset(
                        AppAssets.pngLogo,
                        width: 50.r,
                        height: 50.r,
                      ),*/
                            // Flexible + scale-down: .sp sizes are scaled
                            // against a portrait design size, so on a wide
                            // desktop window the logo text renders huge and
                            // used to overflow this Row by hundreds of px.
                            // Shrinking to the available width is a no-op on
                            // phones, where it already fit.
                            AppHelpers.getAppName() != null
                                ? Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: AlignmentDirectional
                                          .centerStart,
                                      child: RichText(
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text: AppHelpers.getAppName(),
                                              style:
                                                  AppStyle.logoFontBoldItalic(
                                                color: AppStyle.white,
                                                size: 35.sp,
                                              ),
                                            ),
                                            WidgetSpan(
                                              child: Transform.translate(
                                                offset: Offset(
                                                  0,
                                                  -15,
                                                ), // Move up by 15 pixels, adjust as needed
                                                child: Text(
                                                  "®",
                                                  style: AppStyle
                                                      .logoFontBoldItalic(
                                                    color: AppStyle.white,
                                                    size: 12.sp,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                : SizedBox.shrink(),
                            8.horizontalSpace,
                            const Spacer(),
                            const Spacer(),
                            // No composed intro -> no Skip: tapping it could
                            // only land on a blank page.
                            if (_introPage != null)
                              SecondButton(
                                onTap:
                                    _showIntroPage, // Show IntroPage when Skip is tapped
                                title: AppHelpers.getTranslation(TrKeys.skip),
                                bgColor: AppStyle.primary,
                                titleColor: AppStyle.white,
                              ),
                          ],
                        ),
                        // Flexible + scroll: the scaled buttons/terms card can
                        // run a few px past the height budget on desktop
                        // aspect ratios (the "BOTTOM OVERFLOWED BY N PIXELS"
                        // stripes). Scrolls only when it must; sizes to
                        // content — and stays bottom-pinned — when it fits.
                        Flexible(
                          child: SingleChildScrollView(
                            child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CustomButton(
                              title: AppHelpers.getTranslation(TrKeys.login),
                              onPressed: () {
                                AppHelpers.showCustomModalBottomSheet(
                                  context: context,
                                  modal: const LoginScreen(),
                                  isDarkMode: isDarkMode,
                                );
                              },
                            ),
                            10.verticalSpace,
                            CustomButton(
                              title: AppHelpers.getTranslation(TrKeys.register),
                              onPressed: () {
                                AppHelpers.showCustomModalBottomSheet(
                                  context: context,
                                  modal: RegisterPage(isOnlyEmail: true),
                                  isDarkMode: isDarkMode,
                                  paddingTop: MediaQuery.paddingOf(context).top,
                                );
                              },
                              background: AppStyle.transparent,
                              textColor: AppStyle.white,
                              borderColor: AppStyle.white,
                            ),
                            5.verticalSpace,
                            Container(
                              decoration: BoxDecoration(
                                color: AppStyle.white.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(
                                  10,
                                ), // Adjust the radius as needed
                              ),
                              padding: const EdgeInsets.all(
                                16,
                              ), // Adjust the padding as needed
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                children: [
                                  Text(
                                    "By using ${AppHelpers.getAppName() ?? ""}'s services, you acknowledge that you have read and accepted the",
                                    style: const TextStyle(
                                      color: AppStyle.black,
                                    ), // Make text color white for visibility
                                  ),
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              EmbeddedWidgets.I.termPage(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      AppHelpers.getTranslation(TrKeys.terms),
                                      style: const TextStyle(
                                        decoration: TextDecoration.underline,
                                        color: AppStyle
                                            .black, // Optional: Different color for links
                                      ),
                                    ),
                                  ),
                                  const Text(
                                    " & ",
                                    style: TextStyle(
                                      color: AppStyle.black,
                                    ), // Make text color white for visibility
                                  ),
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              EmbeddedWidgets.I.policyPage(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      AppHelpers.getTranslation(
                                        TrKeys.privacyPolicy,
                                      ),
                                      style: const TextStyle(
                                        decoration: TextDecoration.underline,
                                        color: AppStyle
                                            .black, // Optional: Different color for links
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            20.verticalSpace,
                          ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
