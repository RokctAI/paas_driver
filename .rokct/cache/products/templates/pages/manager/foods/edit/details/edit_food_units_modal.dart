import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/components/title_icon.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:products_sdk/src/manager/application/foods/edit/details/units/edit_food_units_provider.dart';
import 'package:${package}/presentation/component/helper/modal_drag.dart';
import 'package:${package}/presentation/component/helper/modal_wrap.dart';
import 'package:${package}/presentation/components/foods/food_unit_item.dart';

class EditFoodUnitsModal extends ConsumerStatefulWidget {
  const EditFoodUnitsModal({super.key});

  @override
  ConsumerState<EditFoodUnitsModal> createState() => _EditFoodUnitsModalState();
}

class _EditFoodUnitsModalState extends ConsumerState<EditFoodUnitsModal> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(editFoodUnitsProvider.notifier).fetchUnits(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ModalWrap(
      body: Padding(
        padding: REdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ModalDrag(),
            TitleAndIcon(
              title: AppHelpers.getTranslation(TrKeys.units),
              titleSize: 16,
            ),
            24.verticalSpace,
            Consumer(
              builder: (context, ref, child) {
                final state = ref.watch(editFoodUnitsProvider);
                final event = ref.read(editFoodUnitsProvider.notifier);
                return state.isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 3.r,
                          color: AppStyle.primary,
                        ),
                      )
                    : Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: state.units.length,
                          shrinkWrap: true,
                          itemBuilder: (context, index) => FoodUnitItem(
                            unit: state.units[index],
                            onTap: () => event.setActiveIndex(index),
                            isSelected: state.activeIndex == index,
                          ),
                        ),
                      );
              },
            ),
            24.verticalSpace,
            CustomButton(
              title: AppHelpers.getTranslation(TrKeys.close),
              onPressed: context.maybePop,
            ),
            20.verticalSpace,
          ],
        ),
      ),
    );
  }
}
