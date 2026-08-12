// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [BecomeDriverRouteView]
class BecomeDriverRoute extends PageRouteInfo<void> {
  const BecomeDriverRoute({List<PageRouteInfo>? children})
      : super(BecomeDriverRoute.name, initialChildren: children);

  static const String name = 'BecomeDriverRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const BecomeDriverRouteView();
    },
  );
}

/// generated route for
/// [CalculatorPage]
class CalculatorRoute extends PageRouteInfo<void> {
  const CalculatorRoute({List<PageRouteInfo>? children})
      : super(CalculatorRoute.name, initialChildren: children);

  static const String name = 'CalculatorRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const CalculatorPage();
    },
  );
}

/// generated route for
/// [ClosedRouteView]
class ClosedRoute extends PageRouteInfo<void> {
  const ClosedRoute({List<PageRouteInfo>? children})
      : super(ClosedRoute.name, initialChildren: children);

  static const String name = 'ClosedRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ClosedRouteView();
    },
  );
}

/// generated route for
/// [DriverDeliveryZonePage]
class DriverDeliveryZoneRoute extends PageRouteInfo<void> {
  const DriverDeliveryZoneRoute({List<PageRouteInfo>? children})
      : super(DriverDeliveryZoneRoute.name, initialChildren: children);

  static const String name = 'DriverDeliveryZoneRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const DriverDeliveryZonePage();
    },
  );
}

/// generated route for
/// [HomePage]
class HomeRoute extends PageRouteInfo<void> {
  const HomeRoute({List<PageRouteInfo>? children})
      : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const HomePage();
    },
  );
}

/// generated route for
/// [IncomePage]
class DriverIncomeRoute extends PageRouteInfo<void> {
  const DriverIncomeRoute({List<PageRouteInfo>? children})
      : super(DriverIncomeRoute.name, initialChildren: children);

  static const String name = 'DriverIncomeRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const IncomePage();
    },
  );
}

/// generated route for
/// [LoginRouteView]
class LoginRoute extends PageRouteInfo<void> {
  const LoginRoute({List<PageRouteInfo>? children})
      : super(LoginRoute.name, initialChildren: children);

  static const String name = 'LoginRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const LoginRouteView();
    },
  );
}

/// generated route for
/// [NoConnectionRouteView]
class NoConnectionRoute extends PageRouteInfo<void> {
  const NoConnectionRoute({List<PageRouteInfo>? children})
      : super(NoConnectionRoute.name, initialChildren: children);

  static const String name = 'NoConnectionRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const NoConnectionRouteView();
    },
  );
}

/// generated route for
/// [NotificationListPage]
class NotificationListRoute extends PageRouteInfo<void> {
  const NotificationListRoute({List<PageRouteInfo>? children})
      : super(NotificationListRoute.name, initialChildren: children);

  static const String name = 'NotificationListRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const NotificationListPage();
    },
  );
}

/// generated route for
/// [OrderHistoryPage]
class OrderHistoryRoute extends PageRouteInfo<void> {
  const OrderHistoryRoute({List<PageRouteInfo>? children})
      : super(OrderHistoryRoute.name, initialChildren: children);

  static const String name = 'OrderHistoryRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const OrderHistoryPage();
    },
  );
}

/// generated route for
/// [OrdersPage]
class OrdersRoute extends PageRouteInfo<void> {
  const OrdersRoute({List<PageRouteInfo>? children})
      : super(OrdersRoute.name, initialChildren: children);

  static const String name = 'OrdersRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const OrdersPage();
    },
  );
}

/// generated route for
/// [ParcelHistoryPage]
class ParcelHistoryRoute extends PageRouteInfo<void> {
  const ParcelHistoryRoute({List<PageRouteInfo>? children})
      : super(ParcelHistoryRoute.name, initialChildren: children);

  static const String name = 'ParcelHistoryRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ParcelHistoryPage();
    },
  );
}

/// generated route for
/// [ParcelsPage]
class ParcelsRoute extends PageRouteInfo<void> {
  const ParcelsRoute({List<PageRouteInfo>? children})
      : super(ParcelsRoute.name, initialChildren: children);

  static const String name = 'ParcelsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ParcelsPage();
    },
  );
}

/// generated route for
/// [ProfilePage]
class ProfileRoute extends PageRouteInfo<void> {
  const ProfileRoute({List<PageRouteInfo>? children})
      : super(ProfileRoute.name, initialChildren: children);

  static const String name = 'ProfileRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ProfilePage();
    },
  );
}

