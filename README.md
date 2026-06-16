# aroma-mobile-app

Application mobile Flutter pour **Aroma JPC**, connectée à l’API CRM Aroma.

## Fonctionnalités

- Authentification et sélection d’entité (multi-entité)
- Accueil, analytics, tâches, interventions
- RH, comptabilité, caisse, validation
- Galerie documentaire

## Prérequis

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (SDK ^3.11)
- Un appareil ou émulateur iOS / Android

## Installation

```bash
flutter pub get
```

Configurer l’URL de l’API dans `assets/env/app.env` :

```env
API_BASE_URL=https://aroma-jpc-crm-api.aroma-digitalisation.cloud
```

## Lancement

```bash
flutter run
```

## Stack

- Flutter
- Provider (état global)
- HTTP (API REST Aroma)
