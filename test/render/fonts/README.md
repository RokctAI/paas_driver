# Committed Google faces

Inter, [SIL Open Font License 1.1](OFL.txt). `AppStyle`'s whole type scale is
`GoogleFonts.inter(...)`, google_fonts fetches faces at runtime, and a widget
test has no network — without a real face every glyph renders as the
FlutterTest block font and the PNG is worthless.

These are the exact files Google serves. google_fonts addresses every face as
`https://fonts.gstatic.com/s/a/<sha256>.ttf`, so **the file name is the
checksum**, and `render_screen_test.dart` serves them back through
google_fonts' own `@visibleForTesting` http seam. google_fonts then takes its
normal path and verifies each file's length *and* SHA-256 before registering
it — so the render is provably the real Inter, and no hash is hard-coded in
the harness.

| File | Weight | Used by |
|---|---|---|
| `ecdb53099b1a68cd24c6900ea5beeafec81bd3c8cb9d0f3c51b9986583ba3982.ttf` | Inter 400 | `AppStyle.interRegular` |
| `492dec3bc33255f9d81bd5fb18704ad72f96f9b9318e4171bc9f9be9dd4bf44b.ttf` | Inter 500 | `AppStyle.interNormal` |
| `d7ba633bab7f40576e539a7e934a1301d7618dceea59c743de477c2c493462fc.ttf` | Inter 600 | `AppStyle.interNoSemi` |
| `b7e339223d56e8c4210c86f1ba87b3d43d6c47e03956ea56f0a7a938ae61b2a3.ttf` | Inter 700 | `AppStyle.interSemi`, `AppStyle.interBold` |

They are **not** app assets: nothing here is declared in `pubspec.yaml`, so
none of it ships in a build. The harness reads them straight off disk.

## Adding a face

A weight or family nobody committed 404s through the offline client and fails
the run loudly, naming the URL. To add one, read the expected hash out of
google_fonts' own table for that family
(`google_fonts/lib/src/google_fonts_parts/part_<letter>.g.dart`), then:

```bash
curl -sSL -o "test/render/fonts/<hash>.ttf" "https://fonts.gstatic.com/s/a/<hash>.ttf"
```

and add a row above. The same table is what a google_fonts version bump would
change — which is why a bump surfaces as an honest 404 rather than a silently
wrong render.
