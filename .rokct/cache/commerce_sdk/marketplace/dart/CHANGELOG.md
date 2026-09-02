## 1.12.0

* `WalletTopUpScreen` tops up by naming the saved CARD, not by handing
  back a credential. `Saved Card.token` is the gateway reuse credential —
  presenting it to the gateway charges that card again — and pay confined
  it to a Frappe `Password` field (pay#46), so it stopped travelling to
  clients. The screen passes `_selectedCard!.id`, the Saved Card docname,
  where it passed `_selectedCard!.token`; that field is gone from
  base_sdk 1.50.0, so this is a build break rather than a silent one.
  `walletTopUp`'s parameter keeps the name `token` because it overrides a
  base_sdk interface — what travels on it is the docname.
* REQUIRES base_sdk >= 1.50.0 and a backend carrying pay#46. Against an
  older backend the top-up is REFUSED without being charged.
* VERSIONING NOTE: the `wallet_topup_screen.dart` change described above
  actually SHIPPED in commerce#92, which carried no marketplace_sdk
  version bump — that PR was deliberately held to two files, so the
  behaviour change went out under 1.11.0. This entry is that bump,
  landed after the fact: a compose resolving marketplace_sdk >= 1.12.0
  is the first one guaranteed to carry it.

## 1.11.0

* The customer edit-own-details sheet (`EditProfileScreen`,
  edit_profile_page.dart) is PROMOTED verbatim to base_sdk 1.45.0
  (approved frame 4d 2026-08-30) as the fleet's shared
  `edit_profile_sheet.dart`, so every GenericProfilePage host — the
  manager hub first — can wire the user-card pencil (chip 109) to the
  one shipped flow. This package's copy becomes a thin re-export at the
  same path, so the "Edit account" row (my_account.dart) and every other
  import keep working; customer behavior is unchanged (same class name,
  same drag-sheet contract, same base_sdk `editProfileProvider` save
  path). Only shipped visual delta: the sheet chrome, previously
  light-only bgGrey@96%, now resolves the dark surface in dark mode
  (the promoted sheet's mode-resolving chrome).

## 1.10.0

* Dark mode for the customer profile hub ("all sdks should have darkmode",
  render-verified 2026-08-28). The hub's sections
  (`marketplace_profile_sections.dart`) drop their last fixed light-theme
  colors for base_sdk's mode-resolving `AppStyle` getters: the square tiles
  fall back to `AppStyle.cardDark` / `AppStyle.textPrimary` instead of
  fixed `AppStyle.white` / `AppStyle.black`; the ghost spacer tiles use a
  transparent border instead of a fixed white one (which glared on dark);
  the delete-account tile swaps `Colors.pink[50]` / `Colors.red` /
  `Colors.pink[700]` for a translucent `AppStyle.red` tint with
  `AppStyle.red` icon/label, legible in both modes; and the member footer
  links + separator dots render `AppStyle.textPrimary` /
  `AppStyle.textDarkSecondary` instead of fixed `AppStyle.black`.
  Adjacent: the wallet history page's Topup / Send / Loan bottom sheets
  (`wallet_history.dart`) open with the real current theme mode
  (`LocalStorage.getAppThemeMode()`) instead of hardcoded
  `isDarkMode: false`.
