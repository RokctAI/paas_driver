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

// THE "MY LOAD" TILE on the driver home, next to the cash-on-hand card.
//
// It sits beside chip 932 because it is the same kind of fact: cash on hand
// is the shop's money in his pocket, this is the shop's STOCK on his van.
// Both are things he is personally answerable for and neither was visible
// anywhere before.
//
// SHOWN ONLY WHEN THERE IS A LOAD. That is the home sheet's existing rule,
// not a new one: the cash card is wrapped in
// `if (home.report.cashOrderCount > 0)` for exactly the same reason — a
// driver who is not carrying anything should not be told about a thing he
// is not carrying. Most drivers never see this tile, and that is correct.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:remixicon/remixicon.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';

import 'package:delivery_sdk/src/driver/presentation/load/load_line_tiles.dart';

class MyLoadCard extends StatelessWidget {
  const MyLoadCard({
    super.key,
    required this.remainingUnits,
    required this.remainingValue,
    required this.loadCount,
    required this.onOpen,
  });

  /// Units still on the van across every open load.
  final num remainingUnits;

  /// Those units at the load prices — what he is carrying liability for.
  final num remainingValue;

  /// How many open loads that came from; almost always one.
  final int loadCount;

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppStyle.cardAltFor(Theme.of(context).brightness),
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        key: const Key('driverHomeMyLoadCard'),
        borderRadius: BorderRadius.circular(14.r),
        onTap: onOpen,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: AppStyle.subtleStrokeFor(Theme.of(context).brightness),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppHelpers.getTranslation('my_load'),
                      style: AppStyle.interSemi(
                        size: 15,
                        color: AppStyle.inkFor(Theme.of(context).brightness),
                      ),
                    ),
                    4.verticalSpace,
                    Text(
                      _subLine(),
                      style: AppStyle.interNormal(
                        size: 12,
                        color: AppStyle.secondaryInkFor(
                          Theme.of(context).brightness,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              12.horizontalSpace,
              Text(
                AppHelpers.numberFormat(number: remainingValue),
                key: const Key('driverHomeMyLoadValue'),
                style: AppStyle.interSemi(
                  size: 20,
                  color: AppStyle.inkFor(Theme.of(context).brightness),
                ),
              ),
              4.horizontalSpace,
              Icon(
                Remix.arrow_right_s_line,
                size: 20.r,
                color: AppStyle.secondaryInkFor(Theme.of(context).brightness),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "12 items on the van", and which shop count when there is more than
  /// one load open. Pluralised through the SDK's own keys rather than by
  /// string surgery on a translated word (the cash card's rule).
  String _subLine() {
    final units = loadQtyText(remainingUnits);
    final items = AppHelpers.getTranslation(
      remainingUnits == 1 ? 'item' : 'items',
    );
    final onTheVan = AppHelpers.getTranslation('on_the_van');
    if (loadCount <= 1) return '$units $items · $onTheVan';
    final loads = AppHelpers.getTranslation('loads');
    return '$units $items · $loadCount $loads';
  }
}
