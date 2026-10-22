# Attendance Flutter

Flutter starter project migrated from the uploaded Kivy attendance application.

## Run
1. Install Flutter SDK and Android Studio (or Xcode for iOS).
2. Extract this folder.
3. In the project directory run:
   ```bash
   flutter pub get
   flutter run
   ```

## CSV storage
- `assets/combined_data.csv` is the initial dataset bundled with the app.
- On first launch it is copied into the app's documents directory.
- Changes are written to the app's private `combined_data.csv`, not back into the bundled asset.
- To replace the initial data before first launch, replace the asset CSV and rebuild.
- CSV header and RecordType values are retained: `student`, `attendance`, `label`.

## Current implementation
Includes student list/search, labels filtering, add/edit/delete students, class-day selection,
attendance registration with optional pending flag and date picker, remaining-session decrement,
term renewal, reports, class-day calendar, language toggle, and local CSV persistence.

## Notes
This is a generated migration starter and should be run and tested in your local Flutter environment.
The Flutter SDK is not available in this generation environment, so a device build was not performed.
