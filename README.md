# Moore Momentum — Flutter App

A plain‑Flutter rebuild of the Moore Momentum habit‑building app (rocket cockpit,
AI‑guided onboarding, daily scoring ritual, Momentum Points, Core Balance).

## Getting started

```bash
flutter pub get
```

### 1. Backend secret (required)

The app talks to Firebase Cloud Functions using a shared secret that is **not**
committed to the repo. Create it from the template:

```bash
cp lib/config/api_config.example.dart lib/config/api_config.dart
```

Then open `lib/config/api_config.dart` and set the real value:

```dart
class ApiConfig {
  static const String secret = 'YOUR_BACKEND_SECRET_HERE';
}
```

`lib/config/api_config.dart` is git‑ignored, so the secret never lands in source
control.

### 2. Firebase config (required to build)

Firebase project config is git‑ignored too (it contains project keys). Drop your
own copies in from the Firebase console:

- `android/app/google-services.json` (Android)
- `ios/Runner/GoogleService-Info.plist` (iOS)

### 3. Run

```bash
# Emulator (x86_64):
flutter run -d emulator-5554

# Build a debug APK:
#   emulator:        flutter build apk --debug --target-platform android-x64
#   physical device: flutter build apk --debug --target-platform android-arm64
```

> Note: a plain `flutter build apk` currently fails with *"Invalid platform:
> android-x86"* on this toolchain — pass `--target-platform` as shown above.

## Project layout

- `lib/screens/momentum/` — the app screens (dashboard, check‑in, summary, Phase 1
  flow, daily ritual, sub‑screens).
- `lib/widgets/momentum/` — shared UI (rocket, glass panels, buttons, core alert).
- `lib/services/` — backend clients (profile, check‑in, points, onboarding, lists,
  chat, cantina, notifications) + offline cache.
- `lib/config/` — `api_config.dart` (secret, git‑ignored) + its example template.
- `design/ref/documentation/` — build progress & traceability doc mapping each
  feature to the original spec, with screenshots.

## Backend

The cloud functions live in a separate codebase (`vf-bridge`, `functions-flutter`)
and are not part of this repo. This app only consumes their HTTP endpoints.

## Progress

The living backlog is `COMPLETION_PLAN.md`. A client‑facing progress + document
traceability write‑up (with screenshots) is in `design/ref/documentation/`.
