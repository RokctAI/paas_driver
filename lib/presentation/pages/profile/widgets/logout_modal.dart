import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:driver/application/providers.dart';
import 'package:driver/infrastructure/services/services.dart';
import 'package:driver/presentation/component/components.dart';
import 'package:driver/presentation/routes/app_router.gr.dart';
import 'package:driver/presentation/styles/style.dart';

class LogoutModal extends StatelessWidget {
  final bool isDeleteAccount;

  const LogoutModal({super.key, this.isDeleteAccount = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: REdgeInsets.symmetric(horizontal: 15),
      child: Column(
        children: [
          Text(
            AppHelpers.getTranslation(
              isDeleteAccount
                  ? TrKeys.areYouSure
                  : TrKeys.doYouReallyWantToLogout,
            ),
            style: Style.interSemi(size: 16.sp),
            textAlign: TextAlign.center,
          ),
          40.verticalSpace,
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  borderColor: Style.black,
                  background: Style.transparent,
                  title: AppHelpers.getTranslation(TrKeys.cancel),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              16.horizontalSpace,
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    if (isDeleteAccount) {
                      return CustomButton(
                        background: Style.redColor,
                        textColor: Style.white,
                        title: AppHelpers.getTranslation(TrKeys.deleteAccount),
                        onPressed: () {
                          ref
                              .read(profileSettingsProvider.notifier)
                              .deleteAccount(context);
                        },
                      );
                    } else {
                      return CustomButton(
                        title: AppHelpers.getTranslation(TrKeys.logout),
                        onPressed: () {
                          LocalStorage.logout();
                          context.router.popUntilRoot();
                          context.replaceRoute(const LoginRoute());
                        },
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          24.verticalSpace,
        ],
      ),
    );
  }
}
