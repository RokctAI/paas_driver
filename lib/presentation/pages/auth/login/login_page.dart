import 'package:auto_route/auto_route.dart';
import 'package:driver/presentation/app_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:driver/presentation/pages/auth/login/widgets/languages_modal.dart';
import '../register_page.dart';
import 'widgets/login_modal.dart';
import '../../../styles/style.dart';
import '../../../component/components.dart';
import '../../../../application/providers.dart';
import '../../../../infrastructure/services/services.dart';

@RoutePage()
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(languagesProvider.notifier).checkLanguage(context),
    );
  }

  void selectLanguage() {
    AppHelpers.showCustomModalBottomSheet(
      isDismissible: false,
      isDrag: false,
      context: context,
      modal: LanguageScreen(
        afterUpdate: (lang) {
          ref.read(appProvider.notifier).changeLanguage(lang);
        },
      ),
      isDarkMode: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLtr = LocalStorage.getLangLtr();
    ref.listen(languagesProvider, (previous, next) {
      if (!next.isSelectLanguage &&
          !((previous?.isSelectLanguage ?? false) == next.isSelectLanguage)) {
        selectLanguage();
      }
    });
    return Directionality(
      textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(Assets.imageBackground),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: REdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  30.verticalSpace,
                  Row(
                    children: [
                      Text(
                        AppHelpers.getAppName(),
                        style: Style.interBold(color: Style.white, size: 24),
                      ),
                    ],
                  ),
                  const Spacer(),
                  CustomButton(
                    background: Style.primary,
                    title: AppHelpers.getTranslation(TrKeys.login),
                    onPressed: () =>
                        AppHelpers.showCustomModalBottomSheetWithoutIosIcon(
                          context: context,
                          modal: const LoginModal(),
                          isDarkMode: false,
                        ),
                  ),
                  10.verticalSpace,
                  CustomButton(
                    title: AppHelpers.getTranslation(TrKeys.register),
                    onPressed: () {
                      AppHelpers.showCustomModalBottomSheetWithoutIosIcon(
                        context: context,
                        modal: const RegisterPage(isOnlyEmail: true),
                        isDarkMode: false,
                      );
                    },
                    background: Style.transparent,
                    textColor: Style.white,
                    borderColor: Style.white,
                  ),
                  30.verticalSpace,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
