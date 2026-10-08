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

// ONE LOAD, in full: who it went to, the line table (issued / sold /
// returned / remaining at the load's own unit price) and — while it is
// open — the one action the shop has, Close.
//
// CLOSING IS A MONEY ACTION. Issued minus sold minus returned is the
// driver's variance, and closing charges it to his wallet at the load's
// unit prices. The confirm dialog therefore NAMES THE AMOUNT before the
// shop commits, and says plainly when the amount is nothing. The shop may
// close without the driver; the backend is idempotent, so the driver
// pressing Close on his own app afterwards charges nothing twice.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:orders_sdk/src/manager/application/loads/shop_loads_provider.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/data/load_data.dart';

import 'load_keys.dart';
import 'loads_list.dart';

/// The detail surface for one load. The same widget serves the plane pane
/// and the phone sheet.
class LoadDetail extends ConsumerStatefulWidget {
  final LoadData load;

  /// Called with the closed load once a Close lands, so the host can tell
  /// the shop what was charged and fold the pane if it wants to.
  final void Function(LoadData closed)? onClosed;

  const LoadDetail({super.key, required this.load, this.onClosed});

  @override
  ConsumerState<LoadDetail> createState() => _LoadDetailState();
}

class _LoadDetailState extends ConsumerState<LoadDetail> {
  late LoadData _load = widget.load;

  @override
  void didUpdateWidget(covariant LoadDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.load.id != widget.load.id) _load = widget.load;
  }

  Future<void> _confirmClose() async {
    final bool? go = await showLoadCloseConfirmDialog(context, _load);
    if (go != true || !mounted) return;
    final LoadData? closed = await ref
        .read(shopLoadsProvider.notifier)
        .closeLoad(_load.id);
    if (!mounted) return;
    if (closed == null) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(AppHelpers.getTranslation(LoadKeys.couldNotCloseLoad)),
        ),
      );
      return;
    }
    setState(() => _load = closed);
    widget.onClosed?.call(closed);
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(_closedMessage(closed))),
    );
  }

  String _closedMessage(LoadData closed) {
    if (closed.alreadyClosed) {
      return AppHelpers.getTranslation(LoadKeys.loadWasAlreadyClosed);
    }
    final num charged =
        closed.totals?.varianceCharged ?? closed.varianceAmount;
    if (charged <= 0) {
      return AppHelpers.getTranslation(LoadKeys.loadClosed);
    }
    return '${AppHelpers.getTranslation(LoadKeys.loadClosed)} · '
        '${AppHelpers.numberFormat(number: charged)} '
        '${AppHelpers.getTranslation(LoadKeys.willBeChargedToTheDriversWallet)}';
  }

  @override
  Widget build(BuildContext context) {
    final bool closing = ref.watch(shopLoadsProvider).closingId == _load.id;
    final num variance = _load.totals?.varianceAmount ?? _load.varianceAmount;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      physics: const BouncingScrollPhysics(),
      children: [
        Text(
          _load.deliveryman?.name ?? _load.id,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppStyle.interSemi(size: 22, color: AppStyle.inkFor(Theme.of(context).brightness)),
        ),
        const SizedBox(height: 6),
        Text(
          _subtitle(),
          style: AppStyle.interNormal(
            size: 12,
            color: AppStyle.secondaryInkFor(Theme.of(context).brightness),
          ),
        ),
        const SizedBox(height: 18),
        LoadLinesTable(load: _load),
        const SizedBox(height: 18),
        if (_load.isClosed)
          _VarianceSummary(load: _load, amount: variance)
        else
          _CloseAction(onTap: closing ? null : _confirmClose, busy: closing),
      ],
    );
  }

  String _subtitle() {
    final parts = <String>[];
    final DateTime? created = _load.createdAt;
    if (created != null) {
      parts.add(
        '${AppHelpers.getTranslation(LoadKeys.issuedOn)} '
        '${DateFormat('d MMM yyyy · HH:mm').format(created)}',
      );
    }
    final DateTime? closed = _load.closedAt;
    if (closed != null) {
      parts.add(
        '${AppHelpers.getTranslation(LoadKeys.closedOn)} '
        '${DateFormat('d MMM yyyy · HH:mm').format(closed)}',
      );
    }
    parts.add(
      '${_load.lines.length} '
      '${AppHelpers.getTranslation(LoadKeys.linesOnLoad).toLowerCase()}',
    );
    return parts.join(' · ');
  }
}

/// The line table: one row per product with the four quantities, the unit
/// price and — once the load is closed — what the shortfall on that line
/// was worth.
class LoadLinesTable extends StatelessWidget {
  final LoadData load;

