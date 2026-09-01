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

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/key_sound.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../application/calculator/calculator_provider.dart';
import '../calc_format.dart';

/// CHIP 838 — THE MEMORY BAR.
///
/// The only genuinely new INFORMATION on the calculator screen (design
/// strip frames 45a/45e, flag (c)): `memoryValue` has been stored since
/// calc_sdk 1.0.1 and NOTHING has ever rendered it, so the four memory
/// keys have been operating blind — M+ with no confirmation, MR with no
/// idea what is about to arrive. The bar renders the value that was
/// already in state; it changes no notifier behaviour.
///
/// Full form (the tape plane, frame 45a): an amber-washed strip with an
/// `M` mark, the live value, and MC / MR / M- / M+ as four mini pills —
/// a second, reachable copy of the pad's memory row, which stays where
/// it has always been.
///
/// Compact form (the phone fold, frame 45e): the value alone, folded
/// into the header's count-pill slot. The fold drops no key — the pad's
/// own memory row is still there.
class CalcMemoryBar extends ConsumerWidget {
  const CalcMemoryBar({super.key, this.compact = false});

  final bool compact;

  static const List<String> keys = ['MC', 'MR', 'M-', 'M+'];

  Color get _wash => AppStyle.pendingDark.withValues(alpha: 0.12);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(calculatorProvider).memoryValue;
    final notifier = ref.read(calculatorProvider.notifier);
    final text = CalcFormat.number(value);

    if (compact) {
      return Container(
        key: const Key('calcMemoryPill'),
        padding: REdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _wash,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          'M  $text',
          style: AppStyle.interSemi(size: 13, color: AppStyle.pendingDark),
        ),
      );
    }

    return Container(
      key: const Key('calcMemoryBar'),
      padding: REdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _wash,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppStyle.pendingDark.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22.r,
                height: 22.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppStyle.pendingDark,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  'M',
                  style: AppStyle.interSemi(
                    size: 12,
                    color: AppStyle.blackColor,
                  ),
                ),
              ),
              10.horizontalSpace,
              Expanded(
                child: Text(
                  text,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyle.interSemi(
                    size: 17,
                    color: AppStyle.pendingDark,
                  ),
                ),
              ),
            ],
          ),
          10.verticalSpace,
          Row(
            children: [
              for (var i = 0; i < keys.length; i++) ...[
                if (i > 0) SizedBox(width: 6.r),
                Expanded(
                  child: GestureDetector(
                    key: Key('calcMemoryPill${keys[i]}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      // A key is a key: the mini pills sound exactly
                      // like the pad's own memory row.
                      KeySound.tap();
                      notifier.onMemoryPressed(keys[i]);
                    },
                    child: Container(
                      padding: REdgeInsets.symmetric(vertical: 6),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppStyle.cardDarkAlt,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: AppStyle.strokeDarkSubtle),
                      ),
                      child: Text(
                        keys[i],
                        style: AppStyle.interNormal(
                          size: 12,
                          color: AppStyle.pendingDark,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
