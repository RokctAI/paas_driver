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


import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

abstract class AppValidators {
  AppValidators._();
  static bool isValidEmail(String email) => RegExp(
        "^[a-zA-Z0-9.!#\$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*\$",
      ).hasMatch(email);

  static bool checkEmail(String email) =>
      RegExp("/^[0-9 ()+-]+\$/").hasMatch(email);

  static bool isValidPassword(String password) => password.length > 5;

  static String? isNotEmptyValidator(String? title) {
    if (title?.isEmpty ?? true) {
      return AppHelpers.getTranslation(TrKeys.thisFieldIsRequired);
    }
    return null;
  }

  static String? emailCheck(String? text) {
    if (text == null || text.trim().isEmpty) {
      return AppHelpers.getTranslation(TrKeys.thisFieldIsRequired);
    }
    if (!isValidEmail(text)) {
      return AppHelpers.getTranslation(TrKeys.emailIsNotValid);
    }
    return null;
  }

  static String? isValidPrice(String? title) {
    if (title?.isEmpty ?? true) {
      return AppHelpers.getTranslation(TrKeys.thisFieldIsRequired);
    } else if ((num.tryParse(title ?? "0") ?? 0) <= 0) {
      return AppHelpers.getTranslation(TrKeys.thisFieldIsNotMinusOrZero);
    }
    return null;
  }

  static bool isValidConfirmPassword(String password, String confirmPassword) =>
      password == confirmPassword;

  static bool arePasswordsTheSame(String password, String confirmPassword) =>
      password == confirmPassword;
}