/// generated route for
/// [RegisterConfirmationRouteView]
class RegisterConfirmationRoute
    extends PageRouteInfo<RegisterConfirmationRouteArgs> {
  RegisterConfirmationRoute({
    Key? key,
    required UserModel userModel,
    required String verificationId,
    bool isResetPassword = false,
    List<PageRouteInfo>? children,
  }) : super(
          RegisterConfirmationRoute.name,
          args: RegisterConfirmationRouteArgs(
            key: key,
            userModel: userModel,
            verificationId: verificationId,
            isResetPassword: isResetPassword,
          ),
          initialChildren: children,
        );

  static const String name = 'RegisterConfirmationRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<RegisterConfirmationRouteArgs>();
      return RegisterConfirmationRouteView(
        key: args.key,
        userModel: args.userModel,
        verificationId: args.verificationId,
        isResetPassword: args.isResetPassword,
      );
    },
  );
}

class RegisterConfirmationRouteArgs {
  const RegisterConfirmationRouteArgs({
    this.key,
    required this.userModel,
    required this.verificationId,
    this.isResetPassword = false,
  });

  final Key? key;

  final UserModel userModel;

  final String verificationId;

  final bool isResetPassword;

  @override
  String toString() {
    return 'RegisterConfirmationRouteArgs{key: $key, userModel: $userModel, verificationId: $verificationId, isResetPassword: $isResetPassword}';
  }
}

/// generated route for
/// [RegisterRouteView]
class RegisterRoute extends PageRouteInfo<RegisterRouteArgs> {
  RegisterRoute({
    Key? key,
    bool isOnlyEmail = false,
    List<PageRouteInfo>? children,
  }) : super(
          RegisterRoute.name,
          args: RegisterRouteArgs(key: key, isOnlyEmail: isOnlyEmail),
          initialChildren: children,
        );

  static const String name = 'RegisterRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<RegisterRouteArgs>(
        orElse: () => const RegisterRouteArgs(),
      );
      return RegisterRouteView(key: args.key, isOnlyEmail: args.isOnlyEmail);
    },
  );
}

class RegisterRouteArgs {
  const RegisterRouteArgs({this.key, this.isOnlyEmail = false});

  final Key? key;

  final bool isOnlyEmail;

  @override
  String toString() {
    return 'RegisterRouteArgs{key: $key, isOnlyEmail: $isOnlyEmail}';
  }
}

/// generated route for
/// [RegistrationStepsRouteView]
class RegistrationStepsRoute extends PageRouteInfo<void> {
  const RegistrationStepsRoute({List<PageRouteInfo>? children})
      : super(RegistrationStepsRoute.name, initialChildren: children);

  static const String name = 'RegistrationStepsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const RegistrationStepsRouteView();
    },
  );
}

/// generated route for
/// [ResetPasswordRouteView]
class ResetPasswordRoute extends PageRouteInfo<void> {
  const ResetPasswordRoute({List<PageRouteInfo>? children})
      : super(ResetPasswordRoute.name, initialChildren: children);

  static const String name = 'ResetPasswordRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ResetPasswordRouteView();
    },
  );
}

/// generated route for
/// [SplashRouteView]
class SplashRoute extends PageRouteInfo<void> {
  const SplashRoute({List<PageRouteInfo>? children})
      : super(SplashRoute.name, initialChildren: children);

  static const String name = 'SplashRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SplashRouteView();
    },
  );
}

/// generated route for
/// [StoryPage]
class StoryRoute extends PageRouteInfo<void> {
  const StoryRoute({List<PageRouteInfo>? children})
      : super(StoryRoute.name, initialChildren: children);

  static const String name = 'StoryRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const StoryPage();
    },
  );
}

/// generated route for
/// [UiTypeRouteView]
class UiTypeRoute extends PageRouteInfo<UiTypeRouteArgs> {
  UiTypeRoute({Key? key, bool isBack = false, List<PageRouteInfo>? children})
      : super(
          UiTypeRoute.name,
          args: UiTypeRouteArgs(key: key, isBack: isBack),
          initialChildren: children,
        );

  static const String name = 'UiTypeRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<UiTypeRouteArgs>(
        orElse: () => const UiTypeRouteArgs(),
      );
      return UiTypeRouteView(key: args.key, isBack: args.isBack);
    },
  );
}

class UiTypeRouteArgs {
  const UiTypeRouteArgs({this.key, this.isBack = false});

  final Key? key;

  final bool isBack;

  @override
  String toString() {
    return 'UiTypeRouteArgs{key: $key, isBack: $isBack}';
  }
}
