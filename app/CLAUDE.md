# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Flutter app "Minha Watchlist" — single-user, no login, tracks movies/series/anime/cartoons the
user wants to watch, is watching, or has watched. 100% offline (SQLite via `sqflite`); TMDB
integration is optional and only used for search/poster/metadata enrichment.

## Commands

Run from `app/` (the Flutter project root, not the repo root):

```bash
flutter pub get              # install dependencies
flutter run                  # run on connected device/emulator
flutter analyze              # static analysis (flutter_lints)
flutter test                 # run all tests
flutter test test/widget_test.dart   # run a single test file
```

TMDB search requires a free API key set via `app/.env` (`TMDB_API_KEY=...`, copy from
`.env.example`, gitignored) or pasted into the in-app Settings screen (takes priority over
`.env`). Without a key, manual title entry with a gallery-picked poster still works.

## Architecture

Layers, each with one direction of dependency (screens → provider → data/services → models):

- `lib/models/title_item.dart` — `TitleItem` plus `TitleType` (filme/serie/anime/desenho) and
  `WatchStatus` (queroVer/assistindo/visto) enums. `toMap`/`fromMap` are the only serialization
  boundary to SQLite.
- `lib/data/database_helper.dart` — `DatabaseHelper` singleton wrapping the single `titles`
  SQLite table. Schema changes go through `onUpgrade` version bumps (currently version 4) with
  additive `ALTER TABLE` migrations — never edit `onCreate` for an existing shipped version.
- `lib/providers/titles_provider.dart` — `TitlesProvider` (ChangeNotifier via `provider` package)
  is the single state owner the UI talks to. All mutations (`addItem`/`updateItem`/`deleteItem`/
  `advanceEpisode`/`markWatched`/`moveBackToWatchlist`) go through it and end with a `load()` that
  re-reads from `DatabaseHelper` and calls `notifyListeners()` — there is no optimistic local
  mutation of `_items`. Also tracks `lastError` so screens can surface DB failures instead of
  failing silently, and `totalCount` (unfiltered row count) to distinguish "save failed" from
  "filter is hiding it" when a newly added item doesn't appear.
- `lib/services/tmdb_service.dart` — all TMDB API calls (search, season/episode listings,
  episode-name lookup with an in-memory cache, poster download to app documents dir). Throws
  `TmdbException` with user-facing Portuguese messages; callers show these in the UI. Episode
  metadata calls fail soft (return null/empty list) rather than throwing.
- `lib/services/settings_service.dart` — resolves the TMDB API key: user-entered value in
  `shared_preferences` takes priority, falls back to `.env`'s `TMDB_API_KEY`.
- `lib/screens/` and `lib/widgets/` — UI. `home_screen.dart` is the main list (search + status/type
  filters); `add_title_screen.dart`/`edit_title_screen.dart` handle TMDB search-and-fill or manual
  entry; `select_season_screen.dart` + `widgets/season_episode_picker.dart` handle rewinding/jumping
  the current watch position.

### Episode-advance logic

`TitlesProvider.advanceEpisode` (providers/titles_provider.dart) is the trickiest piece of domain
logic: it increments `episode`/`episodesWatched`, rolls over to the next `season` when the current
season's `totalEpisodes` is exceeded, and flips status to `visto` either when
`episodesWatched >= totalSeriesEpisodes` (series-wide count known) or, if that total is unknown,
when a season rolls over past the last known season. Read it fully before changing rollover/status
behavior — the three branches (series done / season done / first watch) are order-dependent.

### Error visibility

`main.dart` installs global handlers (`ErrorWidget.builder`, `FlutterError.onError`,
`PlatformDispatcher.instance.onError`) that route uncaught build/async errors into an on-screen
banner (`widgets/error_banner.dart`'s `GlobalErrorNotifier`), because release builds otherwise show
a blank screen with no visible error. Keep this in mind when debugging "silent" failures on a real
device build — check for the red banner before assuming nothing happened.
