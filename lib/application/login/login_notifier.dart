import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/interface/interfaces.dart';
import '../../infrastructure/services/services.dart';
import 'login_state.dart';

class LoginNotifier extends StateNotifier<LoginState> {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  LoginNotifier(this._authRepository, this._userRepository)
      : super(const LoginState());

  Future<void> loginWithGoogle({
    required BuildContext context,
    VoidCallback? checkYourNetwork,
    Function(String)? errorOccurred,
    VoidCallback? loginSuccess,
    VoidCallback? youAreNotDeliveryman,
  }) async {
    if (await AppConnectivity.connectivity()) {
      state = state.copyWith(isGoogleLoading: true);
      GoogleSignInAccount? googleUser;
      try {
        googleUser = await GoogleSignIn().signIn();
      } catch (e) {
        state = state.copyWith(isGoogleLoading: false);
        debugPrint('===> login with google exception: $e');
        if (errorOccurred != null) {
          errorOccurred(e.toString());
        }
      }
      if (googleUser == null) {
        state = state.copyWith(isGoogleLoading: false);
        return;
      }
      final response = await _authRepository.loginWithSocial(
        email: googleUser.email,
        displayName: googleUser.displayName,
        id: googleUser.id,
      );
      response.when(
        success: (data) async {
          if (data.data?.user?.role != 'deliveryman') {
            state = state.copyWith(isGoogleLoading: false);
            final GoogleSignIn signIn = GoogleSignIn();
            signIn.disconnect();
            signIn.signOut();
            youAreNotDeliveryman?.call();
            return;
          }
          LocalStorage.setToken(data.data?.accessToken ?? '');
          await getProfileDetails(context);
          String? fcmToken;
          try {
            fcmToken = await FirebaseMessaging.instance.getToken();
          } catch (e) {
            debugPrint('===> error with getting firebase token $e');
          }
          _userRepository.updateFirebaseToken(fcmToken);
          state = state.copyWith(isGoogleLoading: false);
          loginSuccess?.call();
        },
        failure: (failure, status) {
          debugPrint('===> login error google $failure');
          state = state.copyWith(isGoogleLoading: false);
          AppHelpers.showCheckTopSnackBar(
            context,
            AppHelpers.getTranslation(failure),
          );
        },
      );
    } else {
      checkYourNetwork?.call();
    }
  }

  Future<void> getProfileDetails(BuildContext context) async {
    final response = await _userRepository.getProfileDetails();
    response.when(
      success: (data) {
        LocalStorage.setUser(data.data);
      },
      failure: (failure, status) {
        debugPrint('==> get profile details failure: $failure');
      },
    );
  }

  void setPassword(String text) {
    state = state.copyWith(
      password: text.trim(),
      isLoginError: false,
      isEmailNotValid: false,
      isPasswordNotValid: false,
    );
  }

  void setEmail(String text) {
    state = state.copyWith(
      email: text.trim(),
      isLoginError: false,
      isEmailNotValid: false,
      isPasswordNotValid: false,
    );
  }

  void toggleShowPassword() {
    state = state.copyWith(showPassword: !state.showPassword);
  }

  void toggleKeepLogin() {
    state = state.copyWith(isKeepLogin: !state.isKeepLogin);
  }

