import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:driver/application/parcel/parcel_provider.dart';
import 'package:driver/application/statistics/statistics_provider.dart';

import '../../application/order/all_order/order_provider.dart';
import '../../infrastructure/services/app_helpers.dart';
import '../../infrastructure/services/tr_keys.dart';
import '../styles/style.dart';
import 'buttons/custom_button.dart';
import 'custom_date_picker.dart';
import 'tab_bars/custom_tab_bar.dart';
import 'title_icon.dart';

class FilterScreen extends StatefulWidget {
  final bool isTabBar;
  final bool parcel;
  final DateTime? start;
  final DateTime? end;

  const FilterScreen({
    super.key,
    this.isTabBar = true,
    this.start,
    this.end,
    this.parcel = false,
  });

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<DateTime?> _rangeDatePicker = [];
  List<DateTime?> _newList = [];

  final _tabs = [
    Tab(child: Text(AppHelpers.getTranslation(TrKeys.today))),
    Tab(
      child: Text(
        AppHelpers.getTranslation(TrKeys.weekly),
        maxLines: 1,
        overflow: TextOverflow.clip,
      ),
    ),
    Tab(
      child: Text(
        AppHelpers.getTranslation(TrKeys.monthly),
        maxLines: 1,
        overflow: TextOverflow.clip,
      ),
    ),
    Tab(child: Text(AppHelpers.getTranslation(TrKeys.overall))),
  ];

  @override
  void initState() {
    _tabController = TabController(length: 4, vsync: this);
    _rangeDatePicker = [
      widget.start ?? DateTime.now(),
      widget.end ?? DateTime.now(),
    ];
    _tabController.addListener(() {
      switch (_tabController.index) {
        case 0:
          _rangeDatePicker = [DateTime.now(), DateTime.now()];
          _newList = _rangeDatePicker;
          break;
        case 1:
          _rangeDatePicker = [
            DateTime.now().subtract(const Duration(days: 7)),
            DateTime.now(),
          ];
          _newList = _rangeDatePicker;
          break;
        case 2:
          _rangeDatePicker = [
            DateTime.now().subtract(const Duration(days: 30)),
            DateTime.now(),
          ];
          _newList = _rangeDatePicker;
          break;
        case 3:
          _rangeDatePicker = [
            DateTime.now().subtract(const Duration(days: 120)),
            DateTime.now(),
          ];
          _newList = _rangeDatePicker;
          break;
      }
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: TitleAndIcon(title: AppHelpers.getTranslation(TrKeys.filter)),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            AppHelpers.getTranslation(TrKeys.selectDesiredOrderHistory),
            style: Style.interNormal(
              size: 14.sp,
              color: Style.black,
              letterSpacing: -0.3,
            ),
          ),
        ),
        widget.isTabBar
            ? Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
                child: CustomTabBar(
                  scroll: true,
                  tabController: _tabController,
                  tabs: _tabs,
                ),
              )
            : const SizedBox.shrink(),
        CustomDatePicker(
          range: _rangeDatePicker,
          onChange: (n) {
            _newList = n;
          },
        ),
        16.verticalSpace,
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Consumer(
            builder: (context, ref, child) {
              return CustomButton(
                title: AppHelpers.getTranslation(TrKeys.save),
                onPressed: () {
                  widget.isTabBar
                      ? widget.parcel
                            ? ref
                                  .read(parcelProvider.notifier)
                                  .fetchHistoryOrders(
                                    context,
                                    start: _newList.first,
                                    end: _newList.last,
                                  )
                            : ref
                                  .read(orderProvider.notifier)
                                  .fetchHistoryOrders(
                                    context,
                                    start: _newList.first,
                                    end: _newList.last,
                                  )
                      : ref
                            .read(statisticsProvider.notifier)
                            .fetchStatistics(
                              startTime: _newList.last ?? DateTime.now(),
                              endTime: _newList.first ?? DateTime.now(),
                            );
                  context.router.maybePop();
                },
              );
            },
          ),
        ),
        8.verticalSpace,
      ],
    );
  }
}
