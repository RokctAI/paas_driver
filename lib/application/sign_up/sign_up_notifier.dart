import 'package:auto_route/auto_route.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:vender/infrastructure/models/data/user_data.dart';
import '../../presentation/routes/app_router.gr.dart';
import 'sign_up_state.dart';
import '../../domain/interface/interfaces.dart';
import '../../infrastructure/services/services.dart';

class SignUpNotifier extends StateNotifier<SignUpState> {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  SignUpNotifier(this._authRepository, this._userRepository)
      : super(const SignUpState());

  Future<void> getProfileDetails() async {
    final response = await _userRepository.getProfileDetails();
    response.when(
      success: (data) {
        LocalStorage.setUser(data.data);
        if (data.data?.wallet != null) {
          LocalStorage.setWallet(data.data?.wallet);
        }
      },
      failure: (failure, status) {
        debugPrint('==> get profile details failure: $failure');
      },
    );
  }

  void setPassword(String password) {
    state = state.copyWith(password: password.trim(), isPasswordInvalid: false);
  }

  void setConfirmPassword(String password) {
    state = state.copyWith(
      confirmPassword: password.trim(),
      isConfirmPasswordInvalid: false,
    );
  }

  void setFirstName(String name) {
    state = state.copyWith(
      firstName: name.trim(),
      isFirstNameInvalid: false,
    );
  }

  void setEmail(String value) {
    state = state.copyWith(email: value.trim(), isEmailInvalid: false);
  }

  void toggleShowPassword() {
    state = state.copyWith(showPassword: !state.showPassword);
  }

  void toggleKeepLogin() {
    state = state.copyWith(isKeepLogin: !state.isKeepLogin);
  }

  checkEmail() {
    return AppValidators.isValidEmail(state.email);
  }

  Future<void> sendCode(BuildContext context, VoidCallback onSuccess) async {
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      if (!AppValidators.isValidEmail(state.email)) {
        state = state.copyWith(isEmailInvalid: true);
        return;
      }
      state = state.copyWith(isLoading: true, isSuccess: false);
      final response = await _authRepository.signUp(
        email: state.email,
      );
      response.when(
        success: (data) async {
          state = state.copyWith(isLoading: false, isSuccess: true);
          onSuccess();
        },
        failure: (failure, status) {
          state = state.copyWith(isLoading: false, isSuccess: false);
          if (status == 400) {
            AppHelpers.showCheckTopSnackBar(
              context,
              AppHelpers.getTranslation(TrKeys.emailIsNotValid),
            );
          } else {
            AppHelpers.showCheckTopSnackBar(
              context,
              failure.toString(),
            );
          }
        },
      );
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }

