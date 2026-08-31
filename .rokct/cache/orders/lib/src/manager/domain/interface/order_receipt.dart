// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import 'package:get_it/get_it.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';

/// Narrow seam for REPRINTING an order's receipt (ADR-005).
///
/// Ray's amendment on approving frame 38a (2026-08-30 12:23Z): "receipt
/// reprint action in the order detail (wired to the till receipt path)".
/// The till receipt path is merchants_sdk's `PosReceiptPrinter` — the
/// checkout's hardware seam — and orders_sdk must not import
/// merchants_sdk, so it declares the reprint in its own terms here and
/// the manager host binds the two in
/// `templates/adapters/manager/orders_adapters.dart`.
///
/// [reprint] is the same ATOMIC contract the till's "Print Receipt &
/// Finish" uses: it completes only when the printer accepted the job, and
/// throws otherwise, so the caller can tell the user the reprint failed
/// instead of silently eating it.
abstract class OrderReceiptFacade {
  /// True when a printer is actually installed — the detail hides the
  /// reprint action rather than offering a button that cannot work.
  bool get isAvailable;

  /// Reprints [order]'s receipt through the till's printer.
  Future<void> reprint(OrderData order);
}

/// GetIt-or-stand-in resolution (the [PosCustomersFacade] pattern): an
/// unwired host reports no printer, so the action simply does not appear.
OrderReceiptFacade resolveOrderReceiptFacade() {
  final getIt = GetIt.instance;
  return getIt.isRegistered<OrderReceiptFacade>()
      ? getIt<OrderReceiptFacade>()
      : const _UnwiredOrderReceipt();
}

class _UnwiredOrderReceipt implements OrderReceiptFacade {
  const _UnwiredOrderReceipt();

  @override
  bool get isAvailable => false;

  @override
  Future<void> reprint(OrderData order) async {
    throw StateError(
      'No OrderReceiptFacade is registered: the host app has not '
      'installed/wired orders_adapters.dart to the till receipt path.',
    );
  }
}
