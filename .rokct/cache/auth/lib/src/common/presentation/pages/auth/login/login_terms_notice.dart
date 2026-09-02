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

import 'package:base_sdk/src/presentation/theme/theme.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

import 'package:auth_sdk/src/common/presentation/pages/auth/login/login_embedded_slots.dart';

/// The login screen's legal line: "By using <app>'s services, you
/// acknowledge that you have read and accepted the Terms & Privacy Policy",
/// with both names as links into corporate_sdk's pages.
///
/// Extracted from the login page so the one decision it carries is testable:
/// the two pages are borrowed through the EmbeddedWidgets registry, and a
/// composition without corporate_sdk has neither. The whole line is then
/// dropped rather than any part of it kept — the sentence exists only to
/// point at those two documents, so a card ending in "...accepted the" (or
/// links that throw on tap) is worse than no card, and both pages come from
/// the same SDK, so "one link missing" is not a shape a real app takes.
///
/// With corporate_sdk composed this renders exactly the card it always did.
class LoginTermsNotice extends StatelessWidget {
  const LoginTermsNotice({super.key, required this.slots});

  /// The login screen's once-resolved registry slots.
  final LoginEmbeddedSlots slots;

  void _open(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget? termPage = slots.termPage;
    final Widget? policyPage = slots.policyPage;
    if (!slots.hasLegalPages || termPage == null || policyPage == null) {
      return const SizedBox.shrink();
    }
    return Container(
      decoration: BoxDecoration(
        color: AppStyle.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(
          10,
        ), // Adjust the radius as needed
      ),
      padding: const EdgeInsets.all(
        16,
      ), // Adjust the padding as needed
      child: Wrap(
        alignment: WrapAlignment.center,
        children: [
          Text(
            "By using ${AppHelpers.getAppName() ?? ""}'s services, you acknowledge that you have read and accepted the",
            style: const TextStyle(
              color: AppStyle.black,
            ), // Make text color white for visibility
          ),
          InkWell(
            onTap: () => _open(context, termPage),
            child: Text(
              AppHelpers.getTranslation(TrKeys.terms),
              style: const TextStyle(
                decoration: TextDecoration.underline,
                color: AppStyle.black, // Optional: Different color for links
              ),
            ),
          ),
          const Text(
            " & ",
            style: TextStyle(
              color: AppStyle.black,
            ), // Make text color white for visibility
          ),
          InkWell(
            onTap: () => _open(context, policyPage),
            child: Text(
              AppHelpers.getTranslation(
                TrKeys.privacyPolicy,
              ),
              style: const TextStyle(
                decoration: TextDecoration.underline,
                color: AppStyle.black, // Optional: Different color for links
              ),
            ),
          ),
        ],
      ),
    );
  }
}
