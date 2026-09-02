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

// NOTIFICATIONS IN THE STANDARD LIST LANGUAGE — approved design strip
// frame 38b, Ray 2026-08-30 12:23Z ("33 list language = STANDARD for all
// lists ... the All/Unread tabs are IN").
//
// The shipped manager notification list was an undesigned white ListView
// whose only read-state affordance was the per-row dot, with "Read all"
// riding a bottom overlay ABOVE the floating nav. Redressed:
//
//   700  header COUNT PILL — "N unread", the standard slot
//   706  READ ALL, re-homed to a header action; the bottom belongs to the
//        two-state nav alone (its old overlay collided with the corner
//        back pill)
//   707  the All / Unread read-state FILTER TABS in the canonical 362/363
//        treatment — the genuinely new affordance Ray ruled IN
//   704  the shipped NOTIFICATION ROW, verbatim: 44 avatar (client photo,
//        or a tinted glyph for blog/system items), the client as
//        "First L.", the body, the Jiffy fromNow time
//   705  the shipped per-row UNREAD DOT; read rows dim to secondary
//
// The read-state split is pure data-in/data-out so it is unit-testable
// without a widget tree; the row is the presentation half.

import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';
import 'package:remixicon/remixicon.dart';

import 'package:base_sdk/src/models/response/notification_response.dart';
import 'package:base_sdk/src/presentation/components/helper/common_image.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';

/// The read-state filter (chip 707): the two tabs of the notification
/// list, in the order the approved frame draws them.
enum NotificationReadFilter {
  all,
  unread;

  /// Translation wire key for the tab label.
  String get wire => switch (this) {
    NotificationReadFilter.all => 'all',
    NotificationReadFilter.unread => 'unread',
  };

  /// Tab colour in the 362/363 treatment. "All" is the neutral base blue
  /// of the 33a set; "Unread" carries the brand primary — the same colour
  /// as the row dot it counts.
  Color get color => switch (this) {
    NotificationReadFilter.all => AppStyle.blue,
    NotificationReadFilter.unread => AppStyle.primary,
  };

  /// The rows this tab shows. "Unread" is exactly the shipped dot's
  /// condition — `readAt == null`.
  List<NotificationModel> apply(List<NotificationModel> notifications) =>
      switch (this) {
        NotificationReadFilter.all => notifications,
        NotificationReadFilter.unread =>
          notifications.where((n) => n.readAt == null).toList(),
      };

  /// The tab's own count pill.
  int countIn(List<NotificationModel> notifications) =>
      apply(notifications).length;
}

/// The shipped notification row (chips 704 + 705), in the dark list
/// dress. Read rows dim to secondary; the unread dot is the shipped
/// primary dot.
class NotificationRow extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  /// The row whose detail currently holds the last plane.
  final bool selected;

  const NotificationRow({
    super.key,
    required this.notification,
    required this.onTap,
    this.selected = false,
  });

  bool get _isUnread => notification.readAt == null;

  /// "First L." — the shipped name shape.
  String get _clientName {
    final client = notification.client;
    if (client == null) return '';
    final last = client.lastname ?? '';
    final initial = last.isEmpty ? '' : ' ${last.substring(0, 1)}.';
    return '${client.firstname ?? ''}$initial'.trim();
  }

  /// A blog or system item has no client photo; the shipped page fell
  /// back to an empty avatar, the language gives it a tinted glyph.
  IconData get _glyph {
    if (notification.blogData != null) return Remix.article_line;
    if (notification.orderData != null) return Remix.file_list_3_line;
    return Remix.notification_3_line;
  }

  @override
  Widget build(BuildContext context) {
    final String? image =
        notification.client?.img ?? notification.blogData?.img;
    final Color ink = _isUnread
        ? AppStyle.textPrimary
        : AppStyle.textDarkSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.fromLTRB(6, 0, 6, 8),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: AppStyle.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppStyle.primary : AppStyle.strokeDarkSubtle,
            width: selected ? 1.3 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (image != null && image.isNotEmpty)
              CommonImage(url: image, radius: 22, width: 44, height: 44)
            else
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppStyle.primary.withValues(alpha: 0.18),
                ),
                child: Icon(_glyph, size: 19, color: AppStyle.primary),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (notification.client != null)
                    Text(
                      _clientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyle.interSemi(size: 13, color: ink),
                    ),
                  if (notification.client != null) const SizedBox(height: 2),
                  Text(
                    '${notification.body ?? notification.title ?? ''}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyle.interNormal(size: 12.5, color: ink),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Jiffy.parseFromDateTime(
                      notification.createdAt ?? DateTime.now(),
                    ).fromNow(),
                    style: AppStyle.interNormal(
                      size: 10.5,
                      color: AppStyle.textDarkFaint,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 705: the shipped unread dot, one per row.
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isUnread ? AppStyle.primary : AppStyle.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The header's READ ALL action (chip 706) — re-homed from the shipped
/// bottom overlay. A pill, not a round utility: it carries a word.
class NotificationReadAllAction extends StatelessWidget {
  final VoidCallback onTap;
  final bool enabled;

  const NotificationReadAllAction({
    super.key,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppStyle.cardDark,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppStyle.strokeDark),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Remix.check_double_line,
              size: 16,
              color: enabled
                  ? AppStyle.textPrimary
                  : AppStyle.textDarkFaint,
            ),
            const SizedBox(width: 7),
            Text(
              AppHelpers.getTranslation('read_all'),
              style: AppStyle.interSemi(
                size: 12,
                color: enabled
                    ? AppStyle.textPrimary
                    : AppStyle.textDarkFaint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
