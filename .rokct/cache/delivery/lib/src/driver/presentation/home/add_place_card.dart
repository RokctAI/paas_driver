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

// "ADD A PLACE" ON THE DRIVER HOME — the off-load way in.
//
// NOT GATED ON A LOAD, and that is the whole point of it. Every other way
// into the Add-a-place sheet hangs off a load: the load card's fourth
// action and the sell screen's place row. A driver who is running orders,
// or driving back empty, passed the same corners and knows the same things
// — and until this card he had nowhere to put them.
//
// It sits beside "My Load" rather than inside it for exactly that reason:
// MyLoadCard is wrapped in `if (loadState.hasOpenLoad)` because a driver
// who is carrying nothing should not be told about a load he does not have,
// while a place is worth filing on every kind of day.
//
// IT NAMES NO SHOP. Off a load nobody knows which round the place belongs
// to, so the sheet asks the server which shops he delivers for and, when
// there is more than one, asks him.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:remixicon/remixicon.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';

class AddPlaceCard extends StatelessWidget {
  const AddPlaceCard({super.key, required this.onAddPlace});

  final VoidCallback onAddPlace;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppStyle.cardAltFor(Theme.of(context).brightness),
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        key: const Key('driverHomeAddPlaceCard'),
        borderRadius: BorderRadius.circular(14.r),
        onTap: onAddPlace,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: AppStyle.subtleStrokeFor(Theme.of(context).brightness)),
          ),
          child: Row(
            children: [
              Icon(
                Remix.map_pin_line,
                size: 20.r,
                color: AppStyle.primary,
              ),
              12.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppHelpers.getTranslation('add_a_place'),
                      style: AppStyle.interSemi(
                        size: 15,
                        color: AppStyle.inkFor(Theme.of(context).brightness),
                      ),
                    ),
                    4.verticalSpace,
                    Text(
                      AppHelpers.getTranslation(
                        'file_a_corner_you_passed_for_the_next_driver',
                      ),
                      style: AppStyle.interNormal(
                        size: 12,
                        color: AppStyle.secondaryInkFor(Theme.of(context).brightness),
                      ),
                    ),
                  ],
                ),
              ),
              8.horizontalSpace,
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
}
