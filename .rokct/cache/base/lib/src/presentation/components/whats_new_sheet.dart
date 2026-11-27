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

import '../../services/app_helpers.dart';
import '../../services/tr_keys.dart';
import '../../services/whats_new.dart';
import '../theme/app_style.dart';

/// "What's new in <version>": shown once after an update, from the note the
/// release packed into this build ([WhatsNew]). Opened by the splash page
/// when it hands over to the main screen.
class WhatsNewSheet extends StatelessWidget {
  final WhatsNewNote note;
  const WhatsNewSheet({super.key, required this.note});

  static Future<void> show(BuildContext context, WhatsNewNote note) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => WhatsNewSheet(note: note),
      );

  /// Shows the note when this version has one the person has not seen.
  static Future<void> maybeShow(BuildContext context) async {
    final note = await WhatsNew.due();
    if (note == null || !context.mounted) return;
    await show(context, note);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppHelpers.getTranslation;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            key: const ValueKey('whats_new_sheet'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('${t(TrKeys.whatsNewIn)} ${note.version}',
                  style: AppStyle.interBold(size: 20)),
              const SizedBox(height: 12),
              // Long notes scroll, but no scrollbar shows (Ray, 2026-11-27).
              Flexible(
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context)
                      .copyWith(scrollbars: false),
                  child: SingleChildScrollView(
                    key: const ValueKey('whats_new_scroll'),
                    child: Text(note.notes,
                        style: AppStyle.interRegular(size: 15)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                key: const ValueKey('whats_new_ok'),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(t(TrKeys.gotIt)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
