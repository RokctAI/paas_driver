// ignore_for_file: use_build_context_synchronously

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driver/presentation/routes/app_router.gr.dart';

import 'package:driver/domain/interface/interfaces.dart';
import '../../infrastructure/models/models.dart';
import '../../infrastructure/services/services.dart';
import 'splash_state.dart';

class SplashNotifier extends StateNotifier<SplashState> {
  final SettingsRepository _settingsRepository;
  final UserRepository _userRepository;

  SplashNotifier(this._settingsRepository, this._userRepository)
    : super(const SplashState());

  Future<void> fetchDriverDetails({required BuildContext context}) async {
    final response = await _userRepository.getDriverDetails();
    response.when(
      success: (data) {
        LocalStorage.setDeliveryInfo(data);
        LocalStorage.setOnline(data.data?.online ?? false);
      },
      failure: (failure, status) {
        AppHelpers.showCheckTopSnackBar(
          context,
          AppHelpers.getTranslation(failure),
        );
        debugPrint('==> error with fetching profile $failure');
      },
    );
  }

  Future<void> fetchGlobalSettings(BuildContext context) async {
    final response = await _settingsRepository.getGlobalSettings();
    response.when(
      success: (data) {
        LocalStorage.setSettingsList(data.data ?? []);
      },
      failure: (failure, status) {
        AppHelpers.showCheckTopSnackBar(
          context,
          AppHelpers.getTranslation(failure),
        );
        debugPrint('==> error with fetching settings $failure');
      },
    );
  }

  Future<void> fetchCurrencies(BuildContext context) async {
    final response = await _settingsRepository.getCurrencies();
    response.when(
      success: (data) {
        int defaultCurrencyIndex = 0;
        final List<CurrencyData> currencies = data.data ?? [];
        for (int i = 0; i < currencies.length; i++) {
          if (currencies[i].isDefault ?? false) {
            defaultCurrencyIndex = i;
            break;
          }
        }
        LocalStorage.setSelectedCurrency(currencies[defaultCurrencyIndex]);
      },
      failure: (failure, status) {
        AppHelpers.showCheckTopSnackBar(
          context,
          AppHelpers.getTranslation(failure),
        );
        debugPrint('==> error with fetching currencies $failure');
      },
    );
  }

  Future<void> fetchProfileDetails(
    BuildContext context, {
    VoidCallback? onMain,
    VoidCallback? onBecome,
    VoidCallback? onLogin,
  }) async {
    final response = await _userRepository.getProfileDetails();
    response.when(
      success: (data) {
        if (data.data?.role == "deliveryman") {
          onMain?.call();
          LocalStorage.setUser(data.data);
          if (data.data?.wallet != null) {
            LocalStorage.setWallet(data.data?.wallet);
          }
          fetchDriverDetails(context: context);
        } else {
          onBecome?.call();
        }
      },
      failure: (failure, status) {
        if (status == 401) {
          onLogin?.call();
          LocalStorage.logout();
          context.replaceRoute(const SplashRoute());
          return;
        }
        AppHelpers.showCheckTopSnackBar(
          context,
          AppHelpers.getTranslation(failure),
        );
        debugPrint('==> error fetching profile details $failure');
      },
    );
  }

  Future<void> fetchTranslations({
    required BuildContext context,
    VoidCallback? noConnection,
    VoidCallback? goMain,
    VoidCallback? goLogin,
    VoidCallback? onBecome,
    Function(DeliveryResponse?)? setDriverData,
  }) async {
    if (await AppConnectivity.connectivity()) {
      final response = await _settingsRepository.getTranslations();
      response.when(
        success: (data) {
          LocalStorage.setTranslations(data.data);
        },
        failure: (failure, status) {
          debugPrint('==> error with fetching translations $failure');
          AppHelpers.showCheckTopSnackBar(
            context,
            AppHelpers.getTranslation(failure),
          );
        },
      );
      fetchGlobalSettings(context);
      if (LocalStorage.getToken().isNotEmpty) {
        fetchProfileDetails(
          context,
          onMain: goMain,
          onBecome: onBecome,
          onLogin: goLogin,
        );
      } else {
        goLogin?.call();
      }
      if (LocalStorage.getSelectedCurrency() == null) {
        fetchCurrencies(context);
      }
    } else {
      noConnection?.call();
    }
  }
}
