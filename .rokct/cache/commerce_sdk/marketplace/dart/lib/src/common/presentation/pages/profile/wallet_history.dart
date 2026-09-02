// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, version 3.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

import 'package:auto_route/auto_route.dart';
import 'package:base_sdk/src/navigation/embedded_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:base_sdk/src/application/profile/profile_notifier.dart';
import 'package:base_sdk/src/application/profile/profile_provider.dart';
import 'package:base_sdk/src/application/profile/profile_state.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/components/app_bars/common_app_bar.dart';
import 'package:base_sdk/src/presentation/components/badges.dart';
import 'package:intl/intl.dart' as intl;
import 'package:base_sdk/src/presentation/components/buttons/pop_button.dart';
import 'package:base_sdk/src/presentation/components/buttons/second_button.dart';
import 'package:base_sdk/src/presentation/components/loading.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
// [refork] embed via EmbeddedWidgets
import 'package:marketplace_sdk/src/common/presentation/pages/profile/widgets/wallet_topup_screen.dart';
import 'package:marketplace_sdk/src/common/presentation/pages/profile/widgets/wallet_send_screen.dart';

// Add this extension for the capitalize method
extension StringExtension on String {
  String capitalize() {
    return isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : '';
  }
}

@RoutePage()
class WalletHistoryPage extends ConsumerStatefulWidget {
  final bool isBackButton;
  const WalletHistoryPage({super.key, this.isBackButton = true});

  @override
  ConsumerState<WalletHistoryPage> createState() => _WalletHistoryState();
}

class _WalletHistoryState extends ConsumerState<WalletHistoryPage> {
  late RefreshController controller;
  late ProfileState state;
  late ProfileNotifier event;
  final bool isLtr = LocalStorage.getLangLtr();

