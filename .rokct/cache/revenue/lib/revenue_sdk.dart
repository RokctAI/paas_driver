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

library revenue_sdk;

// Common-only barrel, same rule as auth_sdk's: everything exported here lives
// under `src/common/`, because the composer's strip_unused_role_folders
// deletes the non-matching role folder from an app's cache (a driver app
// loses `lib/src/manager/`, a manager app loses `lib/src/driver/`) and the
// generated `main.dart` imports this barrel in every composed app — a single
// export into a role folder would break the other role's build.
//
// `common/` holds what is common *by design*: the seams a host implements
// against ([SellerStatisticsRepositoryFacade] and
// [CourierStatisticsRepositoryFacade]), the response models those seams'
// signatures return, and the DI entry point every generated `main.dart`
// calls. Role folders hold the role-specific concrete repositories and
// application state, reached only from code that itself survives the same
// strip — import them via direct `package:revenue_sdk/src/<role>/...` paths:
//
// - manager/: SellerStatisticsRepository, the income screen's
//   statistics notifier/provider/state (used by the manager income page
//   template installed into manager hosts), and ManagerRevenueDependencies
//   (src/manager/di/manager_revenue_di.dart).
// - driver/: CourierStatisticsRepository, the income screen's statistics
//   notifier/provider/state plus its OrdinalSales chart row (used by the
//   driver income page template installed into driver hosts), the wallet
//   plane (design strip frame 49f: its page, widgets and application
//   slice over DriverWalletRepository), and DriverRevenueDependencies
//   (src/driver/di/driver_revenue_di.dart).
//
// Since 1.11.0 the withdraw slice (WithdrawSheet + notifier/provider/state),
// the payout repository, the bank-details surface (frames 49n-49s) and the
// payout trail (frame 49k) live in `common/` and are exported below: they
// are the same endpoint, doctype, debit timing and credit-back for every
// actor, and design strip frame 49l (approved 2026-08-31) mounts them on the
// MANAGER hub too. `ManagerWalletPane` / `ManagerWithdrawAction` with
// `managerWalletProvider` keyed by `ManagerWalletScope` are the entry the
// merchants shop page passes where it passes `actions: []` today. Both role
// DI hooks register the payout seam, so either flavour resolves it.
export 'src/common/di/revenue_di.dart';
export 'src/common/domain/interface/courier_statistics.dart';
export 'src/common/domain/interface/deposit_approval.dart';
export 'src/common/domain/interface/driver_payout.dart';
export 'src/common/domain/interface/driver_wallet.dart';
export 'src/common/domain/interface/seller_statistics.dart';
export 'src/common/infrastructure/models/response/bank_account_record.dart';
export 'src/common/infrastructure/models/response/courier_statistics_income_response.dart';
export 'src/common/infrastructure/models/response/deposit_request_record.dart';
export 'src/common/infrastructure/models/response/courier_statistics_order_response.dart';
export 'src/common/infrastructure/models/response/courier_statistics_response.dart';
export 'src/common/infrastructure/models/response/payout_request_record.dart';
export 'src/common/infrastructure/models/response/payout_request_response.dart';
export 'src/common/infrastructure/models/response/profit_report_response.dart';
export 'src/common/infrastructure/models/response/statistics_order_response.dart';
export 'src/common/infrastructure/models/response/statistics_response.dart';
export 'src/common/infrastructure/models/response/wallet_movement.dart';
export 'src/common/infrastructure/wallet_balance_cache.dart';
export 'src/common/infrastructure/repositories/deposit_approval_repository.dart';
export 'src/common/infrastructure/repositories/driver_payout_repository.dart';
export 'src/common/application/bank/bank_accounts_notifier.dart';
export 'src/common/application/bank/bank_accounts_provider.dart';
export 'src/common/application/bank/bank_accounts_state.dart';
export 'src/common/application/deposit_approvals/deposit_approvals_notifier.dart';
export 'src/common/application/deposit_approvals/deposit_approvals_provider.dart';
export 'src/common/application/deposit_approvals/deposit_approvals_state.dart';
export 'src/common/application/manager_wallet/manager_wallet_notifier.dart';
export 'src/common/application/manager_wallet/manager_wallet_provider.dart';
export 'src/common/application/manager_wallet/manager_wallet_scope.dart';
export 'src/common/application/manager_wallet/manager_wallet_state.dart';
export 'src/common/application/payouts/payout_history_notifier.dart';
export 'src/common/application/payouts/payout_history_provider.dart';
export 'src/common/application/payouts/payout_history_state.dart';
export 'src/common/application/withdraw/withdraw_notifier.dart';
export 'src/common/application/withdraw/withdraw_provider.dart';
export 'src/common/application/withdraw/withdraw_state.dart';
export 'src/common/presentation/bank/bank_account_form_page.dart';
export 'src/common/presentation/bank/bank_accounts_page.dart';
export 'src/common/presentation/bank/no_bank_account_sheet.dart';
export 'src/common/presentation/bank/payout_sent_sheet.dart';
export 'src/common/presentation/deposit_approvals/deposit_approvals_page.dart';
export 'src/common/presentation/deposit_approvals/deposit_reject_sheet.dart';
export 'src/common/presentation/manager_wallet/manager_wallet_pane.dart';
export 'src/common/presentation/payouts/driver_payouts_page.dart';
export 'src/common/presentation/payouts/payout_history_list.dart';
export 'src/common/presentation/payouts/payout_status_trail.dart';
export 'src/common/presentation/withdraw/withdraw_sheet.dart';
