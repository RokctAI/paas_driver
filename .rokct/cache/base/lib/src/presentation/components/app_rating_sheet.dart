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
import '../../services/app_rating.dart';
import '../../services/tr_keys.dart';
import '../theme/app_style.dart';

/// The app's own rating screen: five stars, then either the store step (4 or
/// 5 stars in a listed app) or a private note. See [AppRating].
class AppRatingSheet extends StatefulWidget {
  const AppRatingSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => const AppRatingSheet(),
      );

  @override
  State<AppRatingSheet> createState() => _AppRatingSheetState();
}

class _AppRatingSheetState extends State<AppRatingSheet> {
  int _stars = 0;
  final _note = TextEditingController();
  bool _done = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final goStore = AppRating.offersStore();
    await AppRating.save(_stars, comment: _note.text.trim(), wentToStore: goStore);
    if (goStore) await AppRating.openStore();
    if (mounted) setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppHelpers.getTranslation;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(t(_done ? TrKeys.thanksForRating : TrKeys.howIsTheApp), style: AppStyle.interBold(size: 18)),
          const SizedBox(height: 12),
          if (!_done) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    key: ValueKey('app_rating_star_$i'),
                    icon: Icon(i <= _stars ? Icons.star : Icons.star_border, color: AppStyle.primary, size: 36),
                    onPressed: () => setState(() => _stars = i),
                  ),
              ],
            ),
            if (_stars > 0 && AppRating.asksNote(_stars))
              TextField(
                key: const ValueKey('app_rating_note'),
                controller: _note,
                maxLines: 3,
                decoration: InputDecoration(hintText: t(TrKeys.tellUsWhatToFix)),
              ),
            const SizedBox(height: 12),
            FilledButton(
              key: const ValueKey('app_rating_send'),
              onPressed: _stars == 0 ? null : _send,
              child: Text(t(AppRating.offersStore() ? TrKeys.rateInStore : TrKeys.sendFeedback)),
            ),
          ],
        ],
      ),
    );
  }
}
