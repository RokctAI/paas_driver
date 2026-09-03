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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:remixicon/remixicon.dart';

import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/components/floating_nav/floating_bottom_nav.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

import 'package:delivery_sdk/src/driver/application/deposit/deposit_provider.dart';
import 'package:delivery_sdk/src/driver/application/deposit/deposit_state.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/deposit_request.dart';
import 'package:delivery_sdk/src/driver/presentation/deposit/deposit_flow.dart';
import 'package:delivery_sdk/src/driver/presentation/deposit/deposit_grammar.dart';

/// Frame 49i — the deposit status plane.
///
/// What the driver sees AFTER "Send for approval", and whenever he comes
/// back to ask "where is my deposit?":
///
///   * chip 971 — the wallet as the ledger holds it, as a SENTENCE ("You
///     owe R 1,240.00"), with one honest line under it while a request is
///     live: the figure is unchanged until a person approves. Nothing on
///     this plane ever nets the pending amount into the balance;
///   * chip 979 — the live request: amount, reference, when it was sent;
///   * chip 980 — the trail Submitted · Under review · Approved, the
///     current step lit;
///   * chip 982 — his earlier deposits, newest first; a rejected row carries
///     the reason it was refused (chip 981) so he knows what to fix;
///   * an explainer card, because the wait is a person matching a slip to
///     a bank statement and the driver deserves to know that;
///   * chip 347 — the canonical back pill, bottom-end corner.
///
/// There is no deadline, no due date and no "deposit before your next
/// shift" anywhere here: nothing in the fleet backs a deposit obligation
/// (section 49 ruling), and the copy must never regrow one.
class DriverDepositStatusPlane extends ConsumerStatefulWidget {
  const DriverDepositStatusPlane({
    super.key,
    this.openChooserOnStart = false,
    this.now,
  });

  /// True when the plane was reached with `?choose=1` (the wallet plane's
  /// Top up pill, corporate 49f): the method chooser (49g) opens over it
  /// on the first frame.
  final bool openChooserOnStart;

  /// Injectable clock for the day labels; null reads the wall clock.
  final DateTime? now;

  /// Pushes the plane over the whole shell (root navigator = the nav fold).
  static Future<void> push(BuildContext context) {
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => const DriverDepositStatusPlane()),
    );
  }

  @override
  ConsumerState<DriverDepositStatusPlane> createState() =>
      _DriverDepositStatusPlaneState();
}

