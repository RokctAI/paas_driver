import 'package:driver/infrastructure/services/services.dart';

class AppValidators {
  static bool isValidEmail(String email) => RegExp(
    "^[a-zA-Z0-9.!#\$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*\$",
  ).hasMatch(email);

  static bool isValidPassword(String password) => password.length > 5;

  static bool isValidConfirmPassword(String password, String confirmPassword) =>
      password == confirmPassword;

  static bool arePasswordsTheSame(String password, String confirmPassword) =>
      password == confirmPassword;

  static String? emptyCheck(String? text) {
    if (text == null || text.trim().isEmpty) {
      return AppHelpers.getTranslation(TrKeys.cannotBeEmpty);
    }
    return null;
  }

  static String? emailCheck(String? text) {
    if (text == null || text.trim().isEmpty) {
      return AppHelpers.getTranslation(TrKeys.cannotBeEmpty);
    }
    if (!_isValidEmail(text)) {
      return AppHelpers.getTranslation(TrKeys.emailIsNotValid);
    }
    return null;
  }

  static bool _isValidEmail(String email) => RegExp(
    "^[a-zA-Z0-9.!#\$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*\$",
  ).hasMatch(email);

  static bool isValidEmail2(String input) => RegExp(
    r"^[a-zA-Z0-9.!#\$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+\.[a-zA-Z]{2,}$",
  ).hasMatch(input);

  static String? passwordCheck(String? text) {
    if (text == null || text.trim().isEmpty) {
      return AppHelpers.getTranslation(TrKeys.cannotBeEmpty);
    }
    if (text.length < 6) {
      return AppHelpers.getTranslation(
        TrKeys.passwordShouldContainMinimum6Characters,
      );
    }
    return null;
  }

  static bool isValidPhone(String input) =>
      RegExp(r"^\+?[0-9]{7,15}$").hasMatch(input);

  static String detectType(String input) {
    print(input);
    if (isValidEmail2(input)) {
      return TrKeys.email;
    }
    if (isValidPhone(input)) {
      return TrKeys.phone;
    } else {
      return TrKeys.invalid;
    }
  }
}
