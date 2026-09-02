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


library comms_sdk;

// Import concrete files via package:comms_sdk/src/common/...
export 'src/common/di/comms_di.dart';

// The standard list language on the manager notification list (approved
// design strip frame 38b, Ray 2026-08-30 12:23Z): the All/Unread
// read-state filter and the shipped row + unread dot, in the 33 dress.
export 'src/common/presentation/notifications/notification_list_language.dart';
export 'src/common/local_notifications.dart';
export 'src/common/services/desktop_notification_poller.dart';

// The single guarded entry point for the OS notification-permission
// prompt — platform allowlist + fail-open catch (comms' FCM boot-hook
// idiom) plus in-flight de-duplication so a second sign-in in one process
// cannot trip the platform channel's concurrent-request error.
export 'src/common/services/push_permission_service.dart';
