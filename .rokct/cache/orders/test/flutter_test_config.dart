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

// Registers this SDK's bundled English copy before every test file, the
// same thing the orders-en-bundled-translations boot hook does in a composed
// app, so widget tests find the English text that trkeys resolve to.

import 'dart:async';

import 'package:base_sdk/src/services/bundled_translations.dart';
import 'package:orders_sdk/src/translations/orders_en_translations.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  BundledTranslations.register('en', kOrdersEnTranslations);
  await testMain();
}
