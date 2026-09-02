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

// THE CALC KEY TILE — the shared key DRESS, not the shared layout
// (design strip section 45, inset frame 45f).
//
// 45f draws the line explicitly. SAFE to share with the fleet keypad
// (chip 390, base_sdk's MoneyKeypad): the key TILE itself — cardDarkAlt
// fill, a strokeDarkSubtle hairline, a 10r radius, an interSemi 19
// label, an OPAQUE hit test — and `KeySound.tap()` on every press. NOT
// shared, because it would break 390's approved contract: the digit
// ORDER. 390 is 1-2-3-first (money order); the calculator is
// 7-8-9-first (desktop order) and owns an operator column 390 has no
// room for. They share dress, not layout.
//
// Adopting the dress is what closes the silent-pad flag: `KeySound`
// ships in base_sdk (tap.wav through a round-robin player pool plus a
// light haptic, behind one persisted default-ON gate that fails open),
// MoneyKeypad has called it on every press since base_sdk 1.44.0, and
// until now the calculator was the one keypad in the fleet still
// silent. The sound lives in the tile, so wearing the tile buys it.
//
// FOLLOW-UP (deliberately not done here): the identical tile body also
// lives in base_sdk's `MoneyKeypad._key`. Promoting it to one shared
// base_sdk widget changes no caller and deletes this duplicate — it is
// a base_sdk change, so it lands with the next base_sdk release rather
// than from this SDK.

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/key_sound.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// What a calculator key is for — the ONLY thing that varies between
/// tiles, and the whole of the re-tokening that frame 45a asks for
/// (flag (b): the shipped view painted four raw hex constants and was
/// the last screen in the fleet off [AppStyle]).
enum CalcKeyKind {
  /// Digits and `.` — the plain tile, identical to a MoneyKeypad key.
  digit,

  /// MC / MR / M- / M+ — was the raw `0xFFFF5A66` accent.
  memory,

  /// C / ± / % — was the raw `0xFF26F4CE` function teal.
  function,

  /// ÷ × - + and = — was the raw accent FILL; now the same filled
  /// treatment MoneyKeypad gives its OK key.
  operator,
}

/// One key of the calculator pad, wearing the fleet key tile.
///
/// Every press plays [KeySound.tap] — the tap.wav click plus a light
/// haptic on touch platforms, behind base_sdk's persisted default-ON
/// gate. The service fails open: a host without the audio assets, or a
/// widget test without the platform channel, gets silence and never an
/// exception.
class CalcKey extends StatelessWidget {
  const CalcKey({
    super.key,
    required this.label,
    required this.onTap,
    this.kind = CalcKeyKind.digit,
    this.onDoubleTap,
    this.flex = 1,
  });

  /// The glyph. Deliberately untranslated — calc_sdk declares no
  /// tr_keys: the pad renders keypad glyphs and numbers only.
  final String label;

  final VoidCallback onTap;

  final CalcKeyKind kind;

  /// The shipped double-tap-on-C history wipe. Kept exactly as it was
  /// (frame 45a: "the gesture stays") — chip 841 makes it findable, it
  /// does not replace it.
  final VoidCallback? onDoubleTap;

  /// Row share; the `0` key takes 2 (the shipped last row).
  final int flex;

  Color get _fill =>
      kind == CalcKeyKind.operator ? AppStyle.primary : AppStyle.cardDarkAlt;

  Color get _border => kind == CalcKeyKind.operator
      ? Colors.transparent
      : AppStyle.strokeDarkSubtle;

  Color get _ink => switch (kind) {
        CalcKeyKind.digit => AppStyle.textPrimary,
        CalcKeyKind.memory => AppStyle.primary,
        CalcKeyKind.function => AppStyle.green,
        CalcKeyKind.operator => AppStyle.blackColor,
      };

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: GestureDetector(
        key: Key('calcKey$label'),
        behavior: HitTestBehavior.opaque,
        onTap: () {
          KeySound.tap();
          onTap();
        },
        onDoubleTap: onDoubleTap == null
            ? null
            : () {
                KeySound.tap();
                onDoubleTap!();
              },
        child: Container(
          decoration: BoxDecoration(
            color: _fill,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: _border, width: 1.r),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppStyle.interSemi(size: 19, color: _ink),
          ),
        ),
      ),
    );
  }
}
