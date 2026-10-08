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

// "AT THIS POINT" — the row on the sell screen that says where the sale
// was made.
//
// It is OPTIONAL and stays optional. A sale with no point named is the
// normal case and the commit never waits for one; naming a point is how the
// round learns which corners actually buy.
//
// The list is seeded from the driver's own fix, so what he picks from is
// what is around him. When nothing in it is the place he is standing at,
// the same row offers to add it — which is the only way a point gets filed
// mid-sale, and it lands back on this row with the new point selected.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:remixicon/remixicon.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';

import 'package:delivery_sdk/src/driver/application/poi/poi_provider.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/driver_poi.dart';
import 'package:delivery_sdk/src/driver/presentation/poi/add_poi_sheet.dart';

class PoiSelectorRow extends ConsumerStatefulWidget {
  const PoiSelectorRow({super.key, this.shop});

  /// The shop of the load being sold from. Carried through to the sheet
  /// so a place filed from the sell screen is tagged to the round that
  /// produced it, exactly as one filed from the load card is.
  final String? shop;

  @override
  ConsumerState<PoiSelectorRow> createState() => _PoiSelectorRowState();
}

class _PoiSelectorRowState extends ConsumerState<PoiSelectorRow> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(driverPoiProvider.notifier);
      notifier.loadNearby(context: context);
      notifier.loadTypes(context: context);
    });
  }

  void _openList() {
    AppHelpers.showCustomModalBottomSheet(
      context: context,
      isDarkMode: (Theme.of(context).brightness == Brightness.dark),
      modal: _PoiPickerSheet(shop: widget.shop),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(driverPoiProvider);
    final selected = state.selected;
    return Container(
      key: const Key('loadSalePoi'),
      decoration: BoxDecoration(
        color: AppStyle.cardFor(Theme.of(context).brightness),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppStyle.strokeFor(Theme.of(context).brightness)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14.r),
        child: InkWell(
          key: const Key('loadSalePoiOpen'),
          borderRadius: BorderRadius.circular(14.r),
          onTap: _openList,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            child: Row(
              children: [
                Icon(
                  Remix.map_pin_line,
                  size: 18.r,
                  color: AppStyle.secondaryInkFor(Theme.of(context).brightness),
                ),
                10.horizontalSpace,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppHelpers.getTranslation('at_this_place'),
                        style: AppStyle.interRegular(
                          size: 11,
                          color: AppStyle.faintFor(Theme.of(context).brightness),
                        ),
                      ),
                      2.verticalSpace,
                      Text(
                        selected?.title ??
                            AppHelpers.getTranslation('not_said'),
                        key: const Key('loadSalePoiValue'),
                        style: AppStyle.interSemi(
                          size: 14,
                          color: AppStyle.inkFor(Theme.of(context).brightness),
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected != null)
                  IconButton(
                    key: const Key('loadSalePoiClear'),
                    tooltip: AppHelpers.getTranslation('clear'),
                    icon: Icon(
                      Remix.close_line,
                      size: 18.r,
                      color: AppStyle.secondaryInkFor(Theme.of(context).brightness),
                    ),
                    onPressed: () =>
                        ref.read(driverPoiProvider.notifier).select(null),
                  )
                else
                  Icon(
                    Remix.arrow_right_s_line,
                    size: 20.r,
                    color: AppStyle.secondaryInkFor(Theme.of(context).brightness),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The chooser: what is around him, and the way out when none of it is the
/// place he is standing at.
class _PoiPickerSheet extends ConsumerWidget {
  const _PoiPickerSheet({this.shop});

  /// The load's shop, handed on to the add sheet this one opens.
  final String? shop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(driverPoiProvider);
    return Padding(
      key: const Key('poiPickerSheet'),
      padding: EdgeInsets.fromLTRB(
        16.w,
        20.h,
        16.w,
        MediaQuery.paddingOf(context).bottom + 20.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppHelpers.getTranslation('where_are_you'),
            style: AppStyle.interSemi(size: 18, color: AppStyle.inkFor(Theme.of(context).brightness)),
          ),
          12.verticalSpace,
          if (state.points.isEmpty)
            Text(
              key: const Key('poiPickerEmpty'),
              AppHelpers.getTranslation(
                state.loadedOnce
                    ? 'nothing_on_the_map_around_you_yet'
                    : 'looking_for_places_around_you',
              ),
              style: AppStyle.interRegular(
                size: 13,
                color: AppStyle.secondaryInkFor(Theme.of(context).brightness),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 320.h),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final point in state.points)
                      PoiListRow(
                        point: point,
                        selected: point.id == state.selected?.id,
                        onTap: () {
                          ref
                              .read(driverPoiProvider.notifier)
                              .select(point);
                          Navigator.of(context).maybePop();
                        },
                      ),
                  ],
                ),
              ),
            ),
          12.verticalSpace,
          // The fallback, in the one place a driver discovers he needs it:
          // he is looking at the list and his corner is not on it.
          TextButton.icon(
            key: const Key('poiPickerAdd'),
            onPressed: () {
              final sheetNavigator = Navigator.of(context);
              AddPoiSheet.open(
                context,
                shop: shop,
                onFiled: (_) => sheetNavigator.maybePop(),
              );
            },
            icon: Icon(Remix.add_line, size: 18.r, color: AppStyle.primary),
            label: Text(
              AppHelpers.getTranslation('add_a_place'),
              style: AppStyle.interSemi(size: 14, color: AppStyle.primary),
            ),
          ),
        ],
      ),
    );
  }
}

/// One point as a row: what it is called, what kind of place it is, and how
/// far off it is when the server measured it.
class PoiListRow extends StatelessWidget {
  const PoiListRow({
    super.key,
    required this.point,
    this.selected = false,
    this.onTap,
  });

  final DriverPoi point;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final kind = point.kind;
    final distance = point.distanceKm;
    return Material(
      color: selected ? AppStyle.cardAltFor(Theme.of(context).brightness) : Colors.transparent,
      borderRadius: BorderRadius.circular(10.r),
      child: InkWell(
        key: Key('poiRow-${point.id}'),
        borderRadius: BorderRadius.circular(10.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      point.title,
                      style: AppStyle.interSemi(
                        size: 14,
                        color: AppStyle.inkFor(Theme.of(context).brightness),
                      ),
                    ),
                    if (kind.isNotEmpty) ...[
                      2.verticalSpace,
                      Text(
                        kind,
                        style: AppStyle.interRegular(
                          size: 12,
                          color: AppStyle.secondaryInkFor(Theme.of(context).brightness),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (distance != null)
                Text(
                  poiDistanceText(distance),
                  style: AppStyle.interRegular(
                    size: 12,
                    color: AppStyle.faintFor(Theme.of(context).brightness),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// How far off a point is, in the units a driver reads: metres up close,
/// kilometres past that.
String poiDistanceText(double km) {
  if (km < 1) {
    final metres = (km * 1000).round();
    return '$metres m';
  }
  return '${km.toStringAsFixed(1)} km';
}
