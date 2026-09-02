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

import 'package:flutter/foundation.dart';

/// One printed receipt line.
class PosReceiptLine {
  const PosReceiptLine({
    required this.title,
    required this.quantity,
    required this.lineTotal,
  });

  final String title;
  final double quantity;
  final double lineTotal;
}

/// The checkout's receipt-printing seam.
///
/// "Print Receipt & Finish" is ATOMIC: the checkout awaits [print] and
/// only records the finish when it returns — a throwing handler leaves the
/// sale open (the retired Spazafy checkout printed after recording, so a
/// dead printer silently ate receipts). The default handler is a debug
/// no-op; a composed app with printing hardware (58mm bluetooth thermal,
/// per the old Quick Receipt app) installs its own via [handler].
class PosReceiptPrinter {
  PosReceiptPrinter._();

  /// Composed-app seam: install the real hardware printer here (di_hook /
  /// boot_hook territory). Tests install throwing/recording fakes.
  static Future<void> Function(
    String orderId,
    List<PosReceiptLine> lines,
    double total,
  )? handler;

  static Future<void> print(
    String orderId,
    List<PosReceiptLine> lines,
    double total,
  ) async {
    final h = handler;
    if (h != null) {
      await h(orderId, lines, total);
      return;
    }
    debugPrint(
      '==> POS receipt (no printer installed): $orderId, '
      '${lines.length} lines, total $total',
    );
  }
}
