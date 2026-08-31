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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:remixicon/remixicon.dart';

import 'package:base_sdk/src/presentation/components/floating_nav/floating_bottom_nav.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

import 'package:revenue_sdk/src/common/infrastructure/models/response/bank_account_record.dart';
import 'package:revenue_sdk/src/driver/application/bank/bank_accounts_provider.dart';
import 'package:revenue_sdk/src/driver/presentation/bank/bank_account_form_page.dart';
import 'package:revenue_sdk/src/driver/presentation/bank/bank_grammar.dart';

/// Frame 49q — saved accounts: more than one is allowed, exactly one is the
/// default, and the backend says so.
///
/// The list is built for MORE THAN ONE because the backend genuinely
/// supports more than one — `list_bank_accounts` returns every row for the
/// session user ordered `is_default desc, creation desc`
/// (`pay/wallet/frappe/src/tenant/api/payout.py:241-252`), which is the
/// order drawn — and there is no per-user cap anywhere in
/// `add_bank_account`.
///
/// THE DEFAULT IS SINGULAR AND NEVER ABSENT, and all three behaviours are
/// code: the mark is exclusive (`:209-220`), the first account added carries
/// it whatever the switch said (`:205-207`), and removing the default
/// promotes the newest survivor (`:288-300`).
///
/// WHY `Make default` IS ALWAYS AVAILABLE rather than a settings detail:
/// `_default_account` falls back to an unmarked account only when there is
/// exactly ONE (`:137-157`). A driver with two unmarked rows would be
/// refused a payout with nothing on screen explaining why — so this list
/// must never permit that state to persist silently.
///
/// PLANE DISCIPLINE: plane 2 of the income hub — the canonical back pill
/// (chip 347), no floating nav, pushed on the root navigator.
class BankAccountsPage extends ConsumerStatefulWidget {
  const BankAccountsPage({super.key});

  static Future<void> push(BuildContext context) {
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => const BankAccountsPage()),
    );
  }

  @override
  ConsumerState<BankAccountsPage> createState() => _BankAccountsPageState();
}

