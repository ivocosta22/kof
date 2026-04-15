# Kof App

Flutter mobile app for the Kof table ordering system. See the [root README](../README.md) for a full project overview.

## Setup

```bash
flutter pub get
flutter gen-l10n
flutter run
```

## Required config files

These are not in the repository — obtain them from the project owner or your own Firebase project:

| File | Location | Purpose |
|------|----------|---------|
| `google-services.json` | `android/app/` | Firebase (Android) |
| `GoogleService-Info.plist` | `ios/Runner/` | Firebase (iOS) |

Google Maps API keys are set directly in `android/app/src/main/AndroidManifest.xml` and `ios/Runner/AppDelegate.swift`.

## Localisations

Strings live in `lib/l10n/`. After editing any `.arb` file run:

```bash
flutter gen-l10n
```

Supported languages: English (`en`), Português (`pt`), Suomi (`fi`).
