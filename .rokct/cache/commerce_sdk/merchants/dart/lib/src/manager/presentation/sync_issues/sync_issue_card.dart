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

// The SYNC-ISSUE CARD in the standard list language (approved frame 38c,
// chips 708 + 709): box icon + label (the shipped
// manager_shops/products/orders mapping), the record summary, the
// server's rejection message in red, and the shipped action pair — Try
// again (requeue the parked push; on success the row leaves the list) and
// Discard (delete record + outbox op, behind the shipped are-you-sure
// dialog).

import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:merchants_sdk/src/manager/infrastructure/services/sync_issues_service.dart';
import 'package:merchants_sdk/src/manager/presentation/sync_issues/sync_issue_boxes.dart';

/// The shipped box -> glyph mapping, carried over unchanged.
IconData syncIssueBoxIcon(String box) {
  switch (box) {
    case 'manager_shops':
      return Remix.store_2_line;
    case 'manager_products':
      return Remix.shopping_bag_3_line;
    case 'manager_orders':
      return Remix.file_list_3_line;
  }
  return Remix.error_warning_line;
}

/// The colour a card wears: its box's tab colour, so a card and its tab
/// always read as the same thing (the 33a colour discipline).
Color syncIssueBoxColor(String box) => SyncIssueBox.values
    .firstWhere(
      (tab) => tab.box == box,
      orElse: () => SyncIssueBox.all,
    )
    .color;

class SyncIssueCard extends StatelessWidget {
  final SyncIssue issue;

  /// Already-translated box label (the page owns the TrKeys lookup, so
  /// the SDK half stays free of host-injected keys).
  final String boxLabel;

  final VoidCallback onRetry;
  final VoidCallback onDiscard;

  /// Already-translated action labels.
  final String retryLabel;
  final String discardLabel;

  const SyncIssueCard({
    super.key,
    required this.issue,
    required this.boxLabel,
    required this.onRetry,
    required this.onDiscard,
    required this.retryLabel,
    required this.discardLabel,
  });

  @override
  Widget build(BuildContext context) {
    final Color boxColor = syncIssueBoxColor(issue.box);
    final String? error = issue.error;
    return Container(
      margin: const EdgeInsets.fromLTRB(6, 0, 6, 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppStyle.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppStyle.strokeDarkSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: boxColor.withValues(alpha: 0.20),
                ),
                child: Icon(
                  syncIssueBoxIcon(issue.box),
                  size: 16,
                  color: boxColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                boxLabel,
                style: AppStyle.interSemi(size: 11.5, color: boxColor),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            issue.summary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppStyle.interSemi(size: 13, color: AppStyle.textPrimary),
          ),
          if (error != null && error.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              error,
              style: AppStyle.interNormal(size: 11.5, color: AppStyle.red),
            ),
          ],
          const SizedBox(height: 11),
          // 709: the shipped action pair, in the dark list dress.
          Row(
            children: [
              Expanded(
                child: _SyncIssueAction(
                  label: retryLabel,
                  icon: Remix.refresh_line,
                  onTap: onRetry,
                  filled: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SyncIssueAction(
                  label: discardLabel,
                  icon: Remix.delete_bin_6_line,
                  onTap: onDiscard,
                  color: AppStyle.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SyncIssueAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  final Color? color;

  const _SyncIssueAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final Color tint = color ?? AppStyle.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        height: 34,
        decoration: BoxDecoration(
          color: filled ? tint : AppStyle.transparent,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: tint),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: filled ? AppStyle.white : tint,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppStyle.interSemi(
                  size: 11.5,
                  color: filled ? AppStyle.white : tint,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The header's NEEDS-ATTENTION hint (chip 711): the quiet line under the
/// title that says why the list is not empty.
String syncIssueNeedsAttentionHint(int parked) =>
    '$parked ${AppHelpers.getTranslation('needs_attention')}';
