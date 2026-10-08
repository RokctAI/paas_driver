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

// THE PLACE, OPENED — what a driver reads before he knocks.
//
// The point as it was filed (its name, its kind, its address, the note the
// last driver left) and what has been SOLD here: how many times, for how
// much, and when the last visit was. That history is the whole reason a
// point is worth filing on a round nobody has worked before.
//
// A POINT WITH NO SALES IS NOT AN EMPTY SCREEN. Most points are filed for
// the knowledge alone, so the no-history line says exactly that and offers
// nothing to fix.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:remixicon/remixicon.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';

import 'package:delivery_sdk/src/driver/application/poi/poi_provider.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/driver_poi.dart';

class PoiSheet extends ConsumerStatefulWidget {
  const PoiSheet({super.key, required this.point});

  final DriverPoi point;

  /// Opens the sheet for [point] and reads its sales history.
  static void open(BuildContext context, DriverPoi point) {
    AppHelpers.showCustomModalBottomSheet(
      context: context,
      isDarkMode: (Theme.of(context).brightness == Brightness.dark),
      modal: PoiSheet(point: point),
    );
  }

  @override
  ConsumerState<PoiSheet> createState() => _PoiSheetState();
}

class _PoiSheetState extends ConsumerState<PoiSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(driverPoiProvider.notifier)
          .loadSales(widget.point.id, context: context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(driverPoiProvider);
    // The sheet's own point stays authoritative for the header; only the
    // history comes from the slice, and only when it is this point's.
    final sales =
        state.sales?.poi?.id == widget.point.id ? state.sales : null;
    final point = sales?.poi ?? widget.point;
    final kind = point.kind;
    return Padding(
      key: const Key('poiSheet'),
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
            point.title,
            key: const Key('poiSheetTitle'),
            style: AppStyle.interSemi(size: 20, color: AppStyle.inkFor(Theme.of(context).brightness)),
          ),
          if (kind.isNotEmpty) ...[
            4.verticalSpace,
            Text(
              kind,
              key: const Key('poiSheetKind'),
              style: AppStyle.interRegular(
                size: 13,
                color: AppStyle.secondaryInkFor(Theme.of(context).brightness),
              ),
            ),
          ],
          if ((point.address ?? '').isNotEmpty) ...[
            10.verticalSpace,
            _IconLine(icon: Remix.map_pin_line, text: point.address!),
          ],
          if ((point.note ?? '').isNotEmpty) ...[
            8.verticalSpace,
            _IconLine(
              icon: Remix.sticky_note_line,
              text: point.note!,
              key: const Key('poiSheetNote'),
            ),
          ],
          16.verticalSpace,
          Divider(height: 1, color: AppStyle.subtleStrokeFor(Theme.of(context).brightness)),
          14.verticalSpace,
          Text(
            AppHelpers.getTranslation('sold_here'),
            style: AppStyle.interRegular(
              size: 12,
              color: AppStyle.faintFor(Theme.of(context).brightness),
            ),
          ),
          8.verticalSpace,
          if (state.isLoadingSales)
            Text(
              key: const Key('poiSheetSalesLoading'),
              AppHelpers.getTranslation('reading_what_was_sold_here'),
              style: AppStyle.interRegular(
                size: 13,
                color: AppStyle.secondaryInkFor(Theme.of(context).brightness),
              ),
            )
          else if (sales == null || !sales.hasHistory)
            Text(
              key: const Key('poiSheetNoSales'),
              AppHelpers.getTranslation('nothing_sold_here_yet'),
              style: AppStyle.interRegular(
                size: 13,
                color: AppStyle.secondaryInkFor(Theme.of(context).brightness),
              ),
            )
          else ...[
            Row(
              key: const Key('poiSheetSalesTotals'),
              children: [
                Expanded(
                  child: Text(
                    '${sales.count} '
                    '${AppHelpers.getTranslation(sales.count == 1 ? 'sale' : 'sales')}',
                    style: AppStyle.interRegular(
                      size: 13,
                      color: AppStyle.secondaryInkFor(Theme.of(context).brightness),
                    ),
                  ),
                ),
                Text(
                  AppHelpers.numberFormat(number: sales.total),
                  style: AppStyle.interSemi(
                    size: 18,
                    color: AppStyle.inkFor(Theme.of(context).brightness),
                  ),
                ),
              ],
            ),
            if ((sales.lastVisit ?? '').isNotEmpty) ...[
              4.verticalSpace,
              Text(
                '${AppHelpers.getTranslation('last_visit')} '
                '${sales.lastVisit}',
                key: const Key('poiSheetLastVisit'),
                style: AppStyle.interRegular(
                  size: 12,
                  color: AppStyle.faintFor(Theme.of(context).brightness),
                ),
              ),
            ],
            10.verticalSpace,
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 260.h),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final sale in sales.sales)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 6.h),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                sale.orderId,
                                style: AppStyle.interRegular(
                                  size: 13,
                                  color: AppStyle.inkFor(Theme.of(context).brightness),
                                ),
                              ),
                            ),
                            Text(
                              AppHelpers.numberFormat(number: sale.total),
                              style: AppStyle.interSemi(
                                size: 13,
                                color: AppStyle.inkFor(Theme.of(context).brightness),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _IconLine extends StatelessWidget {
  const _IconLine({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16.r, color: AppStyle.faintFor(Theme.of(context).brightness)),
        8.horizontalSpace,
        Expanded(
          child: Text(
            text,
            style: AppStyle.interRegular(
              size: 13,
              color: AppStyle.secondaryInkFor(Theme.of(context).brightness),
            ),
          ),
        ),
      ],
    );
  }
}
