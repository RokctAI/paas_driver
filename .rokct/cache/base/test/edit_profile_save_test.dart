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

// Edit profile saves what the backend reads. update_user_profile takes
// first_name / last_name / birth_date / gender / phone inside profile_data
// and answers {status, message} with no profile; the photo is attached by
// update_profile_image. Before, the keys were the Laravel-era ones (nothing
// saved), and the empty answer was stored as the signed-in user.

// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:base_sdk/src/application/edit_profile/edit_profile_notifier.dart';
import 'package:base_sdk/src/domain/interface/gallery.dart';
import 'package:base_sdk/src/domain/interface/user.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/models/models.dart';
import 'package:base_sdk/src/models/request/edit_profile.dart';
import 'package:base_sdk/src/services/enums.dart';
import 'package:base_sdk/src/services/local_storage.dart';

class _UserRepo extends Fake implements UserRepositoryFacade {
  _UserRepo({this.profile});

  /// What getProfileDetails answers; null answers a failure.
  ProfileData? profile;
  final List<Map<String, dynamic>> sent = [];
  final List<String> attached = [];
  int profileReads = 0;

  @override
  Future<ApiResult<ProfileResponse>> editProfile({
    required EditProfile? user,
  }) async {
    sent.add(user!.toJson());
    // The real endpoint's answer: no `data`.
    return ApiResult.success(data: ProfileResponse());
  }

  @override
  Future<ApiResult<ProfileResponse>> getProfileDetails() async {
    profileReads++;
    final p = profile;
    if (p == null) {
      return const ApiResult.failure(
        error: 'offline',
        statusCode: 500,
      );
    }
    return ApiResult.success(data: ProfileResponse(data: p));
  }

  @override
  Future<ApiResult<ProfileResponse>> updateProfileImage({
    required String firstName,
    required String imageUrl,
  }) async {
    attached.add(imageUrl);
    return ApiResult.success(data: ProfileResponse());
  }
}

class _Gallery extends Fake implements GalleryRepositoryFacade {
  @override
  Future<ApiResult<GalleryUploadResponse>> uploadImage(
    String file,
    UploadType uploadType,
  ) async =>
      ApiResult.success(
        data: GalleryUploadResponse(
          imageData: ImageData(title: '/files/new.png'),
        ),
      );
}

ProfileData _user() => ProfileData(
      id: 'u@example.com',
      firstname: 'Renda',
      lastname: 'Sinyage',
      email: 'u@example.com',
      birthday: '1990-04-12',
      img: '/files/old.png',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const connectivityChannel =
      MethodChannel('dev.fluttercommunity.plus/connectivity');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityChannel, (call) async {
      if (call.method == 'check') return ['wifi'];
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityChannel, null);
  });

  group('EditProfile.toJson', () {
    test('sends the keys update_user_profile reads', () {
      final json = EditProfile(
        firstname: 'A',
        lastname: 'B',
        birthday: '1990-04-12 00:00:00.000',
        gender: 'Female',
        phone: '+27810000000',
        images: '/files/x.png',
      ).toJson();
      expect(json, {
        'first_name': 'A',
        'last_name': 'B',
        'birth_date': '1990-04-12',
        'gender': 'Female',
        'phone': '+27810000000',
      });
    });

    test('leaves out a phone, birthday or gender it does not have', () {
      final json = EditProfile(firstname: 'A', birthday: '', gender: '')
          .toJson();
      expect(json, {'first_name': 'A'});
    });
  });

  /// Runs Save on a pushed route (success pops it) and returns the
  /// notifier.
  Future<EditProfileNotifier> save(
    WidgetTester tester,
    _UserRepo repo, {
    String imagePath = '',
  }) async {
    final notifier = EditProfileNotifier(repo, _Gallery());
    notifier.state = notifier.state.copyWith(
      firstName: 'Umukhulu',
      imagePath: imagePath,
    );
    late BuildContext sheetContext;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (c) {
              sheetContext = c;
              return const Scaffold(body: Text('sheet'));
            },
          )),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.runAsync(() => notifier.editProfile(sheetContext, _user()));
    await tester.pumpAndSettle();
    return notifier;
  }

  testWidgets('an answer with no profile re-reads it instead of blanking',
      (tester) async {
    final fresh = _user().copyWith(firstname: 'Umukhulu');
    final repo = _UserRepo(profile: fresh);
    final notifier = await save(tester, repo);

    expect(repo.sent.single['first_name'], 'Umukhulu');
    expect(repo.sent.single.containsKey('images'), isFalse);
    expect(repo.profileReads, 1);
    expect(LocalStorage.getUser()?.firstname, 'Umukhulu');
    expect(LocalStorage.getUser()?.email, 'u@example.com');
    expect(notifier.state.isSuccess, isTrue);
    expect(notifier.state.userData?.firstname, 'Umukhulu');
    // Saved: the sheet route closed.
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('when the re-read fails, the edits merge into the user',
      (tester) async {
    final repo = _UserRepo();
    final notifier = await save(tester, repo);

    final stored = LocalStorage.getUser();
    expect(stored, isNotNull);
    expect(stored?.firstname, 'Umukhulu');
    expect(stored?.lastname, 'Sinyage');
    expect(stored?.email, 'u@example.com');
    expect(notifier.state.userData?.id, 'u@example.com');
  });

  testWidgets('a new photo is attached with update_profile_image',
      (tester) async {
    final repo = _UserRepo();
    final notifier =
        await save(tester, repo, imagePath: '/tmp/picked.png');

    expect(repo.attached, ['/files/new.png']);
    expect(notifier.state.userData?.img, '/files/new.png');
  });
}
