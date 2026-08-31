## 1.1.0

* **Design strip section 45 — the calculator surface** (frames 45a, 45e
  and the 45f inset; chips 836–841, canonical 390/347). `/calc` shipped
  in 1.0.1 as a real route that nothing navigated to, drawn on four raw
  hex constants, with two pieces of its own state invisible and no way
  to hand a number back. All four are fixed; the arithmetic engine is
  not touched.
  * **Planes.** `/calc` DECLARES TWO — the tape plane and the
    display+pad plane. The history was a `ListView` jammed into the
    top-right of the display area at 60% of screen width; at tablet
    size, a sliver of grey text over empty space. On a phone the plane
    mechanism collapses by construction and the 45e fold takes over.
  * **836 / 837 — the tape pane and its rows.** Header, the shipped
    ten-row cap stated ON the pane, hairline-separated rows oldest at
    the top, each in the shipped `firstNum op secondNum = result`
    format. Tapping a row puts its result back on the display
    (`CalculatorNotifier.recallResult`) — the one new behaviour on the
    tape, and the same assignment `MR` already makes.
  * **838 — the memory bar.** `memoryValue` has been stored since 1.0.1
    and nothing ever rendered it, so MC/MR/M−/M+ operated blind. The
    bar renders the value that was already in state, with the four keys
    repeated as mini pills. It changes no notifier behaviour.
  * **839 — the operator column.** ÷ × − + with = beneath, intact on
    both the spread and the fold. The 45f inset draws the line: the
    calc pad and base_sdk's `MoneyKeypad` (chip 390) share DRESS, never
    LAYOUT — 390 is 1-2-3-first money order, calc is 7-8-9-first
    desktop order, and neither may be reordered to match the other.
  * **840 — "use this amount", and the number finally comes back.**
    Both exits used to `maybePop()` with no result, so every gate that
    wanted a number was a gate to a dead end. `/calc?pick=true` grows a
    primary pill that pops the display STRING to the caller. Callers
    navigate by ROUTE PATH and never import calc_sdk (ADR-005); a
    caller against an older calc_sdk gets null and falls through.
  * **841 — Clear the tape.** `clearHistory()` was reachable only by
    double-tapping the C key, which nobody would ever find. The visible
    button exposes it; the gesture stays exactly as it was.
  * **Tokens.** `0xFF22252D` / `0xFF2A2D37` / `0xFFFF5A66` /
    `0xFF26F4CE` map one for one onto `AppStyle.surfaceDark` /
    `cardDarkAlt` / `primary` / `green`. The calculator was the last
    screen in the fleet on raw hex. The six rows are unchanged.
  * **Sound.** The pad now wears the fleet key tile, so every press
    plays `KeySound.tap()`. The calculator was the ONE keypad in the
    fleet still silent while `MoneyKeypad` has clicked on every press
    since base_sdk 1.44.0. The sound lives in the tile, so wearing the
    tile buys it — and `KeySound` fails open, so a host without the
    audio assets gets silence, never an exception.
  * New deps: `base_sdk`, `flutter_screenutil`, `remixicon`. Six new
    `tr_keys` (the shipped screen rendered glyphs and numbers only; the
    redrawn one has prose).
  * FOLLOW-UP, deliberately not done here: the key tile's body is now
    duplicated between this SDK and `MoneyKeypad._key`. Promoting it to
    one shared base_sdk widget changes no caller and deletes the
    duplicate — it is a base_sdk change, so it belongs to a base_sdk
    release, not to this one.

## 1.0.1

* Standalone calculator extracted from paas_manager's two parallel
  `lib/calc` implementations: keypad, chained operators, the last-ten
  history tape and the MC/MR/M−/M+ memory keys, behind an un-gated
  `/calc` route shared by the manager and driver compositions. The
  unwired `%` was fixed on the way in.
