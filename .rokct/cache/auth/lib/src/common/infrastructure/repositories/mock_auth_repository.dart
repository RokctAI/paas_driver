// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/domain/interface/auth.dart';
import 'package:base_sdk/src/models/models.dart';
import 'package:base_sdk/src/models/data/address_information.dart';

import 'package:auth_sdk/src/common/domain/interface/deferred_otp_email_resend.dart';
import 'package:auth_sdk/src/common/domain/interface/session_password_rotation.dart';

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

  final UserModel _demoUser = UserModel(
    id: "1",
    uuid: "demo_uuid",
    firstname: "Demo",
    lastname: "User",
    email: "demo@example.com",
    phone: "+1234567890",
    role: "customer",
    active: true,
    img: "https://via.placeholder.com/150",
    addresses: [
      AddressNewModel(
        active: true,
        address: AddressInformation(address: "123 Demo St"),
        id: "1",
        location: [37.7749, -122.4194],
        title: "Home",
      ),
    ],
  );

  ProfileData _mapUserToProfile(UserModel user) {
    return ProfileData(
      id: user.id,
      uuid: user.uuid,
      firstname: user.firstname,
      lastname: user.lastname,
      email: user.email,
      phone: user.phone,
      role: user.role,
      active: user.active,
      img: user.img,
      addresses: user.addresses,
    );
  }

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
          user: _demoUser.copyWith(email: email, role: _roleForEmail(email)),
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
