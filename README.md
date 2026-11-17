# Pos Café

Flutter POS for cafés & restaurants (Windows + Android). Works offline: everything is
saved locally first, then synced with [Backend_Platform](https://github.com/samimh23/Backend_Platform).

## Run

```bash
flutter pub get
flutter run -d windows                                   # backend at http://localhost:3000
flutter run -d windows --dart-define=API_URL=http://192.168.1.10:3000
```

First launch shows the **pairing screen**: enter a pairing code (for now from `pnpm db:seed` in the backend).

## Tests

```bash
flutter test                         # unit + widget tests (no backend needed)
E2E_PAIR_CODE=XXXX-XXXX flutter test test/e2e   # against a real running backend
```

After changing Drift tables: `dart run build_runner build --delete-conflicting-outputs`.

## Architecture: MVVM + Riverpod

```
View (widgets)  →  ViewModel (Riverpod Notifier)  →  Model (repositories + services)
                                                        │
                                   local DB (Drift/SQLite) ←→ Sync engine ←→ Backend
```

```
lib/
├── main.dart, app/            start gate: not paired → pairing, paired → home
├── core/
│   ├── money/                 Money (millimes), VAT split — same rules as the backend
│   ├── db/                    Drift tables + AppDatabase (generated *.g.dart committed)
│   ├── api/                   PosApi (interface) + DioPosApi, ApiException
│   ├── device/                pairing, identity, secure storage (token, Ed25519 key)
│   ├── sync/                  outbox (events), SyncEngine (push/pull), SyncController (background)
│   ├── providers.dart         shared services (override them in tests)
│   └── config.dart            API_URL, sync interval
└── features/<feature>/
    ├── view_model/            screen state + actions (no widgets)
    └── view/                  screens + widgets (no logic, no DB, no HTTP)
```

## Rules
1. The UI reads the **local DB** only — never waits for the internet.
2. Every data change records an **event in the outbox in the same transaction**.
3. Widgets never call repositories; ViewModels do.
4. Only repositories touch Drift, HTTP or secure storage.
5. Money = integer **millimes**, VAT in **basis points**, IDs = **UUID v7**.
6. Secrets (device token, private key) only in secure storage.
