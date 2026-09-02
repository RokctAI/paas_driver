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


import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:base_sdk/src/presentation/theme/theme.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/memory_pressure_service.dart';

final preloadedWebViewProvider = StateProvider<PreloadedWebViewState?>(
  (ref) => null,
);

class PreloadedWebViewState {
  final WebViewController controller;
  final String url;
  final bool isReady;

  PreloadedWebViewState({
    required this.controller,
    required this.url,
    this.isReady = false,
  });

  PreloadedWebViewState copyWith({
    WebViewController? controller,
    String? url,
    bool? isReady,
  }) {
    return PreloadedWebViewState(
      controller: controller ?? this.controller,
      url: url ?? this.url,
      isReady: isReady ?? this.isReady,
    );
  }
}

/// The arguments of the most recent [PreloadedWebViewService.preloadWebView]
/// call, kept so the preload can be re-warmed after it is released under
/// memory pressure.
class _PreloadRequest {
  const _PreloadRequest(this.ref, this.url, this.context);

  final WidgetRef ref;
  final String url;
  final BuildContext context;
}

class PreloadedWebViewService {
  /// Key this service registers under with [MemoryPressureService].
  static const String memoryHandlerKey = 'base_sdk.preloaded_webview';

  static _PreloadRequest? _lastRequest;
  static bool _handlerRegistered = false;

  static void preloadWebView(WidgetRef ref, String url, BuildContext context) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Theme.of(context).scaffoldBackgroundColor)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            ref.read(preloadedWebViewProvider.notifier).state =
                ref.read(preloadedWebViewProvider)?.copyWith(isReady: true);
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith(AppConstants.baseUrl)) {
              AppHelpers.goHome(context);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(url));

    ref.read(preloadedWebViewProvider.notifier).state = PreloadedWebViewState(
      controller: controller,
      url: url,
    );

    // Remember how to rebuild this preload, and make sure the memory service
    // knows to release it. The same three references were already retained
    // for the process lifetime by the navigation-delegate closure above, so
    // holding them here costs nothing new - and it is what lets the heavy
    // part, the platform WebView, be dropped while the app is backgrounded.
    _lastRequest = _PreloadRequest(ref, url, context);
    _ensureMemoryHandler();
  }

  static void _ensureMemoryHandler() {
    if (_handlerRegistered) return;
    _handlerRegistered = true;
    MemoryPressureService().registerHandler(memoryHandlerKey, (event) {
      switch (event) {
        case MemoryEvent.background:
          releasePreloaded();
        case MemoryEvent.resume:
          rewarmPreloaded();
        case MemoryEvent.pressure:
          // Deliberately NOT released on foreground memory pressure: an
          // open WebViewPage may be showing this very controller, and
          // blanking a page the user is looking at would be a worse bug
          // than the memory it saves. Backgrounding is the state whose Play
          // budget is halved anyway, and nobody is looking at it there.
          break;
      }
    });
  }

  /// Drop the preloaded controller and clear the provider.
  ///
  /// The preload feature itself is untouched: [rewarmPreloaded] rebuilds it
  /// on the next foreground, and a [WebViewPage] opened before that simply
  /// takes its existing not-preloaded branch and builds its own controller.
  ///
  /// webview_flutter 4.x exposes no `WebViewController.dispose()`, so the
  /// release is: navigate the page to about:blank, which frees the rendered
  /// document immediately, then drop every reference so the platform
  /// instance goes with the Dart object. Retaining a loaded WebView is the
  /// single largest avoidable allocation the SDK holds while backgrounded.
  static void releasePreloaded() {
    // Cleared by markAdopted(): once a WebViewPage has taken the preloaded
    // controller, that controller is on screen and must not be touched.
    final request = _lastRequest;
    if (request == null) return;
    try {
      final state = request.ref.read(preloadedWebViewProvider);
      if (state == null) return;
      unawaited(_blank(state.controller));
      request.ref.read(preloadedWebViewProvider.notifier).state = null;
    } catch (e) {
      // The owning widget is gone, so the provider is unreachable. Nothing
      // is left to release and nothing can be re-warmed either.
      debugPrint('==> preloaded webview release skipped: $e');
      _lastRequest = null;
    }
  }

  /// Record that a [WebViewPage] has taken over the preloaded controller.
  ///
  /// From here on the controller belongs to a live page rather than to the
  /// preload, so [releasePreloaded] leaves it alone. Calling
  /// [preloadWebView] again starts a fresh, releasable preload.
  static void markAdopted() {
    _lastRequest = null;
  }

  /// Rebuild the preload released by [releasePreloaded], if the originating
  /// widget is still on screen. A no-op when nothing was preloaded, when a
  /// preload is already live, or when the origin has since been disposed.
  static void rewarmPreloaded() {
    final request = _lastRequest;
    if (request == null) return;
    if (!request.context.mounted) {
      _lastRequest = null;
      return;
    }
    try {
      if (request.ref.read(preloadedWebViewProvider) != null) return;
      preloadWebView(request.ref, request.url, request.context);
    } catch (e) {
      debugPrint('==> preloaded webview re-warm skipped: $e');
      _lastRequest = null;
    }
  }

  static Future<void> _blank(WebViewController controller) async {
    try {
      await controller.loadRequest(Uri.parse('about:blank'));
    } catch (_) {
      // Already torn down by the platform; nothing to free.
    }
  }
}

class WebViewPage extends ConsumerStatefulWidget {
  final String url;

  const WebViewPage({super.key, required this.url});

  @override
  ConsumerState<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends ConsumerState<WebViewPage> {
  late WebViewController controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    final preloadedState = ref.read(preloadedWebViewProvider);

    // Check if we have a preloaded webview for this URL
    if (preloadedState != null && preloadedState.url == widget.url) {
      controller = preloadedState.controller;
      isLoading = !preloadedState.isReady;
      // This controller is now driving a visible page, so the memory
      // handler must stop treating it as a droppable preload.
      PreloadedWebViewService.markAdopted();
    } else {
      // If not preloaded or URL doesn't match, initialize a new controller
      controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Theme.of(context).scaffoldBackgroundColor)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) {
              if (mounted) {
                setState(() {
                  isLoading = false;
                });
              }
            },
            onNavigationRequest: (NavigationRequest request) {
              if (request.url.startsWith(AppConstants.baseUrl)) {
                AppHelpers.goHome(context);
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.url));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // The WebView is always present but initially invisible if still loading
          Opacity(
            opacity: isLoading ? 0.0 : 1.0,
            child: WebViewWidget(controller: controller),
          ),
          // Loading indicator shows while content is loading
          if (isLoading)
            Center(child: CircularProgressIndicator(color: AppStyle.primary)),
        ],
      ),
    );
  }
}
