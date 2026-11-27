<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

TODO: Put a short description of the package here that helps potential users
know whether this package might be useful for them.

## Features

TODO: List what your package can do. Maybe include images, gifs, or videos.

## Getting started

TODO: List prerequisites and provide or point to information on how to
start using the package.

## Usage

TODO: Include short and useful examples for package users. Add longer examples
to `/example` folder.

```dart
const like = 'sample';
```

## Additional information

TODO: Tell users more about the package: where to find more information, how to
contribute to the package, how to file issues, what response they can expect
from the package authors, and more.


## Declaring your app's login page (home SDKs)

The login page is shared, but its look is declared by the app's home SDK
through a manifest `integrations` entry on
`lib/presentation/routes/auth_route_pages.dart`, placeholder
`// @auth-entry-config`, normally inside the `app_type` flavor block:

```dart
AuthEntryConfig.layout = AuthEntryLayout.card; // or .photo (default)
AuthEntryConfig.heroAsset = 'assets/images/my_logo.png'; // optional
// or, from the home SDK's di_hook: AuthEntryConfig.heroBuilder = (_) => MyMark();
AuthEntryConfig.titleTrKey = 'my_login_title';   // English + Afrikaans
AuthEntryConfig.subtitleTrKey = 'my_login_subtitle';
AuthEntryConfig.socialSignIns = [AuthSocialSignIn.google]; // card buttons
AuthEntryConfig.showsRegister = false; // accounts made elsewhere
AuthEntryConfig.showsGuestSkip = false; // no guest surface
```

Declare nothing and the app keeps the splash-picture login. Sticks
(agent_sdk, `sticks` flavor) is the first app on the card layout.
