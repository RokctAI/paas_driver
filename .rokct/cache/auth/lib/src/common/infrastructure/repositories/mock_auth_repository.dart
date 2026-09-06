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

import 'package:base_sdk/src/constants/demo_images.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/domain/interface/auth.dart';
import 'package:base_sdk/src/models/models.dart';
import 'package:base_sdk/src/models/data/address_information.dart';

import 'package:auth_sdk/src/common/domain/interface/deferred_otp_email_resend.dart';
import 'package:auth_sdk/src/common/domain/interface/session_password_rotation.dart';
import 'package:auth_sdk/src/common/services/session_profile.dart';

class MockAuthRepository
    implements
        AuthRepositoryFacade,
        DeferredOtpEmailResend,
        SessionPasswordRotation {
  /// Demo-only email -> role mapping so the guided tour (and manual demo
  /// sign-ins) can pick a mode by signing in with a well-known address.
  /// Any other email keeps the default "customer" role.
  ///
  /// Role strings are the exact values the composed apps' session policies
  /// gate on (auth_session_policy.dart DeclaredSessionPolicy.roleLandings,
  /// declared as "session_policy" in each home SDK's manifest.json):
  ///  - 'deliveryman': zones/delivery dart/manifest.json (app_type.driver)
  ///    admits deliveryman -> /home, so driver@ lands the paas_driver
  ///    courier home instead of the '*' fallback /become-driver.
  ///  - 'seller': commerce/merchants dart/manifest.json (app_type.manager)
  ///    admits only seller -> /main, so manager@ is the address that can
  ///    sign in to paas_manager at all.
  static const Map<String, String> _demoRolesByEmail = <String, String>{
    'partner@demo.rokct.ai': 'partner',
    'admin@demo.rokct.ai': 'admin',
    'driver@demo.rokct.ai': 'deliveryman',
    'manager@demo.rokct.ai': 'seller',
  };

  static String _roleForEmail(String email) =>
      _demoRolesByEmail[email.trim().toLowerCase()] ?? 'customer';

  /// The account every demo sign-in lands on. Display data only: the
  /// sign-in ADDRESS decides the role ([_demoRolesByEmail]) and nothing
  /// else - [login] hands back THIS account, email included, whatever was
  /// typed, so a tour's sign-in address (`demo.student@example.com`,
  /// `manager@demo.rokct.ai`) can never reach a profile header. It is
  /// what the account surfaces render (profile header, edit-profile sheet,
  /// address book), so it has to read like a real person: the old fixture
  /// wording (a Demo name, a placeholder-host avatar, a Demo St address)
  /// reached the published tour stills. Thandi Mokoena is the seller
  /// commerce's demo shop already seeds. Kept in step with users_sdk's
  /// `MockUserRepository` and `MockAddressRepository`, which serve the same
  /// account once the session exists.
  final UserModel _demoUser = UserModel(
    id: "1",
    uuid: "demo_uuid",
    firstname: "Thandi",
    lastname: "Mokoena",
    email: "thandi.mokoena@outlook.com",
    phone: "+27 82 456 7890",
    role: "customer",
    active: true,
    // base_sdk's inline `data:` SVG initials avatar: carries its own
    // pixels, so it renders offline and on the CI tour emulator, and it is
    // the one avatar users_sdk's MockUserRepository serves too.
    img: DemoImages.avatar,
    addresses: [
      AddressNewModel(
        active: true,
        address: AddressInformation(address: "42 Marula Avenue, Sandton"),
        id: "1",
        location: [-26.1076, 28.0567],
        title: "Home",
      ),
    ],
  );

  ProfileData _mapUserToProfile(UserModel user) => sessionProfileOf(user);

  @override
  Future<ApiResult<VerifyData>> forgotPasswordConfirm({
    required String verifyCode,
    required String email,
  }) async {
    return ApiResult.success(
      data: VerifyData(token: "demo_token", user: _mapUserToProfile(_demoUser)),
    );
  }

  @override
  Future<ApiResult<VerifyData>> forgotPasswordConfirmWithPhone({
    required String phone,
  }) async {
    return ApiResult.success(
      data: VerifyData(
        token: "demo_token",
        user: _mapUserToProfile(_demoUser.copyWith(phone: phone)),
      ),
    );
  }

  @override
  Future<ApiResult<RegisterResponse>> forgotPassword({
    required String email,
  }) async {
    return ApiResult.success(
      data: RegisterResponse(
        data: RegisterData(verifyId: "demo_verify_id", phone: "1234567890"),
      ),
    );
  }

  @override
  Future<ApiResult<LoginResponse>> login({
    required String email,
    required String password,
  }) async {
    return ApiResult.success(
      data: LoginResponse(
        data: UserData(
          accessToken: "demo_access_token",
          tokenType: "Bearer",
          // The typed address is a credential and a role selector, not an
          // identity: the account signed in is always [_demoUser], email
          // included. Echoing the address here is how a tour's sign-in
          // ("demo.student@example.com", "manager@demo.rokct.ai") reached
          // the profile header once LoginNotifier started persisting the
          // login user (1.10.3).
          user: _demoUser.copyWith(role: _roleForEmail(email)),
        ),
      ),
    );
  }

  @override
  Future<ApiResult<LoginResponse>> loginWithGoogle({
    required String email,
    required String displayName,
    required String id,
    required String avatar,
  }) async {
    return ApiResult.success(
      data: LoginResponse(
        data: UserData(
          accessToken: "demo_google_token",
          tokenType: "Bearer",
          user: _demoUser.copyWith(
            email: email,
            firstname: displayName,
            img: avatar,
          ),
        ),
      ),
    );
  }

  @override
  Future<ApiResult<RegisterResponse>> sendOtp({required String phone}) async {
    return ApiResult.success(
      data: RegisterResponse(
        data: RegisterData(verifyId: "demo_verify_id", phone: phone),
      ),
    );
  }

  @override
  Future<ApiResult<dynamic>> sigUp({required String email}) async {
    return ApiResult.success(data: null);
  }

  @override
  Future<ApiResult<dynamic>> resendVerificationEmail({
    required String email,
  }) async {
    return const ApiResult.success(data: null);
  }

  @override
  Future<ApiResult<dynamic>> updateSessionPassword({
    required String password,
    required String passwordConfirmation,
  }) async {
    return const ApiResult.success(data: null);
  }

  @override
  Future<ApiResult<VerifyData>> sigUpWithData({
    required UserModel user,
    String? idempotencyKey,
  }) async {
    return ApiResult.success(
      data: VerifyData(token: "demo_token", user: _mapUserToProfile(user)),
    );
  }

  @override
  Future<ApiResult<VerifyData>> sigUpWithPhone({
    required UserModel user,
  }) async {
    return ApiResult.success(
      data: VerifyData(token: "demo_token", user: _mapUserToProfile(user)),
    );
  }

  @override
  Future<ApiResult<VerifyPhoneResponse>> verifyEmail({
    required String verifyCode,
  }) async {
    return ApiResult.success(
      data: VerifyPhoneResponse(
        data: VerifyData(
          token: "demo_token",
          user: _mapUserToProfile(_demoUser),
        ),
      ),
    );
  }

  @override
  Future<ApiResult<VerifyPhoneResponse>> verifyPhone({
    required String verifyCode,
    required String verifyId,
  }) async {
    return ApiResult.success(
      data: VerifyPhoneResponse(
        data: VerifyData(
          token: "demo_token",
          user: _mapUserToProfile(_demoUser),
        ),
      ),
    );
  }
}
