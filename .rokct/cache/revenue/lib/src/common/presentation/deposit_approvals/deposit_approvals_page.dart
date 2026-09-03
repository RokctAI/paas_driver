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

import 'package:revenue_sdk/src/common/application/deposit_approvals/deposit_approvals_provider.dart';
import 'package:revenue_sdk/src/common/application/deposit_approvals/deposit_approvals_state.dart';
import 'package:revenue_sdk/src/common/infrastructure/models/response/deposit_request_record.dart';
import 'package:revenue_sdk/src/common/presentation/deposit_approvals/deposit_reject_sheet.dart';

/// Design strip frame 49i, the manager's side — the deposit queue.
///
/// A driver's bank deposit (49h) lands here as a Pending `Wallet Deposit
/// Request`: who, how much, the reference he wrote on the slip, the slip
/// itself, and what his wallet stood at when he sent it. The manager
/// matches it against the bank statement and decides. **Approve credits
/// the wallet, once, server-side; Reject needs a reason the driver will
/// read.** Nothing moves until one of the two is tapped, and this page
/// never pretends otherwise.
///
/// PLANE DISCIPLINE: plane 2 of the manager hub — the canonical back pill
/// (chip 347) at the bottom-end corner, no floating nav, pushed on the
/// root navigator so the host's nav folds away while it is open.
///
/// ROLE: the server gates both decisions (`DEPOSIT_APPROVER_ROLES`) and
/// refuses a requester reviewing his own request. This page is reached
/// only from the manager hub ([ManagerWalletPane]), so a driver app never
/// draws it; a caller the server refuses meets one friendly line.
class DepositApprovalsPage extends ConsumerStatefulWidget {
  const DepositApprovalsPage({super.key, this.now});

  /// Injectable clock for the "submitted" line; null reads the wall clock.
  final DateTime? now;

  static Future<void> push(BuildContext context) {
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => const DepositApprovalsPage()),
    );
  }

  @override
  ConsumerState<DepositApprovalsPage> createState() =>
      _DepositApprovalsPageState();
}

