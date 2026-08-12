// Shrunk in migration stage M2: draw_repository moved to map_sdk with the
// courier home vertical (delivery_sdk). The three remaining interfaces back
// the host auth vertical and the zones_sdk adapter seam; auth/settings die
// with the auth flip (M3), user_repository shrinks away when zones_sdk's
// adapter is rewritten against a users_sdk repository (M4 exit plan in
// domain/di/dependency_manager.dart).
export 'auth_repository.dart';
export 'user_repository.dart';
export 'settings_repository.dart';
