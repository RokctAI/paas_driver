// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

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
