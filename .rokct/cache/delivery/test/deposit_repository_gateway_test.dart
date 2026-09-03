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

// Gateway contract for the driver's deposit calls (frames 49g/49h/49i).
// They travel the universal platform gateway under wallet's own
// `api.wallet.*` aliases and payment's `api.payment.get_wallet_balance`;
// the slip is the one multipart exception and goes up through base's
// gallery seam BEFORE the deposit call, so only its URL rides the
// envelope. These tests pin the cmds, the payload shape, and that a
// failed upload never reaches the gateway.

import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/domain/interface/gallery.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:base_sdk/src/models/response/gallery_upload_response.dart';
import 'package:base_sdk/src/models/response/multi_gallery_upload_response.dart';
import 'package:base_sdk/src/services/enums.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/deposit_request.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/deposit_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/recording_http_service.dart';

class _FakeGallery implements GalleryRepositoryFacade {
  _FakeGallery({this.url, this.fail = false});

  final String? url;
  final bool fail;
  final List<(String, UploadType)> uploads = [];

  @override
  Future<ApiResult<GalleryUploadResponse>> uploadImage(
    String file,
    UploadType uploadType,
  ) async {
    uploads.add((file, uploadType));
    if (fail) {
      return const ApiResult.failure(error: 'upload refused', statusCode: 413);
    }
    return ApiResult.success(
      data: GalleryUploadResponse(status: true, imageData: ImageData(title: url)),
    );
  }

  @override
  Future<ApiResult<MultiGalleryUploadResponse>> uploadMultiImage(
    List<String?> filePaths,
    UploadType uploadType,
  ) =>
      throw UnimplementedError();
}

_FakeGallery _installGallery({String? url, bool fail = false}) {
  final gallery = _FakeGallery(url: url, fail: fail);
  if (getIt.isRegistered<GalleryRepositoryFacade>()) {
    getIt.unregister<GalleryRepositoryFacade>();
  }
  getIt.registerSingleton<GalleryRepositoryFacade>(gallery);
  return gallery;
}

T _data<T>(ApiResult<T> result) => switch (result) {
      Success(:final data) => data,
      Failure(:final error) => throw StateError('unexpected failure: $error'),
    };

void main() {
  tearDown(() async {
    await getIt.reset();
  });

  group('getDestination', () {
    test('posts api.wallet.get_deposit_destination and types the account',
        () async {
      final http = RecordingHttpService.install((_) => {
            'accepting': 1,
            'account_holder_name': 'Rokct Ops',
            'bank_name': 'FNB',
            'account_number': '62000004417',
            'branch_code': '250655',
            'account_type': 'Cheque',
          });

      final result = _data(await DriverDepositRepository().getDestination());

      final request = http.single;
      expect(request.method, 'POST');
      expect(request.path, kPlatformGatewayPath);
      expect(request.cmd, 'api.wallet.get_deposit_destination');
      expect(result.accepting, isTrue);
      expect(result.bankName, 'FNB');
      expect(result.accountNumber, '62000004417');
      expect(result.maskedAccountNumber, endsWith('4417'));
    });
  });

  group('getWalletBalance', () {
    test('posts api.payment.get_wallet_balance and reads the figure',
        () async {
      final http = RecordingHttpService.install(
        (_) => {'balance': -1240.0, 'currency': 'ZAR'},
      );

      final balance = _data(await DriverDepositRepository().getWalletBalance());

      expect(http.single.cmd, 'api.payment.get_wallet_balance');
      expect(balance, -1240.0);
    });
  });

  group('listMyDeposits', () {
    test('posts api.wallet.list_deposit_requests and types every status',
        () async {
      final http = RecordingHttpService.install((_) => [
            {
              'id': 'WDR-3',
              'amount': 1240,
              'status': 'Pending',
              'reference': 'TM-0831-1642',
              'submitted_at': '2026-08-31 16:42:00',
            },
            {
              'id': 'WDR-2',
              'amount': 900,
              'status': 'Approved',
              'credited': 1,
            },
            {
              'id': 'WDR-1',
              'amount': 600,
              'status': 'Rejected',
              'rejection_reason': 'Bank received R 300.00.',
            },
          ]);

      final rows = _data(await DriverDepositRepository().listMyDeposits());

      expect(http.single.cmd, 'api.wallet.list_deposit_requests');
      expect(rows.map((r) => r.status), [
        DepositStatus.pending,
        DepositStatus.approved,
        DepositStatus.rejected,
      ]);
      expect(rows.first.isLive, isTrue);
      expect(rows.first.submittedAt, isNotNull);
      expect(rows[1].credited, isTrue);
      expect(rows.last.rejectionReason, 'Bank received R 300.00.');
    });
  });

  group('submitDeposit', () {
    test('uploads the slip through the gallery seam, then posts the URL',
        () async {
      final gallery = _installGallery(url: 'https://files.test/slip.jpg');
      final http = RecordingHttpService.install((_) => {
            'success': true,
            'request_id': 'WDR-9',
            'reference': 'TM-0831-1642',
            'amount': 1240.0,
            'status': 'Pending',
            'submitted_at': '2026-08-31 16:42:00',
            'balance': -1240.0,
          });

      final response = _data(await DriverDepositRepository().submitDeposit(
        amount: 1240,
        slipPath: '/tmp/slip.jpg',
        reference: 'TM-0831-1642',
      ));

      expect(gallery.uploads, [('/tmp/slip.jpg', UploadType.users)]);
      final request = http.single;
      expect(request.cmd, 'api.wallet.submit_deposit_request');
      expect(request.payload, {
        'amount': 1240.0,
        'method': DepositMethod.bankDeposit,
        'slip': 'https://files.test/slip.jpg',
        'reference': 'TM-0831-1642',
      });
      expect(response.success, isTrue);
      expect(response.requestId, 'WDR-9');
      // Nothing moved: the balance on the wire is still the debt.
      expect(response.balance, -1240.0);
      expect(response.toRecord().status, DepositStatus.pending);
    });

    test('a failed upload never reaches the gateway', () async {
      _installGallery(fail: true);
      final http = RecordingHttpService.install((_) => {'success': true});

      final result = await DriverDepositRepository().submitDeposit(
        amount: 1240,
        slipPath: '/tmp/slip.jpg',
      );

      expect(result, isA<Failure<DepositSubmitResponse>>());
      expect(http.requests, isEmpty);
    });

    test('an upload with no URL is a failure, not a slipless request',
        () async {
      _installGallery(url: null);
      final http = RecordingHttpService.install((_) => {'success': true});

      final result = await DriverDepositRepository().submitDeposit(
        amount: 1240,
        slipPath: '/tmp/slip.jpg',
      );

      expect(result, isA<Failure<DepositSubmitResponse>>());
      expect(http.requests, isEmpty);
    });
  });
}
