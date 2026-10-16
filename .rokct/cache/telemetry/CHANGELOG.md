# Changelog

## 1.1.0

* feat(telemetry): offline events are no longer lost. `TelemetrySdkDependencies.register` now calls the new `TelemetryBootstrap.enableSpool`, which installs `TelemetrySpool.deliver` as `TelemetryClient`'s transport. Online, events leave through the same platform-gateway POST as before. Offline, or when the send fails at the network level (timeouts, connection errors, 502/503/504), they are queued on the device (base_sdk `LocalStorage` JSON record `telemetry_spool`, at most 500, oldest dropped first) with their original payload and timestamp. The queue is flushed in batches of 20 when connectivity returns, at boot, and after any successful live send. A flush stops on a network failure or a 401/403 and keeps the rest. A rejected tenant cmd is retried under its `control:` twin, and an event rejected under both is dropped. Live rejections are still rethrown, so `TelemetryClient`'s `control:` fallback works as before. `TelemetryBootstrap.configure` is unchanged. New dependencies `connectivity_plus` and `dio` use base_sdk's constraints.
* pubspec version now matches manifest.json (pubspec said 1.0.0).

## 1.0.0

* Bootstrap `telemetry_sdk` as a real composable package (the directory was a `.gitignore`-only placeholder). It is the delivery-policy owner for the telemetry lane: `TelemetrySdkDependencies.register` (called from the composed shell's generated sdk-di block) applies `TelemetryBootstrap.configure()`, the formal owner of base_sdk's new `TelemetryClient.configure`/`TelemetryTransport` injection seam. No client, pages, routes, or HTTP of its own — base_sdk's `TelemetryClient` remains the single client, and the default policy keeps its platform-gateway delivery unchanged.
