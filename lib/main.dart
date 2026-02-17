import 'package:driver/infrastructure/models/data/local_location_data.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:driver/infrastructure/services/local_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:workmanager/workmanager.dart';
import 'package:geolocator/geolocator.dart';
import 'package:driver/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'presentation/app_widget.dart';
import 'presentation/styles/style.dart';
import 'package:dio/dio.dart';
import 'dart:async';

const fetchBackground = "fetchBackground";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case fetchBackground:
        await LocalStorage.init();
        Position userLocation = await Geolocator.getCurrentPosition(
          // ignore: deprecated_member_use
          desiredAccuracy: LocationAccuracy.high,
        );
        final Dio client =
            Dio(
                BaseOptions(
                  headers: {
                    'Accept':
                        'application/json, application/geo+json, application/gpx+xml, img/png; charset=utf-8',
                    'Content-type': 'application/json',
                    "Authorization": "Bearer ${LocalStorage.getToken()}",
                  },
                ),
              )
              ..interceptors.add(
                LogInterceptor(
                  responseHeader: false,
                  requestHeader: true,
                  responseBody: true,
                  requestBody: true,
                ),
              );
        await client.post(
          '${AppConstants.baseUrl}/api/v1/dashboard/deliveryman/settings/location',
          data: {
            "location": LocalLocationData(
              latitude: userLocation.latitude,
              longitude: userLocation.longitude,
            ).toJson(),
          },
        );
        break;
    }
    return Future.value(true);
  });
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Firebase.initializeApp();
  await LocalStorage.init();
  await Workmanager().initialize(callbackDispatcher);
  Workmanager().registerPeriodicTask(
    'a',
    fetchBackground,
    frequency: Duration(seconds: 10),
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Style.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.dark,
    ),
  );
  runApp(const ProviderScope(child: AppWidget()));
}
