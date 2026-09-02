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

import 'package:base_sdk/src/application/app_widget/app_provider.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';

/// Icon-only dark/light theme toggle pill for the generic profile page's
/// top controls row — the old lms app bar's pill, now host-owned so every
/// profile page carries it.
///
/// A tap does two things:
///   * flips the persisted app-wide theme mode via
///     [AppNotifier.changeTheme] (LocalStorage + [appProvider] state — the
///     host `MaterialApp` watches the same provider and re-themes the
///     Material tree), and
///   * calls [AppStyle.setBrightness] so [AppStyle]'s mode-resolving
///     surface getters (`surfaceDark`, `cardDark`, ...) resolve to the new
///     mode on the next build.
///
/// The second step is deliberately local: wiring [AppStyle.setBrightness]
/// to the app shell's themeMode for every page is the fleet theme-wiring
/// work tracked separately; until that lands, this toggle keeps the
/// profile surface (which watches [appProvider]) correct on its own.
class ProfileThemeToggle extends ConsumerWidget {
  const ProfileThemeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(appProvider.select((s) => s.isDarkMode));
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final next = !ref.read(appProvider).isDarkMode;
        AppStyle.setBrightness(next ? Brightness.dark : Brightness.light);
        ref.read(appProvider.notifier).changeTheme(next);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: AppStyle.cardDarkAlt,
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: AppStyle.strokeDark, width: 0.5),
        ),
        child: Icon(
          isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
          size: 16,
          color: AppStyle.textPrimary,
        ),
      ),
    );
  }
}