  Future<void> sendCodeToNumber(
      BuildContext context, ValueChanged<String> onSuccess) async {
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      if (state.phone.isEmpty) {
        state = state.copyWith(isPhoneInvalid: true);
        return;
      }
      state = state.copyWith(isLoading: true, isSuccess: false);
      final res = await _authRepository.checkPhone(phone: state.phone);
      res.when(success: (success) async {
        state = state.copyWith(isLoading: false, isSuccess: false);
        AppHelpers.showCheckTopSnackBar(
          context,
          AppHelpers.getTranslation(TrKeys.userAlready),
        );
      }, failure: (failure, status) async {
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: state.phone,
          verificationCompleted: (PhoneAuthCredential credential) {},
          verificationFailed: (FirebaseAuthException e) {
            AppHelpers.showCheckTopSnackBar(context, e.message ?? '');
            state = state.copyWith(isLoading: false, isSuccess: false);
          },
          codeSent: (String verificationId, int? resendToken) {
            state = state.copyWith(
              verificationId: verificationId,
              phone: state.email,
              isLoading: false,
              isSuccess: true,
            );
            onSuccess(verificationId);
          },
          codeAutoRetrievalTimeout: (String verificationId) {},
        );
      });
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }

  Future<void> register(BuildContext context) async {
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      if (AppValidators.emptyCheck(state.phone)?.isNotEmpty ?? false) {
        state = state.copyWith(isPhoneInvalid: true);
        return;
      }
      if (AppValidators.emptyCheck(state.firstName)?.isNotEmpty ?? false) {
        state = state.copyWith(isFirstNameInvalid: true);
        return;
      }
      if (AppValidators.emptyCheck(state.lastName)?.isNotEmpty ?? false) {
        state = state.copyWith(isSurNameInvalid: true);
        return;
      }
      if (!AppValidators.isValidPassword(state.password)) {
        state = state.copyWith(isPasswordInvalid: true);
        return;
      }
      if (!AppValidators.isValidConfirmPassword(
          state.password, state.confirmPassword)) {
        state = state.copyWith(isConfirmPasswordInvalid: true);
        return;
      }
      state = state.copyWith(isLoading: true);
      final response = await _authRepository.sigUpWithData(
          user: UserData(
        email: state.email,
        firstname: state.firstName,
        lastname: state.lastName,
        phone: state.phone,
        password: state.password,
        confirmPassword: state.confirmPassword,
        referral: state.referral,
      ));

      response.when(
        success: (data) async {
          state = state.copyWith(
            isLoading: false,
          );
          LocalStorage.setToken(data.token);
          context.replaceRoute(const HomeRoute());
          String? fcmToken = await FirebaseMessaging.instance.getToken();
          _userRepository.updateFirebaseToken(fcmToken);
        },
        failure: (failure, status) {
          state = state.copyWith(isLoading: false);
          if (status == 400) {
            AppHelpers.showCheckTopSnackBar(
                context, AppHelpers.getTranslation(TrKeys.referral));
          } else {
            AppHelpers.showCheckTopSnackBar(
              context,
              failure.toString(),
            );
          }
        },
      );
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }

  void setPhone(String value) {
    state = state.copyWith(
      phone: value.trim(),
      isPhoneInvalid: false,
    );
  }

  void setLatName(String name) {
    state = state.copyWith(
      lastName: name.trim(),
      isSurNameInvalid: false,
    );
  }

  void setReferral(String name) {
    state = state.copyWith(referral: name.trim());
  }

  void toggleShowConfirmPassword() {
    state = state.copyWith(showConfirmPassword: !state.showConfirmPassword);
  }

  Future<void> registerWithPhone(BuildContext context, String? phone) async {
    final connected = await AppConnectivity.connectivity();
    state = state.copyWith(isPasswordInvalid: false);
    if (connected) {
      if (AppValidators.emailCheck(state.email)?.isNotEmpty ?? false) {
        state = state.copyWith(isEmailInvalid: true);
        return;
      }
      if (AppValidators.emptyCheck(state.firstName)?.isNotEmpty ?? false) {
        state = state.copyWith(isFirstNameInvalid: true);
        return;
      }
      if (!AppValidators.isValidPassword(state.password)) {
        state = state.copyWith(isPasswordInvalid: true);
        return;
      }
      if (!AppValidators.isValidConfirmPassword(
          state.password, state.confirmPassword)) {
        state = state.copyWith(isConfirmPasswordInvalid: true);
        return;
      }
      state = state.copyWith(isLoading: true);
      final response = await _authRepository.sigUpWithPhone(
          user: UserData(
              email: state.email,
              firstname: state.firstName,
              lastname: state.lastName,
              phone: phone ?? state.phone,
              password: state.password,
              confirmPassword: state.confirmPassword,
              referral: state.referral));

      response.when(
        success: (data) async {
          state = state.copyWith(isLoading: false);
          LocalStorage.setToken(data.token);
          context.replaceRoute(const BecomeDriverRoute());
          String? fcmToken = await FirebaseMessaging.instance.getToken();
          _userRepository.updateFirebaseToken(fcmToken);
        },
        failure: (failure, status) {
          state = state.copyWith(isLoading: false);
          if (status == 400) {
            AppHelpers.showCheckTopSnackBar(context, "error");
          } else {
            AppHelpers.showCheckTopSnackBar(context, "error");
          }
        },
      );
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }
}
