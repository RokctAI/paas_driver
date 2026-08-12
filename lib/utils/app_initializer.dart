// import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../app_constants.dart';
// Migration stage M3: the host POI pair (infrastructure/models/data/
// poi_data.dart + application/poidata/poi_data_provider.dart) died with the
// auth-pinned support layer. The remote-config POI feed now writes straight
// into map_sdk's provider - the one map_sdk's view_map_page actually reads -
// where the old host provider was a disconnected twin nothing rendered.
import 'package:base_sdk/src/models/data/poi_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_sdk/src/common/application/poidata/poi_data_provider.dart';
//import 'package:riverpodtemp/utils/excluded_product_ids.dart';

class AppInitializer extends StatefulWidget {
  final ProviderContainer providerContainer;
  // final List<int> excludedProductIds = [];
  //final List<int> excludedCategoryIds = [];

  const AppInitializer({super.key, required this.providerContainer});

  Future<void> initializeApp() async {
    await initializeRemoteConfigWithoutAPICall();
    await checkAppStatusFromAPI();
    // Add other app initialization tasks here
  }

  Future<void> initializeRemoteConfigWithoutAPICall() async {
    final initializer = _AppInitializerState(providerContainer);
    await initializer._initializeRemoteConfigWithoutAPICall();
  }

  Future<void> checkAppStatusFromAPI() async {
    final initializer = _AppInitializerState(providerContainer);
    // await initializer._checkAppStatusFromAPI();
  }

  @override
  _AppInitializerState createState() => _AppInitializerState(providerContainer);
}

class _AppInitializerState extends State<AppInitializer> {
  final ProviderContainer providerContainer;

  _AppInitializerState(this.providerContainer);

  @override
  void initState() {
    super.initState();
    // You can perform additional setup here if needed
  }

  Future<void> _initializeRemoteConfigWithoutAPICall() async {
    final String tenantSite = AppConstants.baseUrl;
    const String controlPanelUrl = "https://platform.rokct.ai";

    try {
      final response = await http.get(Uri.parse(
          '$tenantSite/api/method/paas.api.get_remote_config?app_type=Driver'));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final config = responseData['message'];

        if (config != null) {
          String? getString(String key) => config[key]?.toString();
          bool? getBool(String key) =>
              config[key] == 1 || config[key] == true || config[key] == "true";
          double? getDouble(String key) =>
              double.tryParse(config[key]?.toString() ?? "");

          /// api urls
          if (getString('drawingBaseUrl') != null)
            AppConstants.drawingBaseUrl = getString('drawingBaseUrl')!;
          // AppConstants.baseUrl is not overwritten
          if (getString('webUrl') != null)
            AppConstants.webUrl = getString('webUrl')!;
          if (getString('googleApiKey') != null)
            AppConstants.googleApiKey = getString('googleApiKey')!;
          if (getString('routingKey') != null)
            AppConstants.routingKey = getString('routingKey')!;
          //AppConstants.privacyPolicyUrl = remoteConfig.getString('privacyPolicyUrl');

          /// auth phone fields
          if (getBool('isSpecificNumberEnabled') != null)
            AppConstants.isSpecificNumberEnabled =
                getBool('isSpecificNumberEnabled')!;
          if (getBool('isNumberLengthAlwaysSame') != null)
            AppConstants.isNumberLengthAlwaysSame =
                getBool('isNumberLengthAlwaysSame')!;
          if (getString('countryCodeISO') != null)
            AppConstants.countryCodeISO = getString('countryCodeISO')!;
          if (getBool('showFlag') != null)
            AppConstants.showFlag = getBool('showFlag')!;
          if (getBool('showArrowIcon') != null)
            AppConstants.showArrowIcon = getBool('showArrowIcon')!;

          /// location
          if (getDouble('demoLatitude') != null)
            AppConstants.demoLatitude = getDouble('demoLatitude')!;
          if (getDouble('demoLongitude') != null)
            AppConstants.demoLongitude = getDouble('demoLongitude')!;
          if (getDouble('pinLoadingMin') != null)
            AppConstants.pinLoadingMin = getDouble('pinLoadingMin')!;
          if (getDouble('pinLoadingMax') != null)
            AppConstants.pinLoadingMax = getDouble('pinLoadingMax')!;

          ///Google Maps POI
          if (getBool('showGooglePOILayer') != null)
            AppConstants.showGooglePOILayer = getBool('showGooglePOILayer')!;

          // Handle POI Data
          if (config['poiData'] != null) {
            try {
              String poiDataString = config['poiData'];
              List<dynamic> poiDataJson = jsonDecode(poiDataString);

              print(
                  "poiDataJson: $poiDataJson"); // Debug print to check poiDataJson

              List<POIData> poiDataList = [];
              for (var poiDataMap in poiDataJson) {
                poiDataList.add(
                  POIData(
                    name: poiDataMap['name'],
                    latitude: poiDataMap['latitude'].toDouble(),
                    longitude: poiDataMap['longitude'].toDouble(),
                    titleColor: Color(int.parse(
                            poiDataMap['titleColor'].substring(2),
                            radix: 16) +
                        0xFF000000),
                    // base_sdk's POIData carries a pin asset key the old host
                    // model lacked; empty string = default marker.
                    pin: poiDataMap['pin']?.toString() ?? '',
                  ),
                );
              }
              print(
                  "poiDataList: $poiDataList"); // Debug print to check poiDataList

              // Update the poiDataProvider with the new data
              providerContainer
                  .read(poiDataProvider.notifier)
                  .updatePOIData(poiDataList);
            } catch (e) {
              print("Error processing poiData: $e");
            }
          }
        }
      } else {
        print("Failed to fetch remote config. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching remote config: $e");
    }
  }
  /* Future<void> _checkAppStatusFromAPI() async {
    // Check the app status from the API with a 5-second timeout
    try {
      final response = await http
          .get(Uri.parse('${AppConstants.baseUrl}/public/api/v1/rest/status'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppConstants.isMaintain = data['status'] != 'OK';
      } else {
        AppConstants.isMaintain = true; // Set isMaintain to true if API response is not successful
      }
    } on TimeoutException {
      AppConstants.isMaintain = true; // Set isMaintain to true if the API call times out
    } catch (e) {
      AppConstants.isMaintain = true; // Set isMaintain to true if an exception occurs
    }
  }*/

  @override
  Widget build(BuildContext context) {
    return Container(); // No UI needed here
  }
}