  const LoadLinesTable({super.key, required this.load});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppStyle.cardFor(Theme.of(context).brightness),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppStyle.subtleStrokeFor(Theme.of(context).brightness)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _headerRow(),
          for (final line in load.lines) ...[
            Divider(height: 18, color: AppStyle.subtleStrokeFor(Theme.of(context).brightness)),
            _lineRow(line),
          ],
        ],
      ),
    );
  }

  Widget _headerRow() {
    Widget cell(String key) => Expanded(
      child: Text(
        AppHelpers.getTranslation(key),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.end,
        style: AppStyle.interNormal(size: 11, color: AppStyle.textDarkFaint),
      ),
    );
    return Row(
      children: [
        Expanded(flex: 3, child: const SizedBox.shrink()),
        cell(LoadKeys.issued),
        cell(LoadKeys.sold),
        cell(LoadKeys.returned),
        cell(LoadKeys.remaining),
      ],
    );
  }

  Widget _lineRow(LoadLine line) {
    Widget cell(num value, {Color? color}) => Expanded(
      child: Text(
        formatLoadQuantity(value),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.end,
        style: AppStyle.interSemi(
          size: 13,
          color: color ?? AppStyle.textPrimary,
        ),
      ),
    );
    final num variance = line.varianceQty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                line.product.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppStyle.interSemi(
                  size: 13,
                  color: AppStyle.textPrimary,
                ),
              ),
            ),
            cell(line.issuedQty),
            cell(line.soldQty),
            cell(line.returnedQty),
            cell(
              line.remainingQty,
              color: line.remainingQty > 0
                  ? AppStyle.primary
                  : AppStyle.textDarkSecondary,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          load.isClosed && variance > 0
              ? '${AppHelpers.getTranslation(LoadKeys.unitPrice)} '
                    '${AppHelpers.numberFormat(number: line.unitPrice)} · '
                    '${AppHelpers.getTranslation(LoadKeys.varianceValue)} '
                    '${AppHelpers.numberFormat(number: line.varianceAmount)}'
              : '${AppHelpers.getTranslation(LoadKeys.unitPrice)} '
                    '${AppHelpers.numberFormat(number: line.unitPrice)}',
          style: AppStyle.interNormal(
            size: 11,
            color: load.isClosed && variance > 0
                ? AppStyle.red
                : AppStyle.textDarkSecondary,
          ),
        ),
      ],
    );
  }
}

/// A closed load says what it cost the driver, and when it closed —
/// nothing more; there is no action left on it.
class _VarianceSummary extends StatelessWidget {
  final LoadData load;
  final num amount;

  const _VarianceSummary({required this.load, required this.amount});

  @override
  Widget build(BuildContext context) {
    final num charged = load.totals?.varianceCharged ?? amount;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppStyle.cardAltFor(Theme.of(context).brightness),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppStyle.subtleStrokeFor(Theme.of(context).brightness)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppHelpers.getTranslation(LoadKeys.variance),
            style: AppStyle.interNormal(
              size: 12,
              color: AppStyle.secondaryInkFor(Theme.of(context).brightness),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppHelpers.numberFormat(number: charged),
            style: AppStyle.interSemi(
              size: 20,
              color: charged > 0 ? AppStyle.red : AppStyle.inkFor(Theme.of(context).brightness),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            charged > 0
                ? AppHelpers.getTranslation(
                    LoadKeys.willBeChargedToTheDriversWallet,
                  )
                : AppHelpers.getTranslation(
                    LoadKeys.nothingIsMissingSoNothingIsCharged,
                  ),
            style: AppStyle.interNormal(
              size: 12,
              color: AppStyle.secondaryInkFor(Theme.of(context).brightness),
            ),
          ),
        ],
      ),
    );
  }
}

class _CloseAction extends StatelessWidget {
  final VoidCallback? onTap;
  final bool busy;

  const _CloseAction({required this.onTap, required this.busy});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppStyle.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    AppHelpers.getTranslation(LoadKeys.closeLoad),
                    style: AppStyle.interSemi(
                      size: 15,
                      color: AppStyle.blackColor,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppHelpers.getTranslation(LoadKeys.closingChargesTheDriver),
          textAlign: TextAlign.center,
          style: AppStyle.interNormal(
            size: 11,
            color: AppStyle.secondaryInkFor(Theme.of(context).brightness),
          ),
        ),
      ],
    );
  }
}

/// The confirm dialog. It states the variance amount that closing will
/// charge to the driver's wallet — the whole point of the guard — and says
/// so plainly when there is nothing to charge.
Future<bool?> showLoadCloseConfirmDialog(BuildContext context, LoadData load) {
  final num amount = load.varianceAmount;
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppStyle.cardFor(Theme.of(context).brightness),
      title: Text(
        AppHelpers.getTranslation(LoadKeys.closeLoad),
        style: AppStyle.interSemi(size: 17, color: AppStyle.inkFor(Theme.of(context).brightness)),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppHelpers.getTranslation(LoadKeys.closingChargesTheDriver),
            style: AppStyle.interNormal(
              size: 13,
              color: AppStyle.secondaryInkFor(Theme.of(context).brightness),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            amount > 0
                ? AppHelpers.numberFormat(number: amount)
                : AppHelpers.getTranslation(
                    LoadKeys.nothingIsMissingSoNothingIsCharged,
                  ),
            style: AppStyle.interSemi(
              size: amount > 0 ? 22 : 13,
              color: amount > 0 ? AppStyle.red : AppStyle.inkFor(Theme.of(context).brightness),
            ),
          ),
          if (amount > 0) ...[
            const SizedBox(height: 6),
            Text(
              '${formatLoadQuantity(load.varianceQty)} · '
              '${AppHelpers.getTranslation(LoadKeys.willBeChargedToTheDriversWallet)}',
              style: AppStyle.interNormal(
                size: 12,
                color: AppStyle.secondaryInkFor(Theme.of(context).brightness),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            AppHelpers.getTranslation('cancel'),
            style: AppStyle.interNormal(
              size: 14,
              color: AppStyle.secondaryInkFor(Theme.of(context).brightness),
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            AppHelpers.getTranslation(LoadKeys.closeLoadAndCharge),
            style: AppStyle.interSemi(size: 14, color: AppStyle.primary),
          ),
        ),
      ],
    ),
  );
}
