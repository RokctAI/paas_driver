# Render strip — courier profile

The two halves the [render kit][kit] expects a shell to commit:

| File | What it is |
|---|---|
| `render_screen_test.dart` | The widget test. Pumps delivery_sdk's real `ProfilePage` as this shell composes it, at 390 logical px / dpr 3, light and dark, and writes `out/driver_profile_{light,dark}.png` plus a measured element-rect JSON per variant. |
| `strip.json` | The strip config the composer turns those into: captions, statuses, legend aliases, the committed numbering map and the notes that declare what was seeded. |
| `fonts/` | The four Inter weights `AppStyle` uses, exactly as Google serves them, named by the SHA-256 google_fonts checks them against. [SIL OFL 1.1](fonts/OFL.txt); see [`fonts/README.md`](fonts/README.md). Not app assets — nothing here is declared in `pubspec.yaml`, so none of it ships in a build. |

Run it from CI with the **Render Strip** workflow
(`.github/workflows/render-strip.yml`, `workflow_dispatch` only) and download
the `render-strip` artifact: the page is self-contained, so it opens from disk
with no network.

Locally, after a compose (the shell has no tracked `lib/`):

```bash
flutter test --dart-define=IS_DEMO=true test/render/render_screen_test.dart
python <shared-workflows>/scripts/render/compose_strip.py \
    --config test/render/strip.json --base-dir out \
    --out render-strip.html --emit-numbering test/render/numbering.json
```

Without `--dart-define=IS_DEMO=true` the SDKs register their real HTTP
repositories and you render a broken, empty screen.

**Keep it in sync.** A PR that changes this screen updates this config in the
same PR, exactly as it updates the owning SDK's tour fragment and demo seeds.
A render that lags the code stops being evidence.

Numbers are identities: they are bound to element `key`s in
`strip.json`'s `numbering.map` and stay bound. A removed element's number
moves to `numbering.retired` with a line saying what it was; it is never
re-issued.

[kit]: https://github.com/RokctAI/shared-workflows/blob/main/scripts/render/README.md
