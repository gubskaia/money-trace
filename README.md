# MoneyTrace

MoneyTrace is a Flutter personal finance app with local user accounts, SQLite persistence, theme presets, and multi-currency reporting.

The project is set up so teammates can clone it and start the Windows desktop app without needing a backend or any private keys.

## Recommended First Run

Windows desktop is the smoothest entry point for this repo right now.

1. Install Flutter `3.32.1` with Dart `3.8.1`.
2. Install Visual Studio 2022 with the `Desktop development with C++` workload.
3. Clone the repo.
4. Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\run_windows.ps1
```

That script will:

- enable Windows desktop support in Flutter
- run `flutter pub get`
- run `flutter analyze`
- run `flutter test`
- stop any stale `money_trace.exe` process
- launch the app on Windows

## Manual Quick Start

If you prefer the raw Flutter commands:

```powershell
flutter config --enable-windows-desktop
flutter pub get
flutter analyze
flutter test
flutter run -d windows
```

## Local Data Model

- The app uses a local SQLite database.
- No backend, API token, `.env`, or seed server is required.
- Auth is local.
- Finance data is local.
- Theme and app settings are local.
- Exchange rates are currently seeded locally for testing.

The database file name is `money_trace.db`. Use the reset script below instead of deleting files by hand.

## Helper Scripts

Bootstrap the repo without launching the app:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\bootstrap_windows.ps1
```

Launch the Windows app:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\run_windows.ps1
```

Reset local app data and start from a clean state:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\reset_local_data_windows.ps1
```

## Useful Notes For Teammates

- If Windows build fails with `LNK1168`, a stale `money_trace.exe` is still running. The run script already tries to stop it.
- The first launch after a schema change may run local database migrations automatically.
- The project includes widget and repository tests, so `flutter test` is a good first health check before opening a PR.

## VS Code

If you use VS Code, the repo includes:

- a launch profile for `MoneyTrace (Windows)`
- tasks for bootstrap, run, and resetting local data

Recommended extensions:

- Dart
- Flutter

## Project Structure

```text
lib/
  core/        app bootstrap, router, theme, shared widgets
  data/        local SQLite + demo implementations
  features/    auth, overview, transactions, accounts, templates, analytics
  ui/          app shell
  utils/       formatters and small helpers

tool/
  bootstrap_windows.ps1
  run_windows.ps1
  reset_local_data_windows.ps1
```
