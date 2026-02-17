# Foodyman Driver App

This is the driver application for the Foodyman platform, built with Flutter. It follows a Clean Architecture approach and uses Riverpod for state management.

## Features

- **Order Management**: View and manage assigned delivery orders.
- **Navigation**: Integrated Google Maps for routing and location tracking.
- **Real-time Updates**: Firebase Messaging for instant order notifications.
- **Performance Tracking**: Charts to visualize earnings and delivery statistics.
- **Background Support**: Workmanager for handling background tasks.
- **Localization**: Support for multiple languages.

## Tech Stack

- **Framework**: Flutter
- **State Management**: [Riverpod](https://riverpod.dev/)
- **Navigation**: [AutoRoute](https://pub.dev/packages/auto_route)
- **Networking**: [Dio](https://pub.dev/packages/dio)
- **Maps**: [Google Maps Flutter](https://pub.dev/packages/google_maps_flutter)
- **Architecture**: Domain-Driven Design (DDD) / Clean Architecture

## Getting Started

### Prerequisites

- Flutter SDK (>=3.38.5)
- Dart SDK (>=3.10.0 <4.0.0)
- Android Studio / VS Code

### Installation

1.  **Clone the repository:**

    ```bash
    git clone <repository-url>
    cd foodyman_driver
    ```

2.  **Install dependencies:**

    ```bash
    flutter pub get
    ```

3.  **Run code generation (for Riverpod/Freezed/AutoRoute):**

    ```bash
    flutter pub run build_runner build --delete-conflicting-outputs
    ```

4.  **Run the app:**

    ```bash
    flutter run
    ```

## Project Structure

The project follows a Clean Architecture structure:

-   `lib/application`: Application logic (Providers, Notifiers)
-   `lib/domain`: Business logic, Entities, and Repository Interfaces
-   `lib/infrastructure`: Data layer, Repository Implementations, DTOs
-   `lib/presentation`: UI layer, Widgets, Pages

## Assets

-   Images and Icons: `assets/image/`, `assets/svg/`
-   Animations: `assets/lottie/`
