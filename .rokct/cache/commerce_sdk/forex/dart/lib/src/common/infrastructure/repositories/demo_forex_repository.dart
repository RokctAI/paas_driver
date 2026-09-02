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

import '../../domain/interface/forex_repository.dart';
import '../../domain/models/forex_account.dart';
import '../../domain/models/forex_risk.dart';
import '../../domain/models/forex_strategy.dart';
import '../../domain/models/money.dart';

/// Demo-only [ForexRepository] (`--dart-define=IS_DEMO=true`): serves a tiny
/// fictional strategy catalogue, account snapshot and risk profile offline
/// so the forex screens (/forex-strategies, /forex-risk, /forex-account)
/// are never empty-state screens in demo builds — the same
/// `AppConstants.isDemo` split delivery_sdk's `DriverDeliveryDependencies`
/// and zones_sdk's `DemoDriverDeliveryZonesRepository` use. Registered in
/// place of `HttpForexRepository` by `ForexDependencies.register`; zero
/// behavior change when IS_DEMO is off. Never used in production; every
/// write is acknowledged locally and nothing leaves the device.
///
/// The four consumer-owned interfaces (access status, wallet balance, plan
/// catalog, subscription status) are deliberately NOT stubbed here — their
/// fail-closed resolvers in `ForexDependencies` stay authoritative, so a
/// demo build still shows the honest locked treatment on cards whose tier
/// the host has not unlocked (one card below is seeded locked on purpose to
/// show it).
class DemoForexRepository implements ForexRepository {
  /// Session-local risk profile: replaced by [setRiskPreset] so a preset
  /// choice sticks for the rest of the session. Resets on every launch.
  ForexRiskParameters _risk = ForexRiskPreset.all[1].parameters;

  static const List<ForexStrategySummary> _strategies = [
    ForexStrategySummary(
      key: 'steady-trend',
      title: 'Steady Trend',
      summary: 'Follows established trends with small, patient entries.',
      minTier: 'standard',
      latestVersion: 3,
      verdict: ForexEntitlementVerdict.allowed,
    ),
    ForexStrategySummary(
      key: 'range-keeper',
      title: 'Range Keeper',
      summary: 'Trades quiet ranges and steps aside when volatility spikes.',
      minTier: 'standard',
      latestVersion: 2,
      verdict: ForexEntitlementVerdict.allowed,
    ),
    ForexStrategySummary(
      key: 'momentum-pro',
      title: 'Momentum Pro',
      summary: 'Faster momentum entries for accounts on the pro tier.',
      minTier: 'pro',
      latestVersion: 5,
      verdict: ForexEntitlementVerdict.needsUpgrade,
    ),
  ];

  @override
  Future<List<ForexStrategySummary>> listStrategies() async =>
      List.of(_strategies);

  @override
  Future<ForexStrategyDetail> getStrategy(String key) async {
    final summary = _strategies.firstWhere(
      (s) => s.key == key,
      orElse: () => _strategies.first,
    );
    return ForexStrategyDetail(
      key: summary.key,
      title: summary.title,
      summary: summary.summary,
      pinnedVersion: summary.latestVersion,
      runVerdict: ForexRunVerdict.stopPaused,
      upgradeAvailable: null,
      blockedReason: null,
      versions: [
        ForexStrategyVersionSummary(
          version: summary.latestVersion ?? 1,
          status: ForexVersionStatus.published,
          runnable: true,
          blockedReason: null,
        ),
      ],
      spec: null,
      specChecksum: null,
    );
  }

  @override
  Future<void> pinVersion(String key, int version) async {}

  @override
  Future<ForexRunVerdict> setActive(String key, {required bool active}) async =>
      active ? ForexRunVerdict.run : ForexRunVerdict.stopPaused;

  @override
  Future<ForexDashboard> dashboard() async => ForexDashboard(
        connected: true,
        reason: null,
        accountId: 'DEMO-0001',
        snapshot: ForexAccountSnapshot(
          balance: Money(25000.00, 'USD'),
          equity: Money(25184.50, 'USD'),
          usedMargin: Money(1200.00, 'USD'),
          freeMargin: Money(23984.50, 'USD'),
          marginLevelPct: 2098.7,
          marginState: ForexMarginState.healthy,
          openPositionCount: 2,
          asOf: DateTime.now(),
          stale: false,
        ),
        positions: [
          ForexPosition(
            id: 'POS-1',
            symbol: 'EURUSD',
            side: 'buy',
            volume: 0.10,
            unrealised: Money(126.40, 'USD'),
            openedAt: DateTime.now().subtract(const Duration(hours: 6)),
          ),
          ForexPosition(
            id: 'POS-2',
            symbol: 'GBPUSD',
            side: 'sell',
            volume: 0.05,
            unrealised: Money(58.10, 'USD'),
            openedAt: DateTime.now().subtract(const Duration(hours: 2)),
          ),
        ],
        unreadablePositionCount: 0,
      );

  @override
  Future<ForexRiskParameters> myRiskParameters() async => _risk;

  @override
  Future<ForexRiskParameters> setRiskPreset(String presetName) async {
    _risk = ForexRiskPreset.resolve(presetName).parameters;
    return _risk;
  }
}
