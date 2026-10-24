# Attendance Flutter

Flutter starter project migrated from the uploaded Kivy attendance application.

## Build an Android APK with Codemagic (without installing Flutter locally)

This repository includes `codemagic.yaml`. The workflow first runs
`flutter create --platforms=android .` to generate the missing Android platform
folder in Codemagic's temporary build checkout, then resolves dependencies and
builds a debug APK. The generated Android files are created during the cloud
build and do not need to be present in GitHub beforehand.

1. Upload/commit all files in this project to the root of the GitHub repository.
2. In Codemagic, open the app connected to this repository.
3. If Codemagic offers workflow selection, select the workflow from `codemagic.yaml`
   named **Attendance Flutter Android APK**. YAML configuration takes precedence
   over Workflow Editor settings when a YAML workflow is used.
4. Start the `android-apk` workflow on branch `main`.
5. When successful, download the APK from the build's Artifacts section.

## CSV storage

- `assets/combined_data.csv` is the initial dataset bundled with the app.
- On first launch it is copied into the app's documents directory.
- Changes are written to the app's private `combined_data.csv`, not back into the bundled asset.
- To replace the initial data before first launch, replace the asset CSV and rebuild.
- CSV header and RecordType values are retained: `student`, `attendance`, `label`.

## Current implementation

Includes student list/search, labels filtering, add/edit/delete students, class-day selection, attendance registration with optional pending flag and date picker, remaining-session decrement, term renewal, reports, class-day calendar, language toggle, and local CSV persistence.

This is a generated migration starter. The Android build must still be run in Codemagic to verify compilation.
