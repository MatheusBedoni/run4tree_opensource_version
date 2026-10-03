**English** | [Português](README.pt-BR.md)

<p align="center">
  <img src="docs/images/run4tree-logo.png" alt="Run4Tree logo" width="180">
</p>

<h1 align="center">Run4Tree 🌱🏃</h1>

Run4Tree is a Flutter app for running, walking, and cycling that turns physical activity and advertising revenue into progress toward planting real trees.

This is the open-source edition of the project. It preserves the individual experience and the app's essential features; proprietary social and operational modules are not included in this repository.

## Download the official app

The official, complete version of Run4Tree is available on Google Play:

[Download Run4Tree on Google Play](https://play.google.com/store/apps/details?id=com.run4tree.app)

## See Run4Tree in action

Click the image below to watch the demo on YouTube:

<p align="center">
  <a href="https://www.youtube.com/shorts/NXp-ivzOAGs">
    <img src="https://img.youtube.com/vi/NXp-ivzOAGs/hqdefault.jpg" alt="Watch the Run4Tree demo on YouTube" width="520">
  </a>
</p>

[Watch the video on YouTube](https://www.youtube.com/shorts/NXp-ivzOAGs)

## Official app screenshots

The screenshots below showcase the complete experience available in the official app. Some features shown here, including group challenges and the global forest, are not part of this open-source edition.

<table>
  <tr>
    <td align="center"><img src="docs/images/activity-map.png" alt="Activity tracking map" width="220"><br><sub>Map and activity tracking</sub></td>
    <td align="center"><img src="docs/images/progress.jpeg" alt="Exercise progress and history" width="220"><br><sub>Progress and history</sub></td>
    <td align="center"><img src="docs/images/personal-garden.jpeg" alt="Personal garden" width="220"><br><sub>Personal garden</sub></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/images/profile.png" alt="User profile" width="220"><br><sub>Profile</sub></td>
    <td align="center"><img src="docs/images/sticker-collection.jpeg" alt="Sticker collection" width="220"><br><sub>Sticker collection</sub></td>
    <td align="center"><img src="docs/images/share-progress.jpeg" alt="Activity sharing" width="220"><br><sub>Activity sharing</sub></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/images/reforestation-project-tanzania.png" alt="Reforestation project in Tanzania" width="220"><br><sub>Project in Tanzania</sub></td>
    <td align="center"><img src="docs/images/reforestation-project-uganda.png" alt="Reforestation project in Uganda" width="220"><br><sub>Project in Uganda</sub></td>
    <td align="center"><img src="docs/images/environmental-education.png" alt="Environmental education content" width="220"><br><sub>Environmental education</sub></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/images/group-challenge.png" alt="Group challenge in the official app" width="220"><br><sub>Group challenge — official app</sub></td>
    <td align="center"><img src="docs/images/global-forest.png" alt="Global forest in the official app" width="220"><br><sub>Global forest — official app</sub></td>
    <td></td>
  </tr>
</table>

## Available features

- GPS tracking for running, walking, and cycling;
- route map, time, distance, pace, speed, and calorie tracking;
- exercise history, details, statistics, and personal records;
- offline support using a local Drift/SQLite database;
- personal garden with seeds, pending trees, planted trees, and certificates;
- rewarded ads and banners that contribute to individual progress;
- activity result and route sharing;
- profile, onboarding, and sticker/achievement collection;
- weather, tree-planting notifications, and optional telemetry.

## Open-source edition scope

To keep the public codebase smaller and easier to understand, this edition does not include:

- the global forest, social feed, or public posts;
- group challenges, group activities, or rankings;
- production backend infrastructure or administrative dashboards.

External integrations are implemented defensively: when an optional configuration is unavailable, the app preserves local data and disables only the feature that depends on it. Planting real trees, however, requires a backend compatible with the Cloud Functions contract used by the app.

## Architecture

The code is organized by feature under `lib/features`, with separate presentation, domain, and data layers. Shared services, the local database, themes, and utilities live under `lib/core`.

```text
lib/
├── core/                 # database, services, theme, and utilities
├── features/
│   ├── auth/             # app entry flow
│   ├── onboarding/       # initial user profile
│   ├── home/             # map and activity tracking
│   ├── runs/             # activity sessions and completion
│   ├── exercises/        # history and statistics
│   ├── garden/           # personal seeds and trees
│   ├── profile/          # profile and institutional content
│   ├── share/            # activity sharing card
│   └── stickers/         # achievements and avatar
└── l10n/                 # internationalization
```

## Main technologies

- Flutter and Dart;
- Drift/SQLite for local persistence;
- Google Maps and Geolocator for maps and GPS;
- Firebase Auth, Firestore, and Cloud Functions for remote services;
- Google Mobile Ads and RevenueCat for the revenue flow;
- OneSignal for notifications;
- Sentry for observability.

## Requirements

- a Flutter version compatible with Dart `^3.9.2`;
- Android Studio or Xcode configured for your target platform;
- a Google Maps API key;
- your own Firebase configuration for authentication, synchronization, and remote tree planting.

The app currently focuses on Android and iOS. The other Flutter platform directories are retained, but their native integrations may require additional configuration.

## Getting started

1. Clone the repository and enter the project directory.

2. Install the dependencies:

   ```bash
   flutter pub get
   ```

3. Create your local environment file from the example:

   macOS/Linux:

   ```bash
   cp .env.example .env
   ```

   Windows PowerShell:

   ```powershell
   Copy-Item .env.example .env
   ```

4. On Android, add the following values to `android/local.properties`:

   ```properties
   GOOGLE_MAPS_API_KEY=your_google_maps_key
   ADMOB_API_KEY=ca-app-pub-3940256099942544~3347511713
   ```

   The AdMob value above is Google's official Android test App ID. Replace it with your own ID before distributing the app.

5. Configure your own Firebase project and add the native files, which are not committed to this repository:

   - Android: `android/app/google-services.json`;
   - iOS: `ios/Runner/GoogleService-Info.plist`.

   Enable anonymous authentication if you intend to use the remote planting flow.

6. Run the app:

   ```bash
   flutter run
   ```

To explore the interface without real ads, set `DEMO_ADS=true` in `.env`. Never place secrets in this file: it is bundled with the application.

## Quality and tests

```bash
flutter analyze
flutter test
```

The test suite covers sticker rules, exercises, sharing, reforestation projects, persistence, and tree-planting flows.

## Production notes

- replace AdMob test IDs before publishing;
- keep private tokens and administrative credentials exclusively on the backend;
- review the privacy policy and legal text for your own distribution;
- configure Firebase rules, indexes, and functions for your backend;
- validate permissions and API keys separately on Android and iOS.

Contributions are welcome through issues and pull requests.
