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

library base_sdk;

// Shared kernel for all RokctAI feature SDKs. This barrel carries the
// commonly-consumed surface; anything else is importable via
// package:base_sdk/src/... paths.

// Handlers (HTTP plumbing, result/failure types)
export 'src/handlers/api_result.dart';
export 'src/handlers/http_service.dart';
export 'src/handlers/network_exceptions.dart';
export 'src/handlers/network_helpers.dart';
export 'src/handlers/platform_gateway.dart';
export 'src/handlers/token_interceptor.dart';

// Constants + assets
export 'src/constants/app_constants.dart';
export 'src/constants/demo_images.dart';
export 'src/presentation/app_assets.dart';

// Per-app theme seam (default polarity for first launch — app glue sets
// AppTheme.defaultDarkMode before runApp; AppStyle itself stays a deep
// import via each app's installed theme shim).
export 'src/presentation/theme/app_theme.dart';

// Shared presentation components (generic, no feature-SDK logic — ADR-005)
export 'src/presentation/components/glance_card.dart';
export 'src/presentation/components/blur_wrap.dart';

// Adaptive primitives: Material 3 window-size classes + the two layout
// shells every composed app builds its phone/wide split from.
export 'src/presentation/adaptive/breakpoints.dart';
export 'src/presentation/adaptive/adaptive_shell.dart';
// The orientation policy plus the FreeRotation claim a page declares to be
// excused from it (base honours and restores it; pages never touch
// SystemChrome).
export 'src/presentation/adaptive/orientation.dart';
export 'src/presentation/adaptive/planes.dart';
export 'src/presentation/adaptive/split_pane.dart';

// Shared widgets promoted from paas_manager's host lib/ (manager
// lib/ regenerable migration, stage S2): composed manager templates
// consume these via package:base_sdk imports.
export 'src/presentation/components/app_bars/custom_app_bar.dart';
export 'src/presentation/components/categories_tab_bar.dart';
export 'src/presentation/components/category_tab_bar_item.dart';
export 'src/presentation/components/custom_date_picker.dart';
export 'src/presentation/components/filter_screen.dart';
export 'src/presentation/components/helper/common_image.dart';
export 'src/presentation/components/helper/modal_drag.dart';
export 'src/presentation/components/helper/modal_wrap.dart';
export 'src/presentation/components/helper/shop_bordered_avatar.dart';
export 'src/presentation/components/loading/loading_list.dart';
export 'src/presentation/components/loading/tab_bar_loading.dart';
export 'src/presentation/components/text_fields/underlined_text_field.dart';
export 'src/presentation/components/keypad/money_keypad.dart';

// THE STANDARD LIST LANGUAGE (approved design strip section 38, Ray
// 2026-08-30 12:23Z: "33 list language = STANDARD for all lists"). Its
// consumers sit in three feature SDKs across two repos, and a feature SDK
// may only import base_sdk (ADR-005) — so the language lives here.
export 'src/presentation/components/lists/list_language.dart';
export 'src/presentation/components/lists/list_plane_flow.dart';

// Floating pill navigation (nav_floating.html recovered spec) + the generic
// scroll-collapse state it reads (moved here from marketplace_sdk).
export 'src/application/floating/floating_notifier.dart';
export 'src/application/floating/floating_provider.dart';
export 'src/application/floating/floating_state.dart';
export 'src/presentation/components/floating_nav/bottom_navigator_item.dart';
export 'src/presentation/components/floating_nav/floating_navbar.dart';
export 'src/presentation/components/floating_nav/floating_nav_mode.dart';
export 'src/presentation/components/floating_nav/floating_bottom_nav.dart';

// Generic profile page host: identity header from profileProvider plus an
// open-ended list of SDK-injected sections. Feature SDKs register sections
// and host-level actions on ProfileSectionRegistry.I at bootstrap
// (typically from a manifest di_hooks entry — ADR-005).
export 'src/application/profile/profile_host_capabilities.dart';
export 'src/presentation/pages/profile/edit_profile_sheet.dart';
export 'src/presentation/pages/profile/generic_profile_page.dart';
export 'src/presentation/pages/profile/profile_action_item.dart';
export 'src/presentation/pages/profile/profile_host_scope.dart';
export 'src/presentation/pages/profile/profile_section.dart';
export 'src/presentation/pages/profile/profile_section_registry.dart';
export 'src/presentation/pages/profile/widgets/app_usage_badge.dart';
export 'src/presentation/pages/profile/widgets/base_profile_footer.dart';
export 'src/presentation/pages/profile/widgets/base_wallet_card.dart';
export 'src/presentation/pages/profile/widgets/profile_actions_section.dart';
export 'src/presentation/pages/profile/widgets/profile_nav_tile.dart';
export 'src/presentation/pages/profile/widgets/profile_section_card.dart';
export 'src/presentation/pages/profile/widgets/profile_switch_tile.dart';
export 'src/presentation/pages/profile/widgets/profile_theme_toggle.dart';

// Kernel services
export 'src/services/app_connectivity.dart';
export 'src/services/app_ui_keys.dart';
export 'src/services/customer_cart_store.dart';
export 'src/services/error_presenter.dart';
export 'src/services/telemetry.dart';
export 'src/services/timing_telemetry.dart';
export 'src/services/app_helpers.dart';
export 'src/services/key_sound.dart';
export 'src/services/local_storage.dart';
// Memory pressure + image cache sizing (Play's Feb 2027 memory thresholds)
// and the Restore Credentials transport (Play's April 2027 Zero-Tap
// Sign-In requirement).
export 'src/services/memory_pressure_service.dart';
export 'src/services/restore_credential_service.dart';
export 'src/services/storage_keys.dart';
export 'src/services/tr_keys.dart';
export 'src/services/bundled_translations.dart';
export 'src/services/bundled_af_translations.dart';
export 'src/common/translation_seeder.dart';

// Offline database (shared Drift instance + generic JSON document store)
export 'src/database/app_database.dart';
export 'src/database/kv_tables.dart';

// Offline sync engine (outbox drain + temp-id -> backend-id mapping).
// Feature SDKs implement SyncHandler and register it per op type from
// their *SdkDependencies.register.
export 'src/services/connectivity_service.dart';
export 'src/sync/id_mappings_table.dart';
export 'src/sync/outbox_table.dart';
export 'src/sync/sync_engine.dart';
export 'src/sync/sync_handler.dart';

// DI facade accessors (repository interfaces resolved via get_it)
export 'src/di/injection.dart';
export 'src/di/base_di.dart';

// Host-backed indirection for navigation and cross-SDK widget embedding
export 'src/navigation/app_routes.dart';
export 'src/navigation/embedded_widgets.dart';

// Kernel session models
export 'src/models/models.dart';

// Generalized processing/orchestration lifecycle (shared by feature SDKs
// and backends so they enforce identical state-transition rules — see
// ADR-005: this is exactly why it lives in base_sdk instead of being
// imported cross-SDK from processing_sdk).
export 'src/domain/interface/processing_contract.dart';
