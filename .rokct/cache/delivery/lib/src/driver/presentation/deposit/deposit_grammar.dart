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

/// Shared vocabulary of the deposit screens (frames 49g/49h/49i): the
/// arithmetic and wording rules with no widgets in them, so each is
/// unit-tested. Mirrors revenue_sdk's `wallet_grammar.dart` for the money
/// facts the two SDKs share, without importing it (ADR-005).
library;

import 'dart:ui';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';

import 'package:delivery_sdk/src/driver/infrastructure/models/data/deposit_request.dart';

/// Which sentence the balance head speaks. **The balance is a sentence,
/// not a signed number** (section 49 ruling 11): "You owe R 1,240.00",
/// never "−1,240".
enum BalanceTone { owing, empty, available }

BalanceTone toneFor(num balance) {
  if (balance < 0) return BalanceTone.owing;
  if (balance == 0) return BalanceTone.empty;
  return BalanceTone.available;
}

/// The translation key of the line that leads the balance figure. Chosen
/// so a backend with no row seeded for it still humanizes to the approved
/// English (`AppHelpers.humanizeTrKey`).
String balanceLeadKey(BalanceTone tone) {
  switch (tone) {
    case BalanceTone.owing:
      return 'you_owe';
    case BalanceTone.empty:
      return 'your_wallet_is_clear';
    case BalanceTone.available:
      return 'you_have';
  }
}

/// A deposit status as the row chip renders it: label key and colour.
class DepositStatusView {
  const DepositStatusView(this.labelKey, this.color);

  final String labelKey;
  final Color color;

  /// The chip's fill: the status colour laid faintly over the surface, so
  /// it follows the theme instead of pinning a dark-only hex.
  Color get background =>
      Color.lerp(AppStyle.surfaceDark, color, 0.20) ?? color;
}

DepositStatusView depositStatusView(DepositStatus status) {
  switch (status) {
    case DepositStatus.pending:
      return const DepositStatusView('under_review', AppStyle.rate);
    case DepositStatus.approved:
      return const DepositStatusView('approved', AppStyle.green);
    case DepositStatus.rejected:
      return const DepositStatusView('rejected', AppStyle.red);
    case DepositStatus.draft:
      return DepositStatusView('draft', AppStyle.textDarkSecondary);
    case DepositStatus.unknown:
      return DepositStatusView('', AppStyle.textDarkSecondary);
  }
}

/// How a row dates itself.
enum DepositDay { today, yesterday, earlier }

DepositDay classifyDay(DateTime at, DateTime now) {
  final day = DateTime(at.year, at.month, at.day);
  final todayStart = DateTime(now.year, now.month, now.day);
  final difference = todayStart.difference(day).inDays;
  if (difference <= 0) return DepositDay.today;
  if (difference == 1) return DepositDay.yesterday;
  return DepositDay.earlier;
}

/// Chip 977 — the reference SUGGESTED for the driver rather than asked of
/// him: initials, day, minute (`TM-0831-1642`). The server generates the
/// same shape when the client sends none; this exists so the slip can be
/// written BEFORE the request is sent. The format is a suggestion the frame
/// flagged, not a ruling.
String suggestedReference(String? fullName, DateTime when) {
  final parts = (fullName ?? '')
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .map((p) => p[0])
      .join()
      .replaceAll(RegExp(r'[^A-Za-z]'), '')
      .toUpperCase();
  final initials = parts.isEmpty ? 'DEP' : parts.substring(0, parts.length > 3 ? 3 : parts.length);
  String two(int n) => n.toString().padLeft(2, '0');
  return '$initials-${two(when.month)}${two(when.day)}-${two(when.hour)}${two(when.minute)}';
}

/// "Today 16:42", "Yesterday 09:10", "31 Aug 16:42" — how a row dates
/// itself (chips 979/982). The day words are translation keys so a locale
/// row can replace them; the rest is digits.
String describeWhen(DateTime at, DateTime now) {
  final local = at.isUtc ? at.toLocal() : at;
  String two(int n) => n.toString().padLeft(2, '0');
  final time = '${two(local.hour)}:${two(local.minute)}';
  switch (classifyDay(local, now)) {
    case DepositDay.today:
      return '${AppHelpers.getTranslation('today')} $time';
    case DepositDay.yesterday:
      return '${AppHelpers.getTranslation('yesterday')} $time';
    case DepositDay.earlier:
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      final year = local.year == now.year ? '' : ' ${local.year}';
      return '${local.day} ${months[local.month - 1]}$year $time';
  }
}
