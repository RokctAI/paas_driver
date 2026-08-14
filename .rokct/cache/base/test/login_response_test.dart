import 'package:flutter_test/flutter_test.dart';

import 'package:base_sdk/src/models/response/login_response.dart';

void main() {
  group('LoginResponse / UserData parsing', () {
    test('parses the full login contract incl. refresh_token/expires_at',
        () {
      final response = LoginResponse.fromJson({
        'timestamp': '2026-08-14 09:00:00',
        'status': true,
        'message': 'Logged In',
        'data': {
          'access_token': 'apikey:apisecret',
          'refresh_token': 'refresh-32-chars',
          'expires_at': '2026-08-15 09:00:00',
          'token_type': 'Bearer',
        },
      });
      expect(response.status, isTrue);
      expect(response.data?.accessToken, 'apikey:apisecret');
      expect(response.data?.refreshToken, 'refresh-32-chars');
      expect(response.data?.expiresAt, '2026-08-15 09:00:00');
      expect(response.data?.tokenType, 'Bearer');
    });

    test('tolerates responses without a refresh contract (Google/OTP)', () {
      final data = UserData.fromJson({
        'access_token': 'apikey:apisecret',
        'token_type': 'Bearer',
      });
      expect(data.accessToken, 'apikey:apisecret');
      expect(data.refreshToken, isNull);
      expect(data.expiresAt, isNull);
    });

    test('round-trips through toJson', () {
      final data = UserData.fromJson({
        'access_token': 'a:b',
        'refresh_token': 'r',
        'expires_at': '2026-08-15 09:00:00',
        'token_type': 'Bearer',
      });
      final json = data.toJson();
      expect(json['refresh_token'], 'r');
      expect(json['expires_at'], '2026-08-15 09:00:00');
    });

    test('failure shape (status:false) parses with null data', () {
      final response = LoginResponse.fromJson({
        'status': false,
        'message': 'Invalid refresh token',
      });
      expect(response.status, isFalse);
      expect(response.data, isNull);
    });
  });
}
