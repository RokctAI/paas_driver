// Copyright (c) 2026 RokctAI
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


import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:remixicon/remixicon.dart';

import 'package:base_sdk/src/application/profile/profile_provider.dart';
import 'package:base_sdk/src/models/data/profile_data.dart';
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/components/custom_network_image.dart';
import 'package:base_sdk/src/presentation/components/loading.dart';
import 'package:base_sdk/src/presentation/pages/profile/profile_section.dart';
import 'package:base_sdk/src/presentation/pages/profile/profile_section_registry.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

/// Generic profile page host.
///
/// Identity comes from base_sdk's [profileProvider]; the body is composed
/// from whatever sections the installed SDK set registered on
/// [ProfileSectionRegistry] at bootstrap. Nothing here knows about any
/// feature SDK (ADR-005).
@RoutePage()
class GenericProfilePage extends ConsumerStatefulWidget {
  const GenericProfilePage({super.key});

  @override
  ConsumerState<GenericProfilePage> createState() =>
      _GenericProfilePageState();
}

class _GenericProfilePageState extends ConsumerState<GenericProfilePage> {
  /// Resolved async visibility gates, keyed by section id. A gated section
  /// stays hidden until its gate resolves true.
  final Map<String, bool> _gateResults = {};

  @override
  void initState() {
    super.initState();
    _resolveVisibilityGates();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileProvider.notifier).fetchUser(context);
    });
  }

  Future<void> _resolveVisibilityGates() async {
    for (final section in ProfileSectionRegistry.I.sections) {
      final gate = section.visible;
      if (gate == null) continue;
      var visible = false;
      try {
        visible = await gate();
      } catch (_) {
        visible = false;
      }
      if (!mounted) return;
      setState(() => _gateResults[section.id] = visible);
    }
  }

  bool _isVisible(ProfileSection section) =>
      section.visible == null || (_gateResults[section.id] ?? false);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);
    final registry = ProfileSectionRegistry.I;
    final user = state.userData ?? LocalStorage.getUser();
    final sections = registry.sections.where(_isVisible).toList();
    final hydrating =
        state.isLoading && user == null && LocalStorage.getToken().isNotEmpty;

    return Scaffold(
      backgroundColor: AppStyle.bgGrey,
      body: hydrating
          ? const Loading()
          : SafeArea(
              child: ListView(
                padding: EdgeInsets.all(16.r),
                children: [
                  _IdentityHeader(
                    user: user,
                    onEditProfile: registry.onEditProfile,
                    onLogout: registry.onLogout == null
                        ? null
                        : () => _confirmLogout(registry.onLogout!),
                  ),
                  16.verticalSpace,
                  if (sections.isEmpty)
                    const _EmptySections()
                  else
                    ...sections.map((section) => section.builder(context)),
                ],
              ),
            ),
    );
  }

  void _confirmLogout(void Function(BuildContext context) onLogout) {
    AppHelpers.showAlertDialog(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Remix.logout_box_r_line, size: 48.sp, color: AppStyle.textGrey),
          16.verticalSpace,
          Text(
            AppHelpers.getTranslation(TrKeys.doYouReallyWantToLogout),
            style: AppStyle.interSemi(size: 16.sp),
            textAlign: TextAlign.center,
          ),
          24.verticalSpace,
          CustomButton(
            title: AppHelpers.getTranslation(TrKeys.yes),
            background: AppStyle.primary,
            textColor: AppStyle.white,
            onPressed: () {
              Navigator.of(context).pop();
              onLogout(context);
            },
          ),
          12.verticalSpace,
          CustomButton(
            title: AppHelpers.getTranslation(TrKeys.cancel),
            background: AppStyle.transparent,
            borderColor: AppStyle.black,
            textColor: AppStyle.black,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _IdentityHeader extends StatelessWidget {
  final ProfileData? user;
  final void Function(BuildContext context)? onEditProfile;
  final VoidCallback? onLogout;

  const _IdentityHeader({
    required this.user,
    required this.onEditProfile,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final name = '${user?.firstname ?? ''} ${user?.lastname ?? ''}'.trim();
    final email = user?.email ?? '';
    final contact = email.isNotEmpty ? email : (user?.phone ?? '');
    final role = user?.role ?? '';

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppStyle.cardDark,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          _Avatar(user: user),
          12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty
                      ? AppHelpers.getTranslation(TrKeys.profile)
                      : name,
                  style: AppStyle.interSemi(
                    size: 18.sp,
                    color: AppStyle.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (contact.isNotEmpty) ...[
                  4.verticalSpace,
                  Text(
                    contact,
                    style: AppStyle.interNormal(
                      size: 13.sp,
                      color: AppStyle.textGrey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (role.isNotEmpty) ...[
                  2.verticalSpace,
                  Text(
                    role,
                    style: AppStyle.interNormal(
                      size: 12.sp,
                      color: AppStyle.textGrey,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onEditProfile != null)
            IconButton(
              onPressed: () => onEditProfile!(context),
              icon: Icon(
                Remix.pencil_line,
                size: 20.sp,
                color: AppStyle.textPrimary,
              ),
            ),
          if (onLogout != null)
            IconButton(
              onPressed: onLogout,
              icon: Icon(
                Remix.logout_box_r_line,
                size: 20.sp,
                color: AppStyle.red,
              ),
            ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final ProfileData? user;

  const _Avatar({required this.user});

  @override
  Widget build(BuildContext context) {
    final img = user?.img ?? '';
    if (img.isNotEmpty) {
      return CustomNetworkImage(
        url: img,
        width: 56.r,
        height: 56.r,
        radius: 28.r,
        profile: true,
      );
    }
    final source =
        '${user?.firstname ?? ''}${user?.lastname ?? ''}${user?.email ?? ''}';
    final initial = source.isEmpty ? '?' : source[0].toUpperCase();
    return Container(
      width: 56.r,
      height: 56.r,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppStyle.primary,
        shape: BoxShape.circle,
      ),
      child: Text(
        initial,
        style: AppStyle.interSemi(size: 22.sp, color: AppStyle.white),
      ),
    );
  }
}

class _EmptySections extends StatelessWidget {
  const _EmptySections();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 64.r),
      child: Column(
        children: [
          Icon(
            Remix.list_settings_line,
            size: 56.sp,
            color: AppStyle.textGrey,
          ),
          16.verticalSpace,
          Text(
            AppHelpers.getTranslation(TrKeys.noData),
            style: AppStyle.interNormal(size: 14.sp, color: AppStyle.textGrey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
