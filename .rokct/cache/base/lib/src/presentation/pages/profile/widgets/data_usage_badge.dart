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
import 'package:remixicon/remixicon.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/data_usage_meter.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

/// The profile footer's "data used" figure, beside the days-in-app badge:
/// "4.2 MB used today · 61 MB this month". Tapping it shows the split
/// between Wi-Fi and mobile data. Counted on the device by
/// [DataUsageMeter], so it works signed in or not.
class DataUsageBadge extends StatelessWidget {
  const DataUsageBadge({super.key});

  static String label(DataUsageMeter m) =>
      '${DataUsageMeter.format(m.today.total)} '
      '${AppHelpers.getTranslation(TrKeys.dataUsedToday).toLowerCase()} · '
      '${DataUsageMeter.format(m.thisMonth.total)} '
      '${AppHelpers.getTranslation(TrKeys.dataThisMonth).toLowerCase()}';

  @override
  Widget build(BuildContext context) {
    final meter = DataUsageMeter.instance;
    return ListenableBuilder(
      listenable: meter,
      builder: (context, _) => InkWell(
        key: const ValueKey('profile.dataUsage'),
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showSplit(context, meter),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppStyle.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Remix.arrow_up_down_line, color: AppStyle.primary, size: 16),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label(meter),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyle.interNormal(
                    size: 12,
                    color: AppStyle.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showSplit(BuildContext context, DataUsageMeter m) {
    String tr(String k) => AppHelpers.getTranslation(k);
    Widget row(String name, DataUsageTotals t) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: AppStyle.interSemi(size: 14)),
          Text(
            '${tr(TrKeys.wifi)} ${DataUsageMeter.format(t.wifi)}',
            style: AppStyle.interNormal(size: 13),
          ),
          Text(
            '${tr(TrKeys.mobileData)} ${DataUsageMeter.format(t.mobile)}',
            style: AppStyle.interNormal(size: 13),
          ),
        ],
      ),
    );
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr(TrKeys.dataUsed)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              row(tr(TrKeys.today), m.today),
              row(tr(TrKeys.dataThisMonth), m.thisMonth),
              const SizedBox(height: 8),
              Text(
                tr(TrKeys.dataUsedNote),
                style: AppStyle.interNormal(size: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(tr(TrKeys.close)),
          ),
        ],
      ),
    );
  }
}
