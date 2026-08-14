# UI SPEC

Design reference for the MY Algeria BAC app (from the product owner's Flutter
shell + Rules.md §40 design language).

## Design language

> "Modern Algerian education + game progression"

- Clean, youthful, premium, energetic, highly readable
- Strong hierarchy, rounded cards, meaningful progress indicators
- Polished empty states; excellent Arabic RTL support
- Take inspiration from the *psychology of progression*, not from Duolingo's
  proprietary branding/assets

## Theme

| Token | Value |
|---|---|
| Primary | `#2563EB` |
| Secondary | `#10B981` |
| Background | `#F7F9FC` |
| Surface (cards, inputs, nav bar) | `#FFFFFF` |
| Text (dark on light) | `#111827` |
| Streak accent | `#F97316` (chip bg `#FFF7ED`) |
| Warning/energy accent | `#F59E0B` |
| Mission gradient | `#2563EB → #4F46E5` (top-left → bottom-right) |
| Icon tile (continue learning) | `#DBEAFE` bg, `#2563EB` icon |

Material 3 (`useMaterial3: true`), `ColorScheme.fromSeed(seedColor: primary)`
overridden with the tokens above.

### Component styling
- AppBar: background = page background, no elevation, no center title
- NavigationBar: white, no elevation, indicator = primary at 12% alpha
- Card: white, elevation 0, no margin, radius 20
- InputDecoration: filled white, radius 16, no border
- Primary cards (mission): gradient container, radius 24

## Screens

### Home (`HomePage`)
Scrollable dashboard. Sections in order:
1. Header: greeting (`سلام 👋`) + "Ready for BAC?" + streak chip (fire icon + count)
2. Today's Mission — gradient card: label, title, subtitle, progress bar, "x/y completed", "+XP"
3. Continue Learning — card: subject icon tile, title, "Subject • Unit", "Lesson n of m", chevron
4. "Your progress" — progress card: overall mastery %, bar, stat row (Lessons / Questions / Accuracy)
5. "Quick practice" — card: bolt icon, "5-minute practice", description, "+20 XP", "Start practice" filled button

### Learn / Practice / Progress / Profile
Placeholder pages: centered icon (64), title, subtitle. (To be replaced by
their real features.)

## Navigation
Bottom `NavigationBar` with 5 destinations:

| Tab | Icon (outlined / filled) |
|---|---|
| Home | `home_outlined` / `home` |
| Learn | `menu_book_outlined` / `menu_book` |
| Practice | `bolt_outlined` / `bolt` |
| Progress | `insights_outlined` / `insights` |
| Profile | `person_outline` / `person` |

Tabs render via `IndexedStack` (state preserved).

## Data shown on Home (current milestone)
All values are **static UI placeholders** (streak `3`, mission `4/10` &
`+50 XP`, mastery `42%`, lessons `12`, questions `186`, accuracy `74%`,
quick practice `+20 XP`). They must be wired to real data when the data layer
lands (Rules.md §19: "What should I do now?").