  @override
  void initState() {
    controller = RefreshController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileProvider.notifier).getWallet(context);
    });
    super.initState();
  }

  @override
  void didChangeDependencies() {
    event = ref.read(profileProvider.notifier);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    state = ref.watch(profileProvider);
    return Directionality(
      textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppStyle.bgGrey,
        body: Column(
          children: [
            CommonAppBar(
              child: Column(
                children: [
                  55.verticalSpace,
                  Row(
                    children: [
                      10.horizontalSpace,
                      Text(
                        AppHelpers.getTranslation(TrKeys.transactions),
                        style: AppStyle.interNoSemi(
                          size: 18,
                          color: AppStyle.black,
                        ),
                      ),
                      5.horizontalSpace,
                      SecondButton(
                        title: AppHelpers.getTranslation(TrKeys.topup),
                        bgColor: AppStyle.primary,
                        titleColor: AppStyle.white,
                        titleSize: 12.sp,
                        onTap: () {
                          AppHelpers.showCustomModalBottomSheet(
                            context: context,
                            modal: ProviderScope(
                              child: Consumer(
                                builder: (context, ref, _) =>
                                    const WalletTopUpScreen(),
                              ),
                            ),
                            isDarkMode: LocalStorage.getAppThemeMode(),
                          );
                        },
                      ),
                      5.horizontalSpace,
                      SecondButton(
                        title: AppHelpers.getTranslation(TrKeys.send),
                        bgColor: AppStyle.primary,
                        titleColor: AppStyle.white,
                        titleSize: 12.sp,
                        onTap: () {
                          AppHelpers.showCustomModalBottomSheet(
                            context: context,
                            modal: ProviderScope(
                              child: Consumer(
                                builder: (context, ref, _) =>
                                    const WalletSendScreen(),
                              ),
                            ),
                            isDarkMode: LocalStorage.getAppThemeMode(),
                          );
                        },
                      ),
                      if (AppHelpers.getLendingEnabled()) ...[
                        5.horizontalSpace,
                        SecondButton(
                          title: AppHelpers.getTranslation(TrKeys.loan),
                          bgColor: AppStyle.primary,
                          titleColor: AppStyle.white,
                          titleSize: 12.sp,
                          onTap: () {
                            AppHelpers.showCustomModalBottomSheet(
                              context: context,
                              modal: ProviderScope(
                                child: Consumer(
                                  builder: (context, ref, _) =>
                                      EmbeddedWidgets.I.loanScreen(),
                                ),
                              ),
                              isDarkMode: LocalStorage.getAppThemeMode(),
                            );
                          },
                        ),
                      ],
                      5.horizontalSpace,
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: state.isLoadingHistory
                  ? const Center(child: Loading())
                  : state.isEmptyWallet
                      ? _resultEmpty()
                      : SmartRefresher(
                          enablePullDown: true,
                          enablePullUp: true,
                          physics: const BouncingScrollPhysics(),
                          controller: controller,
                          onLoading: () {
                            event.getWalletPage(context, controller);
                          },
                          onRefresh: () {
                            event.getWallet(context,
                                refreshController: controller);
                          },
                          child: ListView.builder(
                            padding: EdgeInsets.all(16.r),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            scrollDirection: Axis.vertical,
                            itemCount: state.walletHistory?.length ?? 0,
                            itemBuilder: (context, index) => Container(
                              margin: EdgeInsets.only(bottom: 16.h),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.r),
                                color:
                                    state.walletHistory?[index].type == "topup"
                                        ? Colors.green.withOpacity(0.5)
                                        : state.walletHistory?[index].type ==
                                                "withdraw"
                                            ? AppStyle.red.withOpacity(0.5)
                                            : AppStyle.white,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(
                                      top: 16.r,
                                      right: 16.r,
                                      left: 16.r,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${AppHelpers.getTranslation(TrKeys.paymentDate)}: ${intl.DateFormat("MMM dd,yyyy h:mm a").format(DateTime.tryParse(state.walletHistory?[index].createdAt ?? "")?.toLocal() ?? DateTime.now())}",
                                          style: AppStyle.interRegular(
                                            size: 12.sp,
                                            color: AppStyle.black,
                                          ),
                                        ),
                                        4.verticalSpace,
                                        RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: "Ref: ",
                                                style: AppStyle.interBold(
                                                  size: 16.sp,
                                                  color: AppStyle.black,
                                                ),
                                              ),
                                              TextSpan(
                                                text: state
                                                        .walletHistory?[index]
                                                        .note ??
                                                    "",
                                                style: AppStyle.interRegular(
                                                  size: 16.sp,
                                                  color: AppStyle.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(color: AppStyle.black),
                                  Padding(
                                    padding: EdgeInsets.only(
                                      bottom: 16.r,
                                      right: 16.r,
                                      left: 16.r,
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "Transaction type: ",
                                              style: AppStyle.interRegular(
                                                size: 12.sp,
                                                color: AppStyle.black,
                                              ),
                                            ),
                                            Text(
                                              AppHelpers.numberFormat(
                                                number: state
                                                    .walletHistory?[index]
                                                    .price,
                                              ),
                                              style: AppStyle.interBold(
                                                size: 16.sp,
                                                color: AppStyle.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                        /*16.verticalSpace,
                                 Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppHelpers.getTranslation(
                                        TrKeys.sender),
                                    style: AppStyle.interRegular(
                                      size: 12.sp,
                                      color: AppStyle.black,
                                    ),
                                  ),
                                  Text(
                                    '${state.walletHistory?[index].author?.firstname ?? ""} ${state.walletHistory?[index].author?.lastname ?? ""}',
                                    style: AppStyle.interRegular(
                                      size: 16.sp,
                                      color: AppStyle.black,
                                    ),
                                  )
                                ],
                              ),
                              16.verticalSpace,*/
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              (state.walletHistory?[index]
                                                          .type ??
                                                      "")
                                                  .capitalize(), // is ${(state.walletHistory?[index].status ?? "").capitalize()}',

                                              style: AppStyle.interBold(
                                                size: 12.sp,
                                                color: AppStyle.black,
                                              ),
                                            ),
                                            Text(
                                              'Status: ${(state.walletHistory?[index].status ?? "").capitalize()}',
                                              style: AppStyle.interRegular(
                                                size: 12.sp,
                                                color: AppStyle.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        floatingActionButton: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child:
              widget.isBackButton ? const PopButton() : const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _resultEmpty() {
    return EmptyBadge(
      subtitleText: "Your Transaction History will appear here",
      titleText: "No Transactions",
    );
  }
}
