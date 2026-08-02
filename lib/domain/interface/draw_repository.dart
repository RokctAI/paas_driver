import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../infrastructure/models/models.dart';
import 'package:base_sdk/src/handlers/handlers.dart';

abstract class DrawRepository {
  Future<ApiResult<DrawRouting>> getRouting({
    required LatLng start,
    required LatLng end,
  });
}