class _BankAccountsPageState extends ConsumerState<BankAccountsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(bankAccountsProvider.notifier).load(context: context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bankAccountsProvider);
    return Scaffold(
      backgroundColor: AppStyle.surfaceDark,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 92.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppHelpers.getTranslation('bank_accounts'),
                      style: AppStyle.interSemi(size: 21),
                    ),
                    6.verticalSpace,
                    Text(
                      AppHelpers.getTranslation(
                        'payouts_go_to_your_default_unless_you_pick_another',
                      ),
                      style: AppStyle.interRegular(
                        size: 12,
                        color: AppStyle.textDarkSecondary,
                      ),
                    ),
                    22.verticalSpace,
                    Text(
                      AppHelpers.getTranslation('your_accounts').toUpperCase(),
                      style: AppStyle.interSemi(
                        size: 10.5,
                        letterSpacing: 1.2,
                        color: AppStyle.textDarkSecondary,
                      ),
                    ),
                    12.verticalSpace,
                    _body(state.accounts, state),
                    16.verticalSpace,
                    _addAnother(),
                    22.verticalSpace,
                    _defaultRuleCard(),
                    14.verticalSpace,
                    _snapshotCard(),
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

  Widget _body(List<BankAccountRecord> accounts, dynamic state) {
    if (accounts.isEmpty) {
      // Only once a read has landed: an empty list before that is "we have
      // not looked", not "he has none".
      final loadedOnce = ref.watch(bankAccountsProvider).loadedOnce;
      final failed = ref.watch(bankAccountsProvider).failed;
      if (!loadedOnce) return const SizedBox.shrink();
      return Text(
        AppHelpers.getTranslation(
          failed
              ? 'we_couldnt_load_your_bank_accounts_try_again_in_a_moment'
              : 'you_havent_added_a_bank_account_yet',
        ),
        key: const Key('bankAccountsEmptyLine'),
        style: AppStyle.interRegular(
          size: 12,
          color: AppStyle.textDarkFaint,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final account in accounts) ...[
          _accountRow(account),
          10.verticalSpace,
        ],
      ],
    );
  }

  /// Chip 1011 — holder, bank, type, masked number and branch: every field
  /// `_account_payload` carries (`payout.py:159-169`) except the row name,
  /// which is a Frappe hash and means nothing to a driver.
  Widget _accountRow(BankAccountRecord account) {
    final state = ref.watch(bankAccountsProvider);
    final blocked = isRemovalBlocked(account.id, state.liveRequests);
    final busy = state.busyAccountId == account.id;
    return Container(
      key: Key('bankAccountRow_${account.id}'),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppStyle.cardDark,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  account.accountHolderName,
                  style: AppStyle.interNoSemi(size: 14),
                ),
              ),
              if (account.isDefault)
                Container(
                  key: Key('bankDefaultBadge_${account.id}'),
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: AppStyle.primary,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    AppHelpers.getTranslation('default').toUpperCase(),
                    style: AppStyle.interSemi(
                      size: 9,
                      letterSpacing: 0.8,
                      color: AppStyle.blackColor,
                    ),
                  ),
                )
              else
                GestureDetector(
                  key: Key('bankMakeDefault_${account.id}'),
                  onTap: busy
                      ? null
                      : () => ref
                          .read(bankAccountsProvider.notifier)
                          .makeDefault(context: context, account: account),
                  child: Text(
                    AppHelpers.getTranslation('make_default'),
                    style: AppStyle.interNoSemi(
                      size: 11.5,
                      color: AppStyle.primary,
                    ),
                  ),
                ),
            ],
          ),
          6.verticalSpace,
          Text(
            accountSummary(account),
            style: AppStyle.interRegular(
              size: 12,
              color: AppStyle.textDarkSecondary,
            ),
          ),
          4.verticalSpace,
          Text(
            [
              maskAccountNumber(account.accountNumber),
              if ((account.branchCode ?? '').trim().isNotEmpty)
                '${AppHelpers.getTranslation('branch')} ${account.branchCode}',
            ].join(' · '),
            style: AppStyle.interRegular(
              size: 12,
              color: AppStyle.textDarkFaint,
            ),
          ),
          10.verticalSpace,
          Divider(height: 1, color: AppStyle.strokeDarkSubtle),
          8.verticalSpace,
          GestureDetector(
            key: Key('bankRemove_${account.id}'),
            onTap: busy || blocked
                ? null
                : () => ref
                    .read(bankAccountsProvider.notifier)
                    .remove(context: context, account: account),
            child: Text(
              AppHelpers.getTranslation('remove'),
              style: AppStyle.interNoSemi(
                size: 12,
                color: blocked ? AppStyle.textDarkFaint : AppStyle.red,
              ),
            ),
          ),
          // Chip 1013 — the reason is given IN THE ROW, in the driver's
          // terms, not as a toast and not in the server's words. He is told
          // a payout is waiting; the payout trail is where he cancels it.
          if (blocked) ...[
            4.verticalSpace,
            Text(
              AppHelpers.getTranslation(
                'a_payout_is_still_waiting_on_this_account',
              ),
              key: Key('bankRemoveBlocked_${account.id}'),
              style: AppStyle.interRegular(
                size: 11,
                color: AppStyle.textDarkFaint,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _addAnother() => GestureDetector(
        key: const Key('bankAddAnother'),
        onTap: () async {
          await BankAccountFormPage.push(context);
          if (mounted) {
            await ref.read(bankAccountsProvider.notifier).load(context: context);
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 14.h),
          decoration: BoxDecoration(
            color: AppStyle.cardDarkAlt,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppStyle.strokeDark),
          ),
          child: Text(
            AppHelpers.getTranslation('add_another_account'),
            textAlign: TextAlign.center,
            style: AppStyle.interNoSemi(size: 13, color: AppStyle.primary),
          ),
        ),
      );

  /// Chip 1012's sentence: three real behaviours, each of them code.
  Widget _defaultRuleCard() => _noteCard(
        key: const Key('bankDefaultRuleCard'),
        title: 'one_account_is_always_your_default',
        body: 'choosing_another_moves_the_mark_across_it_never_leaves_you_'
            'without_one_remove_the_default_and_the_next_newest_account_'
            'takes_it_over',
      );

  /// Not a chip: the plain-language statement of the snapshot the request row
  /// takes (`payout.py:349-368`), repeated here because this is the screen
  /// where a driver edits details and wonders what that does to money already
  /// in flight.
  Widget _snapshotCard() => _noteCard(
        key: const Key('bankSnapshotCard'),
        title: 'changing_an_account_never_changes_a_payout_you_already_sent',
        body: 'the_details_are_copied_onto_each_request_as_you_send_it',
      );

  Widget _noteCard({
    required Key key,
    required String title,
    required String body,
  }) =>
      Container(
        key: key,
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
        decoration: BoxDecoration(
          color: AppStyle.cardDark,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppHelpers.getTranslation(title),
              style: AppStyle.interNoSemi(size: 11.5),
            ),
            6.verticalSpace,
            Text(
              AppHelpers.getTranslation(body),
              style: AppStyle.interRegular(
                size: 10.5,
                color: AppStyle.textDarkSecondary,
              ),
            ),
          ],
        ),
      );
}
