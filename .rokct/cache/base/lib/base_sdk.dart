library base_sdk;

// Shared kernel for all RokctAI feature SDKs. This barrel carries the
// commonly-consumed surface; anything else is importable via
// package:base_sdk/src/... paths.

// Handlers (HTTP plumbing, result/failure types)
export 'src/handlers/api_result.dart';
export 'src/handlers/http_service.dart';
export 'src/handlers/network_exceptions.dart';
export 'src/handlers/network_helpers.dart';
export 'src/handlers/token_interceptor.dart';

// Constants + assets
export 'src/constants/app_constants.dart';
export 'src/presentation/app_assets.dart';

// Shared presentation components (generic, no feature-SDK logic — ADR-005)
export 'src/presentation/components/glance_card.dart';
export 'src/presentation/components/blur_wrap.dart';

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

// Floating pill navigation (nav_floating.html recovered spec) + the generic
// scroll-collapse state it reads (moved here from marketplace_sdk).
export 'src/application/floating/floating_notifier.dart';
export 'src/application/floating/floating_provider.dart';
export 'src/application/floating/floating_state.dart';
export 'src/presentation/components/floating_nav/bottom_navigator_item.dart';
export 'src/presentation/components/floating_nav/floating_navbar.dart';
export 'src/presentation/components/floating_nav/floating_nav_mode.dart';
export 'src/presentation/components/floating_nav/floating_bottom_nav.dart';

// Kernel services
export 'src/services/app_connectivity.dart';
export 'src/services/customer_cart_store.dart';
export 'src/services/telemetry.dart';
export 'src/services/app_helpers.dart';
export 'src/services/local_storage.dart';
export 'src/services/storage_keys.dart';
export 'src/services/tr_keys.dart';

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
