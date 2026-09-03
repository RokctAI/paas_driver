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

import 'package:base_sdk/src/handlers/api_result.dart';
import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:auto_route/auto_route.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:base_sdk/src/domain/interface/auth.dart';
import 'package:base_sdk/src/domain/interface/user.dart';
import 'package:base_sdk/src/models/data/address_old_data.dart';
import 'package:base_sdk/src/models/models.dart';
import 'package:base_sdk/src/services/app_connectivity.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/app_validators.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/secure_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
// [refork] removed host router import
import 'package:permission_handler/permission_handler.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:base_sdk/src/domain/interface/settings.dart';

import 'package:auth_sdk/src/common/application/auth/login/login_state.dart';
import 'package:auth_sdk/src/common/domain/interface/auth_session_policy.dart';
import 'package:auth_sdk/src/common/infrastructure/services/offline_auth_service.dart';
import 'package:auth_sdk/src/common/services/auth_error_presenter.dart';
import 'package:auth_sdk/src/common/services/platform_support.dart';
import 'package:auth_sdk/src/common/services/restore_credential_service.dart';

class LoginNotifier extends StateNotifier<LoginState> {
  final AuthRepositoryFacade _authRepository;
  final SettingsRepositoryFacade _settingsRepository;
  final UserRepositoryFacade _userRepositoryFacade;
  final OfflineAuthService _offlineAuth = OfflineAuthService();

  LoginNotifier(
    this._authRepository,
    this._settingsRepository,
    this._userRepositoryFacade,
  ) : super(const LoginState());

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

  void setShowPassword(bool show) {
    state = state.copyWith(showPassword: show);
  }

  void setKeepLogin(bool keep) {
    state = state.copyWith(isKeepLogin: keep);
  }

  Future<void> checkLanguage(BuildContext context) async {
    final lang = LocalStorage.getLanguage();
    if (lang == null) {
      // No language selected yet, check available languages
      final connect = await AppConnectivity.connectivity();
      if (connect) {
        final response = await _settingsRepository.getLanguages();
        if (!mounted) return;
        response.when(
          success: (data) {
            final List<LanguageData> languages = data.data ?? [];
            state = state.copyWith(list: languages);

            // Auto-select if there's only one language
            if (languages.length == 1) {
              // Set as selected language
              LocalStorage.setLanguageData(languages[0]);
              LocalStorage.setLangLtr(languages[0].backward);
              LocalStorage.setLanguageSelected(true);

              // Get translations for this language
              _getTranslations(context, languages[0]);

              // Update state to skip language selection screen
              state = state.copyWith(isSelectLanguage: true);
            } else {
              // Multiple languages available, show selection screen
              state = state.copyWith(isSelectLanguage: false);
            }
          },
          failure: (failure, status) {
            state = state.copyWith(isSelectLanguage: false);
            // Settings fetch: never user-actionable — friendly line only,
            // real cause to telemetry (entry-56 rule).
            AuthErrorPresenter.showTechnical(
              context,
              type: 'auth_languages_load_failed',
              detail: failure,
              statusCode: status,
            );
          },
        );
      } else {
        if (context.mounted) {
          AppHelpers.showNoConnectionSnackBar(context);
        }
      }
    } else {
      // Language already selected, verify it exists in available languages
      final connect = await AppConnectivity.connectivity();
      if (connect) {
        final response = await _settingsRepository.getLanguages();
        if (!mounted) return;
        response.when(
          success: (data) {
            state = state.copyWith(list: data.data ?? []);
            final List<LanguageData> languages = data.data ?? [];
            for (int i = 0; i < languages.length; i++) {
              if (languages[i].id == lang.id) {
                state = state.copyWith(isSelectLanguage: true);
                break;
              }
            }
          },
          failure: (failure, status) {
            state = state.copyWith(isSelectLanguage: false);
            AuthErrorPresenter.showTechnical(
              context,
              type: 'auth_languages_load_failed',
              detail: failure,
              statusCode: status,
            );
          },
        );
      } else {
        if (context.mounted) {
          AppHelpers.showNoConnectionSnackBar(context);
        }
      }
    }
  }