class _DepositApprovalsPageState extends ConsumerState<DepositApprovalsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(depositApprovalsProvider.notifier).load(context: context);
      }
    });
  }

  Future<void> _approve(DepositRequestRecord request) {
    return ref.read(depositApprovalsProvider.notifier).approve(
          context: context,
          request: request,
          onDone: (resolution) {
            if (!mounted) return;
            AppHelpers.showCheckTopSnackBarDone(
              context,
              '${AppHelpers.getTranslation('approved')}: '
              '${AppHelpers.numberFormat(number: resolution.amount ?? request.amount)} '
              '${AppHelpers.getTranslation('added_to')} ${request.displayName}',
            );
          },
        );
  }

  void _openReject(DepositRequestRecord request) {
    AppHelpers.showCustomModalBottomSheet(
      context: context,
      isDarkMode: true,
      modal: Consumer(
        builder: (sheetContext, ref, _) {
          final resolving = ref.watch(depositApprovalsProvider).resolvingId;
          return DepositRejectSheet(
            driverName: request.displayName,
            amountLine: [
              AppHelpers.numberFormat(number: request.amount),
              if ((request.reference ?? '').isNotEmpty) request.reference!,
            ].join(' · '),
            submitting: resolving == request.id,
            onSubmit: (reason) {
              ref.read(depositApprovalsProvider.notifier).reject(
                    context: sheetContext,
                    request: request,
                    reason: reason,
                    onDone: (_) {
                      Navigator.of(sheetContext).pop();
                      if (!mounted) return;
                      AppHelpers.showCheckTopSnackBarDone(
                        context,
                        '${AppHelpers.getTranslation('rejected')}: '
                        '${request.displayName}',
                      );
                    },
                  );
            },
          );
        },
      ),
    );
  }

  void _openSlip(DepositRequestRecord request) {
    final url = request.slipUrl;
    if (url == null) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        key: const Key('depositSlipDialog'),
        backgroundColor: AppStyle.cardDark,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(12.r),
              child: Text(
                '${request.displayName} · ${request.reference ?? ''}',
                style: AppStyle.interSemi(size: 13),
              ),
            ),
            Flexible(
              child: InteractiveViewer(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Padding(
                    padding: EdgeInsets.all(24.r),
                    child: Text(
                      AppHelpers.getTranslation('we_couldnt_load_the_slip'),
                      style: AppStyle.interRegular(
                        size: 12.5,
                        color: AppStyle.textDarkSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                AppHelpers.getTranslation(TrKeys.close),
                style: AppStyle.interSemi(size: 13, color: AppStyle.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(depositApprovalsProvider);
    return Scaffold(
      backgroundColor: AppStyle.surfaceDark,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: RefreshIndicator(
                color: AppStyle.primary,
                onRefresh: () => ref
                    .read(depositApprovalsProvider.notifier)
                    .load(context: context),
                child: ListView(
                  key: const Key('depositApprovalsPage'),
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 92.h),
                  children: [
                    Text(
                      AppHelpers.getTranslation('deposits_to_approve'),
                      style: AppStyle.interSemi(size: 21),
                    ),
                    8.verticalSpace,
                    Text(
                      AppHelpers.getTranslation(
                        'match_each_slip_against_the_bank_statement_approving_adds_the_amount_to_the_drivers_wallet_rejecting_needs_a_reason_he_will_read',
                      ),
                      key: const Key('depositApprovalsExplainer'),
                      style: AppStyle.interRegular(
                        size: 12,
                        color: AppStyle.textDarkSecondary,
                      ),
                    ),
                    20.verticalSpace,
                    _Queue(
                      state: state,
                      now: widget.now ?? DateTime.now(),
                      onApprove: _approve,
                      onReject: _openReject,
                      onSlip: _openSlip,
                    ),
                  ],
                ),
              ),
            ),
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

class _Queue extends StatelessWidget {
  const _Queue({
    required this.state,
    required this.now,
    required this.onApprove,
    required this.onReject,
    required this.onSlip,
  });

  final DepositApprovalsState state;
  final DateTime now;
  final void Function(DepositRequestRecord) onApprove;
  final void Function(DepositRequestRecord) onReject;
  final void Function(DepositRequestRecord) onSlip;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && !state.loadedOnce) {
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
    if (state.failed && state.pending.isEmpty) {
      return Text(
        AppHelpers.getTranslation('we_couldnt_load_the_deposits_pull_to_try_again'),
        key: const Key('depositApprovalsFailed'),
        style: AppStyle.interRegular(size: 12.5, color: AppStyle.textDarkSecondary),
      );
    }
    if (state.pending.isEmpty) {
      return Text(
        AppHelpers.getTranslation('nothing_is_waiting_for_you'),
        key: const Key('depositApprovalsEmpty'),
        style: AppStyle.interRegular(size: 12.5, color: AppStyle.textDarkSecondary),
      );
    }
    return Column(
      key: const Key('depositApprovalsQueue'),
      children: [
        for (final request in state.pending)
          _PendingCard(
            request: request,
            now: now,
            resolving: state.resolvingId == request.id,
            inert: state.resolvingId != null,
            onApprove: () => onApprove(request),
            onReject: () => onReject(request),
            onSlip: () => onSlip(request),
          ),
      ],
    );
  }
}

/// One waiting request: who, how much, against what, the slip, and the
/// two decisions.
class _PendingCard extends StatelessWidget {
  const _PendingCard({
    required this.request,
    required this.now,
    required this.resolving,
    required this.inert,
    required this.onApprove,
    required this.onReject,
    required this.onSlip,
  });

  final DepositRequestRecord request;
  final DateTime now;

  /// This card's decision is in flight.
  final bool resolving;

  /// SOME decision is in flight — every card's buttons wait for it.
  final bool inert;

  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onSlip;

  String _when(DateTime at) {
    final local = at.isUtc ? at.toLocal() : at;
    String two(int n) => n.toString().padLeft(2, '0');
    final time = '${two(local.hour)}:${two(local.minute)}';
    final day = DateTime(local.year, local.month, local.day);
    final today = DateTime(now.year, now.month, now.day);
    final gap = today.difference(day).inDays;
    if (gap <= 0) return '${AppHelpers.getTranslation('today')} $time';
    if (gap == 1) return '${AppHelpers.getTranslation('yesterday')} $time';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${local.day} ${months[local.month - 1]} $time';
  }

  /// The wallet the deposit was sent against, as a sentence — never a
  /// signed number (section 49's standing rule).
  String? _againstLine() {
    final at = request.balanceAtSubmit;
    if (at == null) return null;
    final figure = AppHelpers.numberFormat(number: at.abs());
    if (at < 0) {
      return '${AppHelpers.getTranslation('wallet_when_sent')}: '
          '${AppHelpers.getTranslation('owed')} $figure';
    }
    return '${AppHelpers.getTranslation('wallet_when_sent')}: '
        '${AppHelpers.getTranslation('had')} $figure';
  }

  @override
  Widget build(BuildContext context) {
    final against = _againstLine();
    final submitted = request.submittedAt;
    return Container(
      key: Key('depositApproval-${request.id}'),
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppStyle.cardDark,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppStyle.strokeDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.displayName,
                  key: Key('depositApprovalName-${request.id}'),
                  style: AppStyle.interSemi(size: 15),
                ),
              ),
              Text(
                AppHelpers.numberFormat(number: request.amount),
                key: Key('depositApprovalAmount-${request.id}'),
                style: AppStyle.interSemi(size: 17),
              ),
            ],
          ),
          6.verticalSpace,
          Text(
            [
              if ((request.reference ?? '').isNotEmpty)
                '${AppHelpers.getTranslation('reference')} ${request.reference}',
              if ((request.method ?? '').isNotEmpty) request.method!,
            ].join(' · '),
            style: AppStyle.interRegular(size: 12, color: AppStyle.textDarkSecondary),
          ),
          if (submitted != null) ...[
            2.verticalSpace,
            Text(
              '${AppHelpers.getTranslation('submitted')} ${_when(submitted)}',
              style: AppStyle.interRegular(size: 12, color: AppStyle.textDarkSecondary),
            ),
          ],
          if (against != null) ...[
            2.verticalSpace,
            Text(
              against,
              key: Key('depositApprovalAgainst-${request.id}'),
              style: AppStyle.interRegular(size: 12, color: AppStyle.textDarkSecondary),
            ),
          ],
          if ((request.note ?? '').isNotEmpty) ...[
            6.verticalSpace,
            Text(
              request.note!,
              style: AppStyle.interRegular(size: 12, color: AppStyle.textPrimary),
            ),
          ],
          10.verticalSpace,
          GestureDetector(
            key: Key('depositApprovalSlip-${request.id}'),
            behavior: HitTestBehavior.opaque,
            onTap: request.slipUrl == null ? null : onSlip,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Remix.image_line,
                  size: 16.r,
                  color: request.slipUrl == null
                      ? AppStyle.textDarkFaint
                      : AppStyle.primary,
                ),
                6.horizontalSpace,
                Text(
                  AppHelpers.getTranslation(
                    request.slipUrl == null ? 'no_slip_attached' : 'view_slip',
                  ),
                  style: AppStyle.interNoSemi(
                    size: 12,
                    color: request.slipUrl == null
                        ? AppStyle.textDarkFaint
                        : AppStyle.primary,
                  ),
                ),
              ],
            ),
          ),
          14.verticalSpace,
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  key: Key('depositApprove-${request.id}'),
                  title: AppHelpers.getTranslation(TrKeys.approve),
                  background: inert ? AppStyle.strokeDark : AppStyle.primary,
                  textColor: inert ? AppStyle.textDarkFaint : AppStyle.blackColor,
                  isLoading: resolving,
                  onPressed: inert ? () {} : onApprove,
                ),
              ),
              10.horizontalSpace,
              Expanded(
                child: CustomButton(
                  key: Key('depositReject-${request.id}'),
                  title: AppHelpers.getTranslation('reject'),
                  background: AppStyle.cardDarkAlt,
                  textColor: inert ? AppStyle.textDarkFaint : AppStyle.red,
                  onPressed: inert ? () {} : onReject,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
