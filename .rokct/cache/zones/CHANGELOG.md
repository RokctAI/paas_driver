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