  // Helper method to get translations
  Future<void> _getTranslations(
    BuildContext context,
    LanguageData language,
  ) async {
    final connect = await AppConnectivity.connectivity();
    if (connect) {
      final response = await _settingsRepository.getMobileTranslations();
      response.when(
        success: (data) {
          LocalStorage.setTranslations(data.data);
        },
        failure: (failure, status) {
          AuthErrorPresenter.showTechnical(
            context,
            type: 'auth_translations_load_failed',
            detail: failure,
            statusCode: status,
          );
        },
      );
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }

  checkEmail() {
    return AppValidators.checkEmail(state.email);
  }

  /// The active address a credential exchange came back with, in the shape
  /// LocalStorage persists — identical logic to what each login variant
  /// used to inline four times over.
  AddressData _activeAddressOf(UserModel? user) {
    final AddressNewModel active =
        user?.addresses?.firstWhere(
          (element) => element.active ?? false,
          orElse: () {
            return AddressNewModel();
          },
        ) ??
        AddressNewModel();
    return AddressData(
      title: active.title ?? "",
      address: active.address?.address ?? "",
      location: LocationModel(
        longitude: active.location?.last,
        latitude: active.location?.first,
      ),
    );
  }

  /// One successful credential exchange -> one session, gated by the
  /// composed [AuthSessionPolicy]:
  ///
  ///   * policy allows the account's role -> persist token + active
  ///     address, land wherever the policy says (the default policy lands
  ///     exactly where this code always landed: `isDemo ?
  ///     goHome`), then refresh the FCM token.
  ///   * policy rejects it -> nothing is persisted; the policy presents the
  ///     rejection (message/route). Manager-style compositions use this to
  ///     admit only sellers without owning any auth code.
  Future<void> _establishSession(
    BuildContext context,
    UserData? data, {
    bool popUntilRoot = false,
  }) async {
    final String? role = data?.user?.role;
    if (!AuthSessionPolicy.I.allows(role)) {
      AuthSessionPolicy.I.onRejected(context, role: role);
      return;
    }
    // setToken clears any stale refresh contract, so persist the fresh
    // one strictly after it. Flows that mint none (Google login) simply
    // store nothing — their sessions are never proactively refreshed.
    await LocalStorage.setToken(data?.accessToken ?? '');
    await SecureStorage.setRefreshToken(data?.refreshToken);
    await LocalStorage.setTokenExpiry(data?.expiresAt);
    LocalStorage.setAddressSelected(_activeAddressOf(data?.user));
    if (popUntilRoot) {
      context.router.popUntilRoot();
    }
    AuthSessionPolicy.I.onAuthenticated(context, role: role);
    await syncFcmToken(_userRepositoryFacade);
    // Register an Android restore key for the account that just signed in,
    // so a move to a new device lands them signed in instead of here
    // again. No-ops on every other platform, and on Android once this
    // install already has one. Never blocks or fails the sign-in it
    // follows -- the session is already established by this point.
    await RestoreCredentialService().ensureRestoreKey();
  }

  Future<void> login(BuildContext context) async {
    final connected = await AppConnectivity.connectivity();
    if (!mounted) return;
    if (connected) {
      if (checkEmail()) {
        if (!AppValidators.isValidEmail(state.email)) {
          state = state.copyWith(isEmailNotValid: true);
          return;
        }
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
      if (!mounted) return;
      response.when(
        success: (data) async {
          await _establishSession(context, data.data);
          // onAuthenticated navigates away, which disposes this autoDispose
          // notifier while the session is still being finalised; only
          // touch state if the login screen is still around.
          if (!mounted) return;
          state = state.copyWith(isLoading: false);
        },
        failure: (failure, status) {
          state = state.copyWith(isLoading: false, isLoginError: true);
          // Refusal split: a definitive 4xx carries the backend's own
          // user-actionable copy (wrong credentials) and stays verbatim;
          // anything else shows a friendly line and the raw detail goes
          // to telemetry (entry-56 rule).
          AuthErrorPresenter.show(
            context,
            type: 'auth_login_failed',
            failure: failure,
            statusCode: status,
          );
        },
      );
    } else {
      // No connection — try a local account created via offline
      // registration on this device before giving up. A real backend
      // account that's never been registered offline here simply won't be
      // found; that's a distinct, clearer error than a generic
      // "no connection" snackbar.
      if (!AppValidators.isValidPassword(state.password)) {
        state = state.copyWith(isPasswordNotValid: true);
        return;
      }
      state = state.copyWith(isLoading: true);
      final result = await _offlineAuth.loginOffline(
        phone: state.email,
        email: state.email,
        password: state.password,
      );
      if (!mounted) return;
      state = state.copyWith(isLoading: false);
      if (result.success) {
        // The role of an offline account can't be verified against the
        // backend, so a declared role-gated policy rejects offline sessions
        // outright (its onRejected also removes the offline token
        // loginOffline just stored). The default policy allows them and
        // lands exactly where this branch always landed.
        if (!AuthSessionPolicy.I.allows(null)) {
          LocalStorage.deleteToken();
          if (context.mounted) AuthSessionPolicy.I.onRejected(context);
        } else if (context.mounted) {
          AuthSessionPolicy.I.onAuthenticated(context);
        }
      } else {
        state = state.copyWith(isLoginError: true);
        if (context.mounted) {
          AppHelpers.showCheckTopSnackBar(context, result.error ?? '');
        }
      }
    }
  }

  Future<void> loginWithGoogle(BuildContext context) async {
    final connected = await AppConnectivity.connectivity();
    if (!mounted) return;
    if (connected) {
      state = state.copyWith(isLoading: true);
      GoogleSignInAccount? googleUser;
      try {
        googleUser = await GoogleSignIn().signIn();
      } catch (e) {
        if (!mounted) return;
        state = state.copyWith(isLoading: false);
      }
      if (!mounted) return;
      if (googleUser == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final response = await _authRepository.loginWithGoogle(
        email: googleUser.email,
        displayName: googleUser.displayName ?? '',
        id: googleUser.id,
        avatar: googleUser.photoUrl ?? "",
      );
      if (!mounted) return;
      response.when(
        success: (data) async {
          state = state.copyWith(isLoading: false);
          await _establishSession(context, data.data, popUntilRoot: true);
        },
        failure: (failure, status) {
          state = state.copyWith(isLoading: false);
          AuthErrorPresenter.show(
            context,
            type: 'auth_social_login_failed',
            failure: failure,
            statusCode: status,
            extra: const {'provider': 'google'},
          );
        },
      );
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }

  Future<void> loginWithFacebook(BuildContext context) async {
    final connected = await AppConnectivity.connectivity();
    if (!mounted) return;
    if (connected) {
      state = state.copyWith(isLoading: true);
      final fb = FacebookAuth.instance;
      try {
        TrackingStatus? status;
        if (Platform.isIOS) {
          final permission = await Permission.appTrackingTransparency.request();
          status = await AppTrackingTransparency.trackingAuthorizationStatus;
          debugPrint("permission $permission");
          debugPrint("status: $status");
        }

        final user = await fb.login(
          loginTracking: status == TrackingStatus.authorized
              ? LoginTracking.enabled
              : LoginTracking.limited,
          loginBehavior: LoginBehavior.nativeWithFallback,
        );
        debugPrint(
          '===> login with face token ${user.accessToken?.tokenString}',
        );
        debugPrint('===> login with face authenticationToken ${user.status}');
        final rawNonce = AppHelpers.generateNonce();
        final OAuthCredential credential =
            user.accessToken?.type == AccessTokenType.limited
            ? OAuthCredential(
                providerId: 'facebook.com',
                signInMethod: 'oauth',
                idToken: user.accessToken!.tokenString,
                rawNonce: rawNonce,
              )
            : FacebookAuthProvider.credential(
                user.accessToken?.tokenString ?? "",
              );

        final userObj = await FirebaseAuth.instance.signInWithCredential(
          credential,
        );
        if (!mounted) return;

        if (user.status == LoginStatus.success) {
          final response = await _authRepository.loginWithGoogle(
            email: userObj.user?.email ?? "",
            displayName: userObj.user?.displayName ?? "",
            id: userObj.user?.uid ?? "",
            avatar: userObj.user?.photoURL ?? "",
          );
          if (!mounted) return;
          response.when(
            success: (data) async {
              state = state.copyWith(isLoading: false);
              await _establishSession(context, data.data, popUntilRoot: true);
            },
            failure: (failure, status) {
              state = state.copyWith(isLoading: false);
              AuthErrorPresenter.show(
                context,
                type: 'auth_social_login_failed',
                failure: failure,
                statusCode: status,
                extra: const {'provider': 'facebook'},
              );
            },
          );
        } else {
          state = state.copyWith(isLoading: false);
          if (context.mounted) {
            AppHelpers.showCheckTopSnackBar(
              context,
              AppHelpers.getTranslation(TrKeys.somethingWentWrongWithTheServer),
            );
          }
        }
      } catch (e) {
        if (!mounted) return;
        state = state.copyWith(isLoading: false);
        debugPrint('===> login with face exception: $e');
      }
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }

  Future<void> loginWithApple(BuildContext context) async {
    final connected = await AppConnectivity.connectivity();
    if (!mounted) return;
    if (connected) {
      state = state.copyWith(isLoading: true);

      try {
        final credential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
        );

        OAuthProvider oAuthProvider = OAuthProvider("apple.com");
        final AuthCredential credentialApple = oAuthProvider.credential(
          idToken: credential.identityToken,
          accessToken: credential.authorizationCode,
        );

        final userObj = await FirebaseAuth.instance.signInWithCredential(
          credentialApple,
        );

        final response = await _authRepository.loginWithGoogle(
          email: credential.email ?? userObj.user?.email ?? "",
          displayName: credential.givenName ?? userObj.user?.displayName ?? "",
          id: credential.userIdentifier ?? userObj.user?.uid ?? "",
          avatar: userObj.user?.displayName ?? "",
        );
        if (!mounted) return;
        response.when(
          success: (data) async {
            state = state.copyWith(isLoading: false);
            await _establishSession(context, data.data, popUntilRoot: true);
          },
          failure: (failure, s) {
            state = state.copyWith(isLoading: false);
            AuthErrorPresenter.show(
              context,
              type: 'auth_social_login_failed',
              failure: failure,
              statusCode: s,
              extra: const {'provider': 'apple'},
            );
          },
        );
      } catch (e) {
        if (!mounted) return;
        state = state.copyWith(isLoading: false);
        debugPrint('===> login with apple exception: $e');
      }
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }
}