class _DriverDepositStatusPlaneState
    extends ConsumerState<DriverDepositStatusPlane> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await ref.read(depositProvider.notifier).load(context: context);
      if (widget.openChooserOnStart && mounted) {
        await DriverDepositFlow.openChooser(context, ref, onSubmitted: (_) {});
      }
    });
  }

  DateTime get _now => widget.now ?? DateTime.now();

  Future<void> _makeDeposit() =>
      DriverDepositFlow.openChooser(context, ref, onSubmitted: (_) {
        // The plane already holds the row just sent (the slice keeps it);
        // a re-read makes the list the server's word.
        if (mounted) ref.read(depositProvider.notifier).load(context: context);
      });

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(depositProvider);
    final live = state.liveDeposit;
    return Scaffold(
      backgroundColor: AppStyle.surfaceDark,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: RefreshIndicator(
                color: AppStyle.primary,
                onRefresh: () =>
                    ref.read(depositProvider.notifier).load(context: context),
                child: ListView(
                  key: const Key('depositStatusPlane'),
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 92.h),
                  children: [
                    Text(
                      AppHelpers.getTranslation('deposits'),
                      style: AppStyle.interSemi(size: 21),
                    ),
                    20.verticalSpace,
                    _BalanceHead(
                      balance: state.balance,
                      failed: state.balanceFailed,
                      pendingLive: live != null,
                    ),
                    20.verticalSpace,
                    if (live != null) ...[
                      _PendingCard(record: live, now: _now),
                      12.verticalSpace,
                      _StatusTrail(status: live.status),
                      20.verticalSpace,
                    ],
                    CustomButton(
                      key: const Key('depositMakeDeposit'),
                      title: AppHelpers.getTranslation('make_a_deposit'),
                      background: AppStyle.primary,
                      textColor: AppStyle.blackColor,
                      onPressed: _makeDeposit,
                    ),
                    24.verticalSpace,
                    _ExplainerCard(),
                    24.verticalSpace,
                    Text(
                      AppHelpers.getTranslation('your_deposits').toUpperCase(),
                      style: AppStyle.interSemi(
                        size: 10.5,
                        letterSpacing: 1.2,
                        color: AppStyle.textDarkSecondary,
                      ),
                    ),
                    12.verticalSpace,
                    _History(state: state, now: _now),
                  ],
                ),
              ),
            ),
            // Chip 347: the canonical back pill, bottom-end corner, no nav.
            PositionedDirectional(
              end: 16,
              bottom: 16,
              child: FloatingBackPill(
                back: FloatingNavBack(
                  icon: Remix.arrow_left_s_line,
                  label: AppHelpers.getTranslation(TrKeys.back),
                  onTap: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chip 971 — the balance as a sentence, and the honest line under it.
class _BalanceHead extends StatelessWidget {
  const _BalanceHead({
    required this.balance,
    required this.failed,
    required this.pendingLive,
  });

  final num? balance;
  final bool failed;
  final bool pendingLive;

  @override
  Widget build(BuildContext context) {
    final value = balance;
    return Container(
      key: const Key('depositBalanceHead'),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppStyle.cardDark,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppStyle.strokeDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (value == null)
            Text(
              failed
                  ? AppHelpers.getTranslation('we_couldnt_read_your_wallet')
                  : AppHelpers.getTranslation('reading_your_wallet'),
              style: AppStyle.interRegular(
                size: 13,
                color: AppStyle.textDarkSecondary,
              ),
            )
          else ...[
            Text(
              AppHelpers.getTranslation(balanceLeadKey(toneFor(value))),
              style: AppStyle.interRegular(
                size: 13,
                color: AppStyle.textDarkSecondary,
              ),
            ),
            4.verticalSpace,
            Text(
              AppHelpers.numberFormat(number: value.abs()),
              key: const Key('depositBalanceFigure'),
              style: AppStyle.interSemi(size: 28),
            ),
          ],
          if (pendingLive) ...[
            8.verticalSpace,
            Text(
              AppHelpers.getTranslation(
                'unchanged_until_your_deposit_is_approved',
              ),
              key: const Key('depositBalanceUnchangedLine'),
              style: AppStyle.interRegular(
                size: 11.5,
                color: AppStyle.textDarkFaint,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Chip 979 — the request that is live right now.
class _PendingCard extends StatelessWidget {
  const _PendingCard({required this.record, required this.now});

  final DepositRecord record;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final view = depositStatusView(record.status);
    return Container(
      key: const Key('depositPendingCard'),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppStyle.cardDarkAlt,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppStyle.strokeDarkSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${AppHelpers.getTranslation('deposit_of')} '
                  '${AppHelpers.numberFormat(number: record.amount)}',
                  style: AppStyle.interSemi(size: 15),
                ),
              ),
              _StatusChip(view: view),
            ],
          ),
          if ((record.reference ?? '').isNotEmpty) ...[
            6.verticalSpace,
            Text(
              '${AppHelpers.getTranslation('reference')} ${record.reference}',
              key: const Key('depositPendingReference'),
              style: AppStyle.interRegular(
                size: 12,
                color: AppStyle.textDarkSecondary,
              ),
            ),
          ],
          if (record.submittedAt != null) ...[
            4.verticalSpace,
            Text(
              '${AppHelpers.getTranslation('submitted')} '
              '${describeWhen(record.submittedAt!, now)}',
              style: AppStyle.interRegular(
                size: 12,
                color: AppStyle.textDarkSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Chip 980 — Submitted · Under review · Approved. The steps a request
/// walks; the current one lit, the ones behind it done.
class _StatusTrail extends StatelessWidget {
  const _StatusTrail({required this.status});

  final DepositStatus status;

  static const _steps = ['submitted', 'under_review', 'approved'];

  int get _reached {
    switch (status) {
      case DepositStatus.draft:
        return 0;
      case DepositStatus.pending:
        return 1;
      case DepositStatus.approved:
        return 2;
      case DepositStatus.rejected:
      case DepositStatus.unknown:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reached = _reached;
    return Row(
      key: const Key('depositStatusTrail'),
      children: [
        for (var i = 0; i < _steps.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2.r,
                color: i <= reached ? AppStyle.primary : AppStyle.strokeDark,
              ),
            ),
          _TrailStep(
            labelKey: _steps[i],
            state: i < reached
                ? _StepState.done
                : i == reached
                    ? _StepState.current
                    : _StepState.ahead,
          ),
        ],
      ],
    );
  }
}

enum _StepState { done, current, ahead }

class _TrailStep extends StatelessWidget {
  const _TrailStep({required this.labelKey, required this.state});

  final String labelKey;
  final _StepState state;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _StepState.done => AppStyle.primary,
      _StepState.current => AppStyle.rate,
      _StepState.ahead => AppStyle.textDarkFaint,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          switch (state) {
            _StepState.done => Remix.checkbox_circle_fill,
            _StepState.current => Remix.time_fill,
            _StepState.ahead => Remix.checkbox_blank_circle_line,
          },
          size: 18.r,
          color: color,
        ),
        4.verticalSpace,
        Text(
          AppHelpers.getTranslation(labelKey),
          style: AppStyle.interRegular(size: 11, color: color),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.view});

  final DepositStatusView view;

  @override
  Widget build(BuildContext context) {
    if (view.labelKey.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.r, vertical: 4.r),
      decoration: BoxDecoration(
        color: view.background,
        borderRadius: BorderRadius.circular(100.r),
      ),
      child: Text(
        AppHelpers.getTranslation(view.labelKey),
        style: AppStyle.interSemi(size: 11, color: view.color),
      ),
    );
  }
}

/// Why the wait: a person matches the slip to the bank statement.
class _ExplainerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('depositExplainer'),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppStyle.cardDark,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppStyle.strokeDarkSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Remix.information_line, size: 18.r, color: AppStyle.rate),
          10.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppHelpers.getTranslation('how_this_works'),
                  style: AppStyle.interSemi(size: 12.5),
                ),
                4.verticalSpace,
                Text(
                  AppHelpers.getTranslation(
                    'a_person_checks_your_slip_against_the_bank_statement_once_approved_the_amount_is_added_to_your_wallet',
                  ),
                  style: AppStyle.interRegular(
                    size: 12,
                    color: AppStyle.textDarkSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip 982 — earlier deposits, newest first; chip 981 under a refusal.
class _History extends StatelessWidget {
  const _History({required this.state, required this.now});

  final DepositState state;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingDeposits && !state.depositsLoadedOnce) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 24.h),
        child: Center(
          child: SizedBox(
            width: 20.r,
            height: 20.r,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppStyle.primary,
            ),
          ),
        ),
      );
    }
    if (state.depositsFailed && state.deposits.isEmpty) {
      return Text(
        AppHelpers.getTranslation('we_couldnt_load_your_deposits'),
        key: const Key('depositHistoryFailed'),
        style: AppStyle.interRegular(
          size: 12.5,
          color: AppStyle.textDarkSecondary,
        ),
      );
    }
    if (state.deposits.isEmpty) {
      return Text(
        AppHelpers.getTranslation('no_deposits_yet'),
        key: const Key('depositHistoryEmpty'),
        style: AppStyle.interRegular(
          size: 12.5,
          color: AppStyle.textDarkSecondary,
        ),
      );
    }
    return Column(
      key: const Key('depositHistory'),
      children: [
        for (final row in state.deposits) _HistoryRow(record: row, now: now),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.record, required this.now});

  final DepositRecord record;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final view = depositStatusView(record.status);
    final when = record.submittedAt ?? record.resolvedAt;
    final reason = (record.rejectionReason ?? '').trim();
    return Container(
      key: Key('depositRow-${record.id}'),
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppStyle.cardDark,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppStyle.strokeDarkSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppHelpers.numberFormat(number: record.amount),
                      style: AppStyle.interSemi(size: 14),
                    ),
                    if (when != null) ...[
                      2.verticalSpace,
                      Text(
                        describeWhen(when, now),
                        style: AppStyle.interRegular(
                          size: 11.5,
                          color: AppStyle.textDarkSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _StatusChip(view: view),
            ],
          ),
          if (record.status == DepositStatus.rejected && reason.isNotEmpty) ...[
            8.verticalSpace,
            Text(
              reason,
              key: Key('depositRejectionReason-${record.id}'),
              style: AppStyle.interRegular(size: 12, color: AppStyle.red),
            ),
          ],
        ],
      ),
    );
  }
}