  Future<void> login({
    required BuildContext context,
    VoidCallback? checkYourNetwork,
    VoidCallback? youAreNotDeliveryman,
    VoidCallback? loginSuccess,
  }) async {
    if (await AppConnectivity.connectivity()) {
      if (AppValidators.emptyCheck(state.email)?.isNotEmpty ?? false) {
        state = state.copyWith(isEmailNotValid: true);
        return;
      }
      if (!AppValidators.isValidPassword(state.password)) {
        state = state.copyWith(isPasswordNotValid: true);
        return;
      }
      state = state.copyWith(isLoading: true);
      final response = await _authRepository.login(
        email: state.email,
        password: state.password,
      );
      response.when(
        success: (data) async {
          LocalStorage.setToken(data.data?.accessToken ?? '');
          getProfileDetails(context);
          String? fcmToken;
          try {
            fcmToken = await FirebaseMessaging.instance.getToken();
          } catch (e) {
            debugPrint('===> error with getting firebase token $e');
          }
          _userRepository.updateFirebaseToken(fcmToken);

          state = state.copyWith(isLoading: false, isLoginError: true);
          if (data.data?.user?.role != 'deliveryman') {
            youAreNotDeliveryman?.call();
          } else {
            loginSuccess?.call();
          }
        },
        failure: (failure, status) {
          debugPrint('===> login request failure $failure');
          state = state.copyWith(isLoading: false, isLoginError: true);
          AppHelpers.showCheckTopSnackBar(
            context,
            AppHelpers.getTranslation(failure),
          );
        },
      );
    } else {
      checkYourNetwork?.call();
    }
  }

// Future<void> loginWithGoogle(BuildContext context) async {
//   final connected = await AppConnectivity.connectivity();
//   if (connected) {
//     state = state.copyWith(isLoading: true);
//     GoogleSignInAccount? googleUser;
//     try {
//       googleUser = await GoogleSignIn().signIn();
//     } catch (e) {
//       state = state.copyWith(isLoading: false);
//       debugPrint('===> login with google exception: $e');
//       if (context.mounted) {
//         AppHelpers.showCheckTopSnackBar(
//           context,
//           AppHelpers.getTranslation(e.toString()),
//         );
//       }
//     }
//     if (googleUser == null) {
//       state = state.copyWith(isLoading: false);
//       return;
//     }
//     final response = await _authRepository.loginWithGoogle(
//       email: googleUser.email,
//       displayName: googleUser.displayName ?? '',
//       id: googleUser.id,
//     );
//     response.when(
//       success: (data) async {
//         LocalStorage.setToken(data.data?.accessToken ?? '');
//         String? fcmToken;
//         try {
//           fcmToken = await FirebaseMessaging.instance.getToken();
//         } catch (e) {
//           debugPrint('===> error with getting firebase token');
//         }
//         _userRepository.updateFirebaseToken(fcmToken);
//         final addressResponse = await _addressRepository.getUserAddresses();
//         addressResponse.when(
//           success: (addressData) {
//             log('===> getting address data: $addressData');
//             state = state.copyWith(isLoading: false);
//           },
//           failure: (addressFailure) {
//             state = state.copyWith(isLoading: false);
//             debugPrint('==> address failure: $addressFailure');
//           },
//         );
//       },
//       failure: (failure) {},
//     );
//   } else {
//     if (context.mounted) {
//       AppHelpers.showNoConnectionSnackBar(context);
//     }
//   }
// }
//
// Future<void> loginWithFacebook(BuildContext context) async {
//   final connected = await AppConnectivity.connectivity();
//   if (connected) {
//     state = state.copyWith(isLoading: true);
//     AccessToken? accessToken = await FacebookAuth.instance.accessToken;
//     if (accessToken != null) {
//       final LoginResult loginResult = await FacebookAuth.instance.login();
//       if (loginResult.status == LoginStatus.success) {
//         final userData = await FacebookAuth.instance.getUserData();
//         debugPrint('==> facebook auth email: ${userData['email']}');
//         debugPrint('==> facebook auth name: ${userData['name']}');
//         debugPrint('==> facebook auth id: ${userData['id']}');
//       }
//       accessToken = loginResult.accessToken;
//     } else {
//       final userData = await FacebookAuth.instance.getUserData();
//       debugPrint('==> facebook auth email: ${userData['email']}');
//       debugPrint('==> facebook auth name: ${userData['name']}');
//       debugPrint('==> facebook auth id: ${userData['id']}');
//     }
//     state = state.copyWith(isLoading: false);
//   } else {
//     if (context.mounted) {
//       AppHelpers.showCheckTopSnackBar(
//         context,
//         AppHelpers.getTranslation(TrKeys.checkYourNetworkConnection),
//       );
//     }
//   }
// }
}
