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

library weather_sdk;

// Everything in weather_sdk lives under src/common/ - weather is
// role-agnostic (POS header today; any flavour may embed it), so there are
// no lib/src/<role>/ folders for the composer's role-stripping to remove and
// the barrel can safely export the whole surface.
//
// Suite provenance: paas_pos main @ 78ccee4,
// lib/src/presentation/pages/main/widgets/JuvoONE/widgets/weather/**
// (17 files; the dead-twin rain_feedback_system.dart was absorbed into
// infrastructure/services/rain_feedback_system.dart rather than ported).

// Configuration + DI
export 'src/common/config/weather_sdk_config.dart';
export 'src/common/di/weather_sdk_di.dart';

// Application state
export 'src/common/application/warnings/weather_warnings_notifier.dart';
export 'src/common/application/warnings/weather_warnings_state.dart';
export 'src/common/application/weather/open_weather_state.dart';
export 'src/common/application/weather/weather_notifier.dart';
export 'src/common/application/weather/weather_state.dart';

// Services (providers live in the service files, as they did on pos main)
export 'src/common/infrastructure/services/open_weather_icon_mapper.dart';
export 'src/common/infrastructure/services/open_weather_service.dart';
export 'src/common/infrastructure/services/rain_feedback_system.dart';
export 'src/common/infrastructure/services/weather_icon_mapper.dart';
export 'src/common/infrastructure/services/weather_notice_ack_service.dart';
export 'src/common/infrastructure/services/weather_service.dart';
export 'src/common/infrastructure/services/weather_warnings_cache.dart';
export 'src/common/infrastructure/services/weather_warnings_service.dart';

// Presentation
export 'src/common/presentation/theme/weather_colors.dart';
export 'src/common/presentation/widgets/extended_forecast_loader.dart';
export 'src/common/presentation/widgets/extended_forecast_view.dart';
export 'src/common/presentation/widgets/rain_feedback_widget.dart';
export 'src/common/presentation/widgets/severe_weather_banner.dart';
export 'src/common/presentation/widgets/temperature_badge.dart';
export 'src/common/presentation/widgets/weather_forecast_dialog.dart';
export 'src/common/presentation/widgets/weather_icon.dart';
export 'src/common/presentation/widgets/weather_inline_forecast.dart';
export 'src/common/presentation/widgets/weather_status_text.dart';
export 'src/common/presentation/widgets/weather_summary.dart';
export 'src/common/presentation/widgets/weather_widget.dart';
