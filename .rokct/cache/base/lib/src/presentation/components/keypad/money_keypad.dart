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

// THE KEY PAD (design chip 390) — the fleet's standard money-entry
// surface, approved on frame 11u (tablet checkout, 2026-08-29 15:41Z)
// and frame 11y (phone fold, 2026-08-30 11:27Z). Ray's standing
// direction: this keypad is the standard money-entry surface fleet-wide
// (checkout today; delivery, wallet and the calculator adopt it later),
// which is why it lives in base_sdk, the package every app composes
// (the TelemetryClient precedent, ADR-005/006).
//
// Layout per the approved frames (paas_pos order_calculate lineage):
//   1 2 3 / 4 5 6 / 7 8 9 / 00 0 ⌫   — the digits grid, with the money
//   `00` key carried from the paas_pos tender pad;
//   .  |  OK                          — the confirm row (the `.` key at
//   flex 1, OK at flex 2), shown when the caller wires [onDecimal] /
//   [onOk].
//
// Every keypress plays the fleet key feedback (KeySound.tap — tap.wav
// through the round-robin player pool plus a light haptic on touch
// platforms, behind the persisted default-ON gate) so every adopter
// sounds the same without wiring anything.
//
// The pad is a PURE INPUT SURFACE: it emits key events and never owns
// text semantics — the [MoneyEntry] helpers give adopters the shared
// append/backspace/decimal editing rules so money strings behave the
// same fleet-wide. It never focuses anything, so the OS keyboard can
// never appear behind it (the 11y ruling: OUR keypad shows on phone,
// the amount display never summons the OS keyboard).

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:remixicon/remixicon.dart';

import '../../../services/key_sound.dart';
import '../../theme/app_style.dart';

class MoneyKeypad extends StatelessWidget {
  const MoneyKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.onDecimal,
    this.onOk,
    this.okLabel = 'OK',
    this.keyHeight,
    this.gap,
  });

  /// Fired with '1'–'9', '0' or '00'.
  final ValueChanged<String> onDigit;

  final VoidCallback onBackspace;

  /// Wires the confirm row's `.` key; the row renders when either
  /// [onDecimal] or [onOk] is non-null.
  final VoidCallback? onDecimal;

  /// Wires the confirm row's OK key (its meaning belongs to the caller —
  /// checkout normalizes the entry; a dialog adopter would pop).
  final VoidCallback? onOk;

  /// OK renders as a glyph-like literal, deliberately untranslated (the
  /// calc_sdk precedent: keypads render glyphs and numbers only).
  final String okLabel;

  /// Row height; defaults to 52.r (the 11y phone render's hand scale —
  /// at plane widths the keys simply grow WIDER, per 11u's two-plane
  /// spread).
  final double? keyHeight;

  /// Gap between keys; defaults to 8.r (the approved renders' gutter).
  final double? gap;

  static const List<String> _grid = [
    '1', '2', '3', //
    '4', '5', '6', //
    '7', '8', '9', //
    '00', '0', '⌫',
  ];

  @override
  Widget build(BuildContext context) {
    final double h = keyHeight ?? 52.r;
    final double g = gap ?? 8.r;
    final bool confirmRow = onDecimal != null || onOk != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var row = 0; row < 4; row++) ...[
          if (row > 0) SizedBox(height: g),
          SizedBox(
            height: h,
            child: Row(
              children: [
                for (var col = 0; col < 3; col++) ...[
                  if (col > 0) SizedBox(width: g),
                  Expanded(child: _gridKey(_grid[row * 3 + col])),
                ],
              ],
            ),
          ),
        ],
        if (confirmRow) ...[
          SizedBox(height: g),
          SizedBox(
            height: h,
            child: Row(
              children: [
                Expanded(
                  child: onDecimal == null
                      ? const SizedBox.shrink()
                      : _key(
                          keyId: 'moneyKeyDecimal',
                          onTap: onDecimal!,
                          child: _label('.'),
                        ),
                ),
                SizedBox(width: g),
                Expanded(
                  flex: 2,
                  child: onOk == null
                      ? const SizedBox.shrink()
                      : _key(
                          keyId: 'moneyKeyOk',
                          onTap: onOk!,
                          fill: AppStyle.primary,
                          border: Colors.transparent,
                          child: Text(
                            okLabel,
                            style: AppStyle.interSemi(
                              size: 17,
                              color: AppStyle.blackColor,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _gridKey(String label) {
    if (label == '⌫') {
      return _key(
        keyId: 'moneyKeyBackspace',
        onTap: onBackspace,
        child: Icon(Remix.delete_back_2_line, size: 20.r, color: AppStyle.red),
      );
    }
    return _key(
      keyId: 'moneyKey$label',
      onTap: () => onDigit(label),
      child: _label(label),
    );
  }

  Widget _label(String text) =>
      Text(text, style: AppStyle.interSemi(size: 19));

  Widget _key({
    required String keyId,
    required VoidCallback onTap,
    required Widget child,
    Color? fill,
    Color? border,
  }) {
    return GestureDetector(
      key: Key(keyId),
      behavior: HitTestBehavior.opaque,
      onTap: () {
        KeySound.tap();
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          color: fill ?? AppStyle.cardDarkAlt,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: border ?? AppStyle.strokeDarkSubtle,
            width: 1.r,
          ),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

/// The shared money-string editing rules, so every adopter's amount
/// entry behaves identically (paas_pos tender-pad semantics):
/// digits/`00` append (a bare leading '0' is replaced, and `00` on an
/// empty/zero entry stays '0'), one decimal point, at most two cents
/// digits, backspace removes the last character.
class MoneyEntry {
  MoneyEntry._();

  static const int _maxIntegerDigits = 9;

  static String appendDigit(String current, String digit) {
    assert(digit == '00' || (digit.length == 1 && '0123456789'.contains(digit)),
        'not a keypad digit: $digit');
    final dot = current.indexOf('.');
    if (dot >= 0) {
      // Cents: cap at two digits after the point.
      final cents = current.length - dot - 1;
      if (cents >= 2) return current;
      if (digit == '00') {
        return cents >= 1 ? '${current}0' : '${current}00';
      }
      return current + digit;
    }
    if (current == '0' || current.isEmpty) {
      if (digit == '00' || digit == '0') return '0';
      return digit;
    }
    if (current.length >= _maxIntegerDigits) return current;
    if (digit == '00' && current.length + 2 > _maxIntegerDigits) {
      return current;
    }
    return current + digit;
  }

  static String backspace(String current) =>
      current.isEmpty ? current : current.substring(0, current.length - 1);

  static String decimal(String current) {
    if (current.contains('.')) return current;
    return current.isEmpty ? '0.' : '$current.';
  }
}
