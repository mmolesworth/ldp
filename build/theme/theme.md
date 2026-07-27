# App Theme — LDP Application Phase I

**Source:** [`docs/design/color-palette.html`](../../docs/design/color-palette.html) (NCUA brand palette)
**Derived:** 2026-07-25 | **For:** `001-ldp-phase-i`

This is the **build-facing** theme the maker applies. Screens reference these tokens; **no colour is
hardcoded per control** (Constitution VIII — reuse). Every screen's accessibility pass checks colour
pairs against the contrast table below (Constitution V — WCAG 2.1 AA).

## Approach: classic `ColorPalette` variable (App.OnStart)

The source doc offers three application paths. We use the **classic `ColorPalette` dot-notation
variable only**. The **Modern (Fluent v9) theme** and **Creator Kit / Fluent UI theme** paths are
**excluded** — they drive *modern* controls, which Constitution II forbids (**classic controls
only**). Do not enable "Modern controls and themes"; do not paste the `Set(AppTheme, …)` Creator Kit
block.

Apply this in **`App.OnStart`** (transcribed verbatim from the source's ColorPalette block):

```powerfx
Set(
    ColorPalette,
    {
        // ── Primary Navy ──
        Navy950: RGBA(22, 39, 64, 1),
        Navy900: RGBA(33, 52, 85, 1),
        Navy850: RGBA(27, 45, 82, 1),
        Navy700: RGBA(42, 68, 112, 1),
        Navy600: RGBA(58, 90, 138, 1),
        // ── Accent Blue ──
        Blue600: RGBA(36, 111, 174, 1),
        Blue700: RGBA(27, 90, 142, 1),
        Blue400: RGBA(61, 139, 203, 1),
        Blue50:  RGBA(232, 241, 250, 1),
        // ── Neutrals ──
        Gray50:  RGBA(240, 244, 248, 1),
        Gray25:  RGBA(247, 249, 251, 1),
        White:   RGBA(255, 255, 255, 1),
        Gray200: RGBA(226, 231, 237, 1),
        Gray300: RGBA(197, 205, 214, 1),
        // ── Text ──
        TextHeading:     RGBA(33, 52, 85, 1),
        TextBody:        RGBA(59, 79, 107, 1),
        TextSecondary:   RGBA(122, 139, 160, 1),
        TextHelp:        RGBA(93, 107, 125, 1),    // #5D6B7D — accessible help/disabled-label text (ADDED)
        TextMuted:       RGBA(156, 170, 185, 1),
        TextOnDark:      RGBA(255, 255, 255, 1),
        TextOnDarkMuted: RGBA(255, 255, 255, 0.65),
        // ── Status (fills / dots / badge backgrounds) ──
        Success:      RGBA(16, 185, 129, 1),
        SuccessLight: RGBA(236, 253, 245, 1),
        Warning:      RGBA(245, 158, 11, 1),
        WarningLight: RGBA(255, 251, 235, 1),
        Danger:       RGBA(220, 38, 38, 1),
        DangerLight:  RGBA(254, 242, 242, 1),
        // ── Status TEXT (accessible on white/light — see Accessibility) ── ADDED
        SuccessText:  RGBA(4, 120, 87, 1),    // #047857 — accessible success text/icon on light
        WarningText:  RGBA(180, 83, 9, 1),    // #B45309 — accessible warning text/icon on light
        DangerText:   RGBA(220, 38, 38, 1),   // #DC2626 — passes AA on white for text
        // ── Keyboard focus (WCAG 2.4.7) ── ADDED 2026-07-26
        FocusOnDark:  RGBA(232, 241, 250, 1), // == Blue50. Ring for a control on a DARK fill
        FocusOnLight: RGBA(36, 111, 174, 1)   // ring for a control on a LIGHT fill
    }
);
```

> **ADDED tokens** (`TextHelp`, `SuccessText`, `WarningText`, `DangerText`) are not in the source
> doc; they close the accessibility gaps below. `TextHelp` (`#5D6B7D`) is the accessible replacement
> for `TextMuted` wherever text must be read (help text, disabled labels). Use the base
> `Success`/`Warning`/`Danger` only as **fills, dots, and badge backgrounds**; use the `*Text` tokens
> whenever the status colour carries **text or a meaningful icon**.

## Typography (font)

DM Sans (the source doc's web font) is not in the Power Apps canvas font set, so it cannot be used.
**Family: `Lato`** — built into every canvas environment, and the closest match to the source doc's
geometric DM-Sans feel while keeping the x-height Section 508 wants. `Open Sans` (the canvas default)
is the fallback if `Lato` reads too tight at `SizeCaption`; either way it is a one-token swap. Set
alongside `ColorPalette` in **`App.OnStart`**:

```powerfx
Set(
    Typography,
    {
        Family:        "Lato",        // built-in canvas font; "Open Sans" is the fallback swap
        // Type scale — CANVAS POINT sizes (mapped down from the HTML px reference; PowerLibs
        // guidance caps body ~9-12, headings ~14). Kept ≥9 for Section 508 legibility.
        SizeHero:      20,   // ADDED 2026-07-26 — landing hero headline ONLY
        SizeTitle:     14,   // screen / hero title (== SizeHeading; separated by weight + colour)
        SizeHeading:   14,   // card / section heading (canvas practical max)
        SizeSubtitle:  12,   // subtitle
        SizeBody:      11,   // body / list text (508-legible)
        SizeLabel:     11,   // field labels
        SizeCaption:   9,    // captions, badges (minimum — do not go smaller)
        WeightRegular: FontWeight.Normal,
        WeightMedium:  FontWeight.Semibold,
        WeightBold:    FontWeight.Bold
    }
);
```

Screens set control `Font`/`Size`/`FontWeight` from `Typography.*`; **no hardcoded font, size, or
weight**. Keep body ≥ `SizeBody` (11pt) and never render meaningful text below `SizeCaption` (9pt).

`SizeHero` (**20**) is the single exception to that ceiling, and it belongs to **one control**: the
landing page hero headline. The 14 cap is PowerLibs guidance for dense application UI, not a Power
Apps limit — canvas renders 20/24/32 without complaint. A full-width hero on a marketing-style
landing page is the one surface where app-UI density rules do not apply. Do not reach for it
anywhere else; if a second control seems to need it, the real problem is that the screen is
competing with itself for emphasis.

`SizeTitle` and `SizeHeading` are both **14** — the PowerLibs canvas ceiling for headings. Title and
section heading are therefore separated by **weight, colour, and placement**, not size: a screen
title is `WeightBold` + `TextOnDark` on the `Navy900` header bar; a card heading is `WeightBold` +
`TextHeading` on white. Do not reach past 14 to recover hierarchy.

## Role → token mapping (reference this on screens)

| UI role | Token | Notes |
|---|---|---|
| App header / hero background | `ColorPalette.Navy900` | White text on it. |
| Left nav / menu background | `ColorPalette.Navy850` | |
| Menu active/hover background | `ColorPalette.Navy700` | |
| Primary button / link / active indicator | `ColorPalette.Blue600` | White text on it. |
| Primary button hover/pressed | `ColorPalette.Blue700` | |
| Info badge / light accent background | `ColorPalette.Blue50` | Use `Navy900`/`Blue700` for its text. |
| Page background | `ColorPalette.Gray50` | |
| Panel background | `ColorPalette.Gray25` | |
| Card / form / content background | `ColorPalette.White` | |
| Borders / dividers | `ColorPalette.Gray200` | |
| Disabled borders | `ColorPalette.Gray300` | |
| Headings, strong labels | `ColorPalette.TextHeading` | |
| Body text, table content | `ColorPalette.TextBody` | |
| Secondary text (large only) | `ColorPalette.TextSecondary` | **≥18pt / 14pt-bold only** — see A11y. |
| Help text / disabled labels (readable) | `ColorPalette.TextHelp` | Accessible on white/Gray25/Gray50. |
| Placeholder text (decorative) | `ColorPalette.TextMuted` | **True placeholders only, never meaningful text.** |
| Text on dark surfaces | `ColorPalette.TextOnDark` / `TextOnDarkMuted` | Muted variant for inactive menu items. |
| Status text/icon on light | `SuccessText` / `WarningText` / `DangerText` | |
| Status fill / dot / badge bg | `Success`+`SuccessLight`, etc. | Background only. |
| Keyboard focus ring, dark fill | `ColorPalette.FocusOnDark` | `Blue50`. Use on Blue600/Navy buttons. |
| Keyboard focus ring, light fill | `ColorPalette.FocusOnLight` | Blue600. Use on white/grey buttons. |

## Accessibility — WCAG 2.1 AA contrast audit (Constitution V)

Ratios vs. the stated background. AA needs **4.5:1** normal text, **3:1** large text (≥18pt or
≥14pt bold) and UI/graphics.

| Foreground | Background | Ratio | Verdict |
|---|---|---|---|
| `TextOnDark` white | `Navy900` header | 12.4:1 | ✅ AAA |
| `TextOnDark` white | `Navy850` menu | 13.6:1 | ✅ AAA |
| `TextOnDarkMuted` 65% white | `Navy850` menu | ~6.7:1 | ✅ AA |
| White | `Blue600` primary button | 5.3:1 | ✅ AA |
| `TextHeading` `#213455` | White card | 12.4:1 | ✅ AAA |
| `TextHeading` `#213455` | `Gray50` page | 11.3:1 | ✅ AAA |
| `TextBody` `#3B4F6B` | White card | 8.3:1 | ✅ AAA |
| `TextBody` `#3B4F6B` | `Gray50` page | 7.5:1 | ✅ AAA |
| `DangerText` `#DC2626` | White | 4.8:1 | ✅ AA |
| `TextHelp` `#5D6B7D` | White | 5.4:1 | ✅ AA |
| `TextHelp` `#5D6B7D` | `Gray25` panel | ~5.0:1 | ✅ AA |
| `TextHelp` `#5D6B7D` | `Gray50` page | 4.9:1 | ✅ AA |
| **`TextSecondary` `#7A8BA0`** | White | **3.5:1** | ⚠ **large text only** — fails normal body |
| **`TextMuted` `#9CAAB9`** | White | **2.4:1** | ❌ **fails as text** — decorative placeholders only |
| `Success` `#10B981` **as text** | White | 2.5:1 | ❌ fill only — use `SuccessText` |
| `Warning` `#f59e0b` **as text** | White | ~1.9:1 | ❌ fill only — use `WarningText` |

### Rules that fall out of the audit ("the work it needs")

1. **`TextSecondary` (`#7A8BA0`)**: only for **large text** (subtitles/labels ≥18pt or ≥14pt bold).
   For secondary **body** text on white/light, use `TextBody` instead.
   ⚠ **Since the 18 → 14 title reconcile, no token in the scale reaches 18pt.** `TextSecondary` is
   therefore usable *only* at `SizeTitle`/`SizeHeading` (14) **with `WeightBold`** — every other
   size/weight combination fails AA. In practice: reach for `TextHelp` (`#5D6B7D`, 5.4:1 on white)
   for de-emphasised text, and treat any `TextSecondary` at `SizeBody` or `SizeCaption` as a bug.
2. **`TextMuted` (`#9CAAB9`)**: true placeholders only. For **help text and disabled labels that must
   be read**, use **`TextHelp` (`#5D6B7D`)** — it clears AA on white, `Gray25`, and `Gray50`.
3. **Status colours carrying text/icons**: use `SuccessText` / `WarningText` / `DangerText`. Reserve
   `Success` / `Warning` / `Danger` for fills, dots, and badge backgrounds (paired with their
   `*Light` background token).
4. **Keyboard focus must be visible (WCAG 2.4.7).** Every focusable control sets:

   ```
   FocusedBorderColor:     =ColorPalette.FocusOnDark    // on Blue600 / Navy fills
                           =ColorPalette.FocusOnLight   // on White / Gray fills
   FocusedBorderThickness: =3
   ```

   **A filled button also needs `BorderStyle.Solid` with `BorderThickness: =0`.** This is the part
   that is easy to get wrong: `BorderStyle: =BorderStyle.None` suppresses the border in **every**
   state, focus included, so `FocusedBorderColor` and `FocusedBorderThickness` are set but never
   render — the properties look correct in the YAML and nothing appears on screen. `Solid` with
   thickness `0` leaves the resting button borderless while giving focus a border to thicken:

   ```
   BorderColor:     =ColorPalette.Blue600     // same as Fill — invisible at rest
   BorderStyle:     =BorderStyle.Solid
   BorderThickness: =0
   ```

   Three failure modes this exists to prevent, all found in the build on 2026-07-26:

   - **`BorderStyle.None`** — focus properties are inert, as above.
   - **No `FocusedBorderColor` at all** — no focus state. Every filled button in the app started
     this way.
   - **`FocusedBorderThickness` equal to the resting `BorderThickness`** — no perceptible change.
     This comes from the PowerLibs outlined-button pattern, which sets them equal deliberately to
     avoid a hover jump. Correct for the mouse, wrong for the keyboard.

   **Pick the ring by the fill it sits on, not by brand preference.** A ring is a non-text indicator
   and needs **3:1 against the adjacent colour**. `Blue600` is dark enough that most of the palette
   fails against it:

   | Ring on a `Blue600` fill | Ratio | |
   |---|---|---|
   | `Blue700` | 1.37:1 | ✗ — sits at the same luminance as the fill |
   | `Blue400` | 1.45:1 | ✗ — same |
   | `Navy900` | 2.35:1 | ✗ |
   | `Navy950` | 2.83:1 | ✗ — close, still short |
   | `FocusOnDark` (`Blue50`) | **4.64:1** | ✅ |

   The palette's mid blues and navies all cluster near `Blue600` in luminance, so **no** brand blue
   works as a ring on a blue button. Only the extremes do. `Blue50` is the light extreme and keeps
   the ring in the brand family; plain white also passes (5.30:1) but reads harshly on a white
   surface.

   | Ring on a `White` fill | Ratio | |
   |---|---|---|
   | `FocusOnLight` (Blue600) | ~5.3:1 | ✅ |
   | `Gray300` | ~1.5:1 | ✗ — and it is usually the resting border anyway |

   A white ring on a dark button reads as the fill shrinking inward; that *change* is the cue, even
   where the ring blends into a white surface behind it.

5. Every screen's accessibility pass verifies its actual colour pairs against this table before the
   screen is *verified* (Constitution V).

## Open items for the maker

- **OI-THEME-1:** Source doc presents Modern/Creator Kit theme paths — **excluded** here
  (Constitution II, classic only). Recorded so no one re-enables modern controls to "use the theme."
- **OI-THEME-2 — RESOLVED (2026-07-25):** added `TextHelp` (`#5D6B7D`) as the accessible help-text/
  disabled-label tone (AA on white/Gray25/Gray50); `TextMuted` restricted to true placeholders.
- **OI-THEME-3 — RESOLVED (2026-07-25):** DM Sans isn't in the canvas font set; family set to
  **`Lato`** (`Open Sans` is the one-token fallback). Type scale expressed in **canvas point sizes**
  (title 14 / heading 14 / body 11 / caption 9) — mapped down from the HTML px reference to match
  Power Apps conventions while staying ≥9pt for Section 508. `SizeTitle` lowered 18 → 14 to sit at
  the PowerLibs heading ceiling; title/heading hierarchy now carried by weight + colour + placement.
  This closes the "reconcile at build" caveat in `build/CONVENTIONS.md`.
