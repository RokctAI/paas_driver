## 1.5.1

* Driver delivery-zone editor (tablet audit 2026-09-07,
  13-driver_delivery_zone rendered an all-black frame; and dark mode): the
  installed page painted a polarity-PINNED grey scaffold (`AppStyle.
  textGrey`), a pinned WHITE loading box and a bare `GoogleMap` whose
  platform view had painted nothing by the time the tour took its still.
  `templates/pages/driver/profile/delivery_zone/delivery_zone_page.dart`
  now carries the three fixes the courier home map already has:
  * the map is MOUNTED only once the page has settled, through
    delivery_sdk's `DeferredMapSurface` (one frame painted, 800 ms of
    being the current route, still mounted), so the plugin's own un-awaited
    channel calls never land on a page that is already leaving;
  * the ground and the loading / pre-mount box resolve with the mode
    (`AppStyle.surfaceDark`, a `cardDark` box with a quiet
    `textDarkSecondary` spinner) instead of the pinned grey and white;
  * the map resolves with the mode too, through delivery_sdk's
    `DriverMapStyle.forMode()` (base_sdk's night JSON when dark, the
    plugin's daylight default when light).
  Camera, polygon, tap-to-add-point and save are untouched. The page is
  host-side template code and imports delivery_sdk the way the courier
  home imports comms_sdk; this SDK's lib/ still imports no delivery_sdk
  (ADR-005). Declared in the manifest's `_comment_requires`: a driver
  compose needs delivery_sdk >= 1.21.2.
* `templates/tour/zones.tour.yaml` is unchanged and needs no change: the
  one step's route, caption and settle stay, and no finder names the
  loading box. Demo zone seed untouched.
* Version 1.5.0 -> 1.5.1 (pubspec 1.1.0 -> 1.1.1) so version-aware cache
  reconciliation re-extracts the SDK.

## 1.5.0

* Manager delivery-zone editor rebuilt to the approved design strip
  section 39 (frames 39a tablet saved-zone editor, 39b tablet drawing
  state, 39c phone fold; chips 735-742), Ray-approved 2026-08-30
  including both flagged proposals as build requirements:
  * Vertex drag-handles (737) + Undo last point (742): the manager
    notifier gains a `pointsHistory` undo stack — every tap-add and
    handle-drag snapshots the previous ring, `undoLastPoint` pops it,
    a successful save clears it (Saved state). New `moveTappedPoint`
    backs the draggable white-dot-in-primary-ring handles the page now
    renders on every vertex. Fetch seeds the saved ring as the editable
    ring, so taps EXTEND the saved shape (39a's approved reading)
    instead of starting over, and saved vertices are draggable.
  * Zone details overlay panel (739): floats top-START at plane widths —
    name, Saved/Drawing state pill, point count, the tap-to-add line
    (738) and a derived coverage figure ("≈ N km² covered") computed
    client-side by the new `zone_geometry` common service (spherical
    polar-triangle area, the SphericalUtil algorithm — no backend
    call). Collapses to the slim status pill on phone windows.
  * The full-bleed map keeps its ALL claim (735, the 19b/20b/37c map
    ruling); the closed polygon keeps the shipped notifier styling
    verbatim (736), while an open shape draws solid tapped edges over a
    faint fill with a DASHED closing-edge preview (741) and the
    N-more-points hint. Save delivery zone (740) stays behind the
    shipped `length > 3` gate — bottom-centre at plane widths,
    START-anchored on the phone — and Back is the corner
    `FloatingBackPill` (canonical 347) at the bottom-END, replacing the
    standalone `PopButton`.
  * New manifest `tr_keys` for the section's copy plus a bundled
    English map (`zones_en_translations.dart`, weather_sdk's af pattern
    applied to en) registered via a top-level boot hook, because the
    approved copy carries punctuation the humanized-key fallback cannot
    reproduce. Afrikaans values are a recorded follow-up.
  * Tests: spherical-area fixtures and notifier undo/drag/extend
    coverage under `test/`.

## 1.4.0

* Pre-changelog history: driver + manager delivery-zone editors ported
  onto the `DeliveryZonesFacade` seam (2026-07/2026-08 reforks), di_hooks
  wiring, and the #160 route declarations. See git history.
