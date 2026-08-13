import 'dart:async';

import 'package:base_sdk/src/navigation/app_routes.dart';

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
import 'package:base_sdk/src/models/request/edit_profile.dart';
import 'package:base_sdk/src/services/app_connectivity.dart';
import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/app_validators.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
// [refork] removed host router import
import 'package:permission_handler/permission_handler.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/sync/sync_engine.dart';
import 'package:auth_sdk/src/common/application/auth/register/register_state.dart';
import 'package:auth_sdk/src/common/infrastructure/services/auth_sync_handler.dart';
import 'package:auth_sdk/src/common/infrastructure/services/offline_auth_service.dart';
import 'package:auth_sdk/src/common/presentation/pages/auth/registration/registration_steps_page.dart';
import 'package:auth_sdk/src/common/services/platform_support.dart';

class RegisterNotifier extends StateNotifier<RegisterState> {
  final AuthRepositoryFacade _authRepository;
  final UserRepositoryFacade _userRepositoryFacade;
  final OfflineAuthService _offlineAuth = OfflineAuthService();

  RegisterNotifier(this._authRepository, this._userRepositoryFacade)
    : super(const RegisterState());

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
    state = state.copyWith(firstName: name.trim());
  }

  void setEmail(String value) {
    state = state.copyWith(email: value.trim(), isEmailInvalid: false);
  }

  void setPhone(String value) {
    state = state.copyWith(phone: value.trim());
  }

  void setLatName(String name) {
    state = state.copyWith(lastName: name.trim());
  }

  void setReferral(String name) {
    state = state.copyWith(referral: name.trim());
  }

  void toggleShowPassword() {
    state = state.copyWith(showPassword: !state.showPassword);
  }

  void toggleShowConfirmPassword() {
    state = state.copyWith(showConfirmPassword: !state.showConfirmPassword);
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
      final response = await _authRepository.sigUp(email: state.email);
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
              AppHelpers.getTranslation(
                AppHelpers.getTranslation(TrKeys.emailAlreadyExists),
              ),
            );
          } else {
            AppHelpers.showCheckTopSnackBar(context, failure);
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
    BuildContext context,
    ValueChanged<String> onSuccess,
  ) async {
    // Firebase phone verification has no desktop implementation — fail
    // fast instead of hanging the spinner until the plugin call dies.
    // (The backend-OTP branch below is plain HTTP and works everywhere.)
    if (AppConstants.isPhoneFirebase && !isMobilePlatform) {
      AppHelpers.showCheckTopSnackBar(
        context,
        AppHelpers.getTranslation(trPhoneVerificationNotAvailableOnDesktop),
      );
      return;
    }
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      state = state.copyWith(isLoading: true, isSuccess: false);
      if (AppConstants.isPhoneFirebase) {
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: state.email,
          verificationCompleted: (PhoneAuthCredential credential) {},
          verificationFailed: (FirebaseAuthException e) {
            AppHelpers.showCheckTopSnackBar(
              context,
              AppHelpers.getTranslation(e.message ?? ""),
            );
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
          codeAutoRetrievalTimeout: (String verificationId) {
            state = state.copyWith(isLoading: false, isSuccess: false);
          },
        );
      } else {
        final response = await _authRepository.sendOtp(phone: state.email);
        response.when(
          success: (success) {
            state = state.copyWith(
              verificationId: success.data?.verifyId ?? '',
              phone: state.email,
              isLoading: false,
              isSuccess: true,
            );
            onSuccess(success.data?.verifyId ?? '');
          },
          failure: (failure, status) {
            AppHelpers.showCheckTopSnackBar(context, failure);
            state = state.copyWith(isLoading: false, isSuccess: false);
          },
        );
      }
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }

  /// Local-first registration (Ray's flow): the account is written to the
  /// local DB before any network I/O, so registration always succeeds on
  /// this device. Backend reachable (connectivity check + the register call
  /// itself as the test) -> the existing online registration path runs and
  /// the local row is reconciled with the real backend identity. Unreachable
  /// -> the local account stands, an `auth.register` op is enqueued on the
  /// SyncEngine, and OTP verification is deferred to sync time.
  Future<void> register(BuildContext context) async {
    if (!AppValidators.isValidPassword(state.password)) {
      state = state.copyWith(isPasswordInvalid: true);
      return;
    }
    if (!AppValidators.isValidConfirmPassword(
      state.password,
      state.confirmPassword,
    )) {
      state = state.copyWith(isConfirmPasswordInvalid: true);
      return;
    }
    state = state.copyWith(isLoading: true);
    final local = await _offlineAuth.registerOffline(
      phone: state.phone,
      email: state.email,
      firstName: state.firstName,
      lastName: state.lastName,
      password: state.password,
      referral: state.referral,
    );
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      final response = await _authRepository.sigUpWithData(
        user: UserModel(
          email: state.email,
          firstname: state.firstName,
          lastname: state.lastName,
          phone: state.phone,
          password: state.password,
          confirmPassword: state.confirmPassword,
          referral: state.referral,
        ),
      );

      response.when(
        success: (data) async {
          state = state.copyWith(isLoading: false);
          // Reconcile the local-first row: the backend account now exists,
          // so the sync path must treat this row as done.
          if (local.success) {
            await _offlineAuth.markSynced(
              local.localUserId!,
              backendUserId: data.user?.id?.toString(),
              backendToken: data.token,
            );
          }
          LocalStorage.setToken(data.token);
          LocalStorage.setAddressSelected(
            AddressData(
              title:
                  data.user?.addresses
                      ?.firstWhere(
                        (element) => element.active ?? false,
                        orElse: () {
                          return AddressNewModel();
                        },
                      )
                      .title ??
                  "",
              address:
                  data.user?.addresses
                      ?.firstWhere(
                        (element) => element.active ?? false,
                        orElse: () {
                          return AddressNewModel();
                        },
                      )
                      .address
                      ?.address ??
                  "",
              location: LocationModel(
                longitude: data.user?.addresses
                    ?.firstWhere(
                      (element) => element.active ?? false,
                      orElse: () {
                        return AddressNewModel();
                      },
                    )
                    .location
                    ?.last,
                latitude: data.user?.addresses
                    ?.firstWhere(
                      (element) => element.active ?? false,
                      orElse: () {
                        return AddressNewModel();
                      },
                    )
                    .location
                    ?.first,
              ),
            ),
          );
          // Registration succeeded: run any SDK-contributed registration
          // steps (school/grade capture, ...), then land on the same
          // destination as before — see RegistrationFlow.
          RegistrationFlow.completeRegistration(context, user: data.user);
          await syncFcmToken(_userRepositoryFacade);
        },
        failure: (failure, status) async {
          // The register call doubles as the reachability test: 5xx and
          // timeouts mean "backend unreachable" -> fall through to the
          // offline outcome with the local account intact.
          if (local.success && !_isDefinitiveRejection(status)) {
            await _completeOffline(context, local);
            return;
          }
          // Definitive backend rejection: roll back the local-first row so
          // a corrected retry isn't blocked by "account already exists".
          if (local.success) {
            await _offlineAuth.discardLocal(local.localUserId!);
          }
          state = state.copyWith(isLoading: false);
          if (status == 400) {
            AppHelpers.showCheckTopSnackBar(
              context,
              AppHelpers.getTranslation(
                AppHelpers.getTranslation(TrKeys.referralIncorrect),
              ),
            );
          } else {
            AppHelpers.showCheckTopSnackBar(context, failure);
          }
        },
      );
    } else {
      // No connection — the local account written above stands and the
      // user proceeds with the offline session. It gets synced to the
      // backend (and OTP verified) once connectivity returns; see
      // OfflineAuthService and AuthSyncHandler.
      await _completeOffline(context, local);
    }
  }

  /// Offline outcome shared by register/registerWithPhone: keep the local
  /// account, queue its backend registration, run the registration steps.
  Future<void> _completeOffline(
    BuildContext context,
    OfflineAuthResult local, {
    bool enqueueSync = true,
  }) async {
    if (!local.success) {
      state = state.copyWith(isLoading: false);
      if (context.mounted) {
        AppHelpers.showCheckTopSnackBar(context, local.error ?? '');
      }
      return;
    }
    if (enqueueSync) {
      await _enqueueRegisterSync(local.localUserId!);
    }
    state = state.copyWith(isLoading: false);
    if (context.mounted) {
      // Registration succeeded: run any SDK-contributed registration
      // steps (school/grade capture, ...), then land on the same
      // destination as before — see RegistrationFlow.
      RegistrationFlow.completeRegistration(context, user: null);
    }
  }

  /// Queue the `auth.register` op. No kick: this path runs while the
  /// backend is unreachable; the engine drains on boot and on connectivity
  /// regain.
  Future<void> _enqueueRegisterSync(String localUserId) {
    return SyncEngine().enqueue(
      opType: AuthSyncHandler.opType,
      sdk: AuthSyncHandler.sdkName,
      payload: {'localUserId': localUserId},
      tempIds: [AuthSyncHandler.tempIdFor(localUserId)],
    );
  }

  /// Mirrors NetworkExceptions.getDioStatus: connection failures and
  /// timeouts surface as 500 (and 408), so only a concrete 4xx is a
  /// definitive backend rejection.
  static bool _isDefinitiveRejection(int status) =>
      status >= 400 && status < 500 && status != 408;

  Future<void> registerWithFirebase(BuildContext context) async {
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      if (!AppValidators.isValidPassword(state.password)) {
        state = state.copyWith(isPasswordInvalid: true);
        return;
      }
      if (!AppValidators.isValidConfirmPassword(
        state.password,
        state.confirmPassword,
      )) {
        state = state.copyWith(isConfirmPasswordInvalid: true);
        return;
      }
      state = state.copyWith(isLoading: true);
      final response = await _authRepository.sigUpWithPhone(
        user: UserModel(
          email: state.email,
          firstname: state.firstName,
          lastname: state.lastName,
          phone: state.phone,
          password: state.password,
          confirmPassword: state.confirmPassword,
          referral: state.referral,
        ),
      );

      response.when(
        success: (data) async {
          state = state.copyWith(isLoading: false);
          LocalStorage.setToken(data.token);
          LocalStorage.setAddressSelected(
            AddressData(
              title:
                  data.user?.addresses
                      ?.firstWhere(
                        (element) => element.active ?? false,
                        orElse: () {
                          return AddressNewModel();
                        },
                      )
                      .title ??
                  "",
              address:
                  data.user?.addresses
                      ?.firstWhere(
                        (element) => element.active ?? false,
                        orElse: () {
                          return AddressNewModel();
                        },
                      )
                      .address
                      ?.address ??
                  "",
              location: LocationModel(
                longitude: data.user?.addresses
                    ?.firstWhere(
                      (element) => element.active ?? false,
                      orElse: () {
                        return AddressNewModel();
                      },
                    )
                    .location
                    ?.last,
                latitude: data.user?.addresses
                    ?.firstWhere(
                      (element) => element.active ?? false,
                      orElse: () {
                        return AddressNewModel();
                      },
                    )
                    .location
                    ?.first,
              ),
            ),
          );
          // Registration succeeded: run any SDK-contributed registration
          // steps (school/grade capture, ...), then land on the same
          // destination as before — see RegistrationFlow.
          RegistrationFlow.completeRegistration(context, user: data.user);
          await syncFcmToken(_userRepositoryFacade);
        },
        failure: (failure, status) {
          state = state.copyWith(isLoading: false);
          if (status == 400) {
            AppHelpers.showCheckTopSnackBar(
              context,
              AppHelpers.getTranslation(
                AppHelpers.getTranslation(TrKeys.referralIncorrect),
              ),
            );
          } else {
            AppHelpers.showCheckTopSnackBar(context, failure);
          }
        },
      );
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }

  /// Same local-first shape as [register], with one difference: this method
  /// runs after a successful phone-OTP step, so a real backend account and
  /// session already exist (created at verify time) and the online call is
  /// a profile completion. The local row is therefore never enqueued for
  /// `auth.register` while a real session is active — that push would
  /// re-register an existing phone and be rejected.
  Future<void> registerWithPhone(BuildContext context) async {
    if (!AppValidators.isValidPassword(state.password)) {
      state = state.copyWith(isPasswordInvalid: true);
      return;
    }
    if (!AppValidators.isValidConfirmPassword(
      state.password,
      state.confirmPassword,
    )) {
      state = state.copyWith(isConfirmPasswordInvalid: true);
      return;
    }
    state = state.copyWith(isLoading: true);
    // The form's single identifier field holds the phone here (see
    // sendCodeToNumber). registerOffline never overwrites the real session
    // token stored by the OTP step.
    final local = await _offlineAuth.registerOffline(
      phone: state.email,
      firstName: state.firstName,
      lastName: state.lastName,
      password: state.password,
      referral: state.referral,
    );
    final activeToken = LocalStorage.getToken();
    final hasBackendSession =
        activeToken.isNotEmpty &&
        !OfflineAuthService.isOfflineToken(activeToken);
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      final response = await _userRepositoryFacade.editProfile(
        user: EditProfile(
          // email: state.email,
          firstname: state.firstName,
          lastname: state.lastName,
          phone: state.email,
          password: state.password,
          confirmPassword: state.confirmPassword,
          referral: state.referral,
        ),
      );

      response.when(
        success: (data) async {
          state = state.copyWith(isLoading: false);
          // Reconcile the local-first row: the backend account exists (the
          // OTP step created it), so the sync path must not push it.
          if (local.success) {
            await _offlineAuth.markSynced(
              local.localUserId!,
              backendUserId: data.data?.id?.toString(),
              backendToken: hasBackendSession ? activeToken : null,
            );
          }
          // Registration succeeded: run any SDK-contributed registration
          // steps (school/grade capture, ...), then land on the same
          // destination as before — see RegistrationFlow.
          RegistrationFlow.completeRegistration(context, user: data.data);
          await syncFcmToken(_userRepositoryFacade);
        },
        failure: (failure, status) async {
          if (local.success && !_isDefinitiveRejection(status)) {
            // Unreachable mid-flow: keep the local account and proceed.
            // Enqueue only when no real backend session exists — with one,
            // the account is already registered and only the profile
            // completion was lost (needs a profile-edit op type to queue;
            // follow-up, see PR).
            await _completeOffline(
              context,
              local,
              enqueueSync: !hasBackendSession,
            );
            return;
          }
          if (local.success) {
            await _offlineAuth.discardLocal(local.localUserId!);
          }
          state = state.copyWith(isLoading: false);
          if (status == 400) {
            AppHelpers.showCheckTopSnackBar(
              context,
              AppHelpers.getTranslation(
                AppHelpers.getTranslation(TrKeys.referralIncorrect),
              ),
            );
          } else {
            AppHelpers.showCheckTopSnackBar(context, failure);
          }
        },
      );
    } else {
      // No connection — the local account stands; verification is deferred
      // to the post-sync OTP step (see OfflineAuthService.syncOne).
      await _completeOffline(context, local, enqueueSync: !hasBackendSession);
    }
  }

  Future<void> loginWithGoogle(BuildContext context) async {
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      state = state.copyWith(isLoading: true);
      GoogleSignInAccount? googleUser;
      try {
        googleUser = await GoogleSignIn().signIn();
      } catch (e) {
        state = state.copyWith(isLoading: false);
        debugPrint('===> login with google exception: $e');
        if (context.mounted) {
          AppHelpers.showCheckTopSnackBar(
            context,
            AppHelpers.getTranslation(e.toString()),
          );
        }
      }
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
      response.when(
        success: (data) async {
          state = state.copyWith(isLoading: false);
          LocalStorage.setToken(data.data?.accessToken ?? '');
          LocalStorage.setAddressSelected(
            AddressData(
              title:
                  data.data?.user?.addresses
                      ?.firstWhere(
                        (element) => element.active ?? false,
                        orElse: () {
                          return AddressNewModel();
                        },
                      )
                      .title ??
                  "",
              address:
                  data.data?.user?.addresses
                      ?.firstWhere(
                        (element) => element.active ?? false,
                        orElse: () {
                          return AddressNewModel();
                        },
                      )
                      .address
                      ?.address ??
                  "",
              location: LocationModel(
                longitude: data.data?.user?.addresses
                    ?.firstWhere(
                      (element) => element.active ?? false,
                      orElse: () {
                        return AddressNewModel();
                      },
                    )
                    .location
                    ?.last,
                latitude: data.data?.user?.addresses
                    ?.firstWhere(
                      (element) => element.active ?? false,
                      orElse: () {
                        return AddressNewModel();
                      },
                    )
                    .location
                    ?.first,
              ),
            ),
          );
          context.router.popUntilRoot();
          if (AppConstants.isDemo) {
            AppRoutes.I.replaceUiTypeRoute(context);
          } else {
            AppHelpers.goHome(context);
          }
          await syncFcmToken(_userRepositoryFacade);
        },
        failure: (failure, status) {
          state = state.copyWith(isLoading: false);
          AppHelpers.showCheckTopSnackBar(context, failure);
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

        if (user.status == LoginStatus.success) {
          final response = await _authRepository.loginWithGoogle(
            email: userObj.user?.email ?? "",
            displayName: userObj.user?.displayName ?? "",
            id: userObj.user?.uid ?? "",
            avatar: userObj.user?.photoURL ?? "",
          );
          response.when(
            success: (data) async {
              state = state.copyWith(isLoading: false);
              LocalStorage.setToken(data.data?.accessToken ?? '');
              LocalStorage.setAddressSelected(
                AddressData(
                  title:
                      data.data?.user?.addresses
                          ?.firstWhere(
                            (element) => element.active ?? false,
                            orElse: () {
                              return AddressNewModel();
                            },
                          )
                          .title ??
                      "",
                  address:
                      data.data?.user?.addresses
                          ?.firstWhere(
                            (element) => element.active ?? false,
                            orElse: () {
                              return AddressNewModel();
                            },
                          )
                          .address
                          ?.address ??
                      "",
                  location: LocationModel(
                    longitude: data.data?.user?.addresses
                        ?.firstWhere(
                          (element) => element.active ?? false,
                          orElse: () {
                            return AddressNewModel();
                          },
                        )
                        .location
                        ?.last,
                    latitude: data.data?.user?.addresses
                        ?.firstWhere(
                          (element) => element.active ?? false,
                          orElse: () {
                            return AddressNewModel();
                          },
                        )
                        .location
                        ?.first,
                  ),
                ),
              );
              context.router.popUntilRoot();
              AppHelpers.goHome(context);
              await syncFcmToken(_userRepositoryFacade);
            },
            failure: (failure, status) {
              state = state.copyWith(isLoading: false);
              AppHelpers.showCheckTopSnackBar(context, failure);
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
        response.when(
          success: (data) async {
            state = state.copyWith(isLoading: false);
            LocalStorage.setToken(data.data?.accessToken ?? '');
            LocalStorage.setAddressSelected(
              AddressData(
                title:
                    data.data?.user?.addresses
                        ?.firstWhere(
                          (element) => element.active ?? false,
                          orElse: () {
                            return AddressNewModel();
                          },
                        )
                        .title ??
                    "",
                address:
                    data.data?.user?.addresses
                        ?.firstWhere(
                          (element) => element.active ?? false,
                          orElse: () {
                            return AddressNewModel();
                          },
                        )
                        .address
                        ?.address ??
                    "",
                location: LocationModel(
                  longitude: data.data?.user?.addresses
                      ?.firstWhere(
                        (element) => element.active ?? false,
                        orElse: () {
                          return AddressNewModel();
                        },
                      )
                      .location
                      ?.last,
                  latitude: data.data?.user?.addresses
                      ?.firstWhere(
                        (element) => element.active ?? false,
                        orElse: () {
                          return AddressNewModel();
                        },
                      )
                      .location
                      ?.first,
                ),
              ),
            );
            context.router.popUntilRoot();
            if (AppConstants.isDemo) {
              AppRoutes.I.replaceUiTypeRoute(context);
            }
            {
              AppHelpers.goHome(context);
            }
            await syncFcmToken(_userRepositoryFacade);
          },
          failure: (failure, s) {
            state = state.copyWith(isLoading: false);
            AppHelpers.showCheckTopSnackBar(
              context,
              AppHelpers.getTranslation(s.toString()),
            );
          },
        );
      } catch (e) {
        state = state.copyWith(isLoading: false);
        debugPrint('===> login with apple exception: $e');
        if (context.mounted) {
          AppHelpers.showCheckTopSnackBar(
            context,
            AppHelpers.getTranslation(e.toString()),
          );
        }
      }
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }
}
