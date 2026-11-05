# SBPDCL OCR – IT Asset & Consumer Inspection Management

[**DOWNLOAD LATEST ANDROID APK**](https://github.com/aqabsam/sbpdcl_ocr/releases/latest)

## Overview

SBPDCL OCR is an offline-first Android field application for consumer lookup, meter reading recognition, and inspection management. Consumer records and inspections are stored on the device in SQLite. The app can import consumer datasets from CSV and Excel files, scan meter images with on-device text recognition, and record inspection readings, photos, and location.

## Key features

- Search consumers by meter number, CA number, account number, name, or address
- Import CSV, XLSX, and XLS consumer files with validation and duplicate handling
- Recognize meter numbers from camera captures or gallery images using on-device OCR
- Record meter condition, findings, readings, photos, GPS coordinates, and remarks
- Review inspection history and related consumer details
- Store consumer and inspection records locally for offline use
- Employee sign-in, profile management, and password change

On a new installation, register an employee from the login screen. No shared default account is created.

## Technology stack

- Flutter and Dart
- SQLite (`sqflite`)
- Google ML Kit text recognition
- Camera, image picker, file picker, and geolocation plugins

## Download the Android app

Get the latest APK from [GitHub Releases](https://github.com/aqabsam/sbpdcl_ocr/releases). Open the release on your Android device, download `app-release.apk`, and install it. Android may ask you to allow installation from your browser or file manager.

## Install from source

1. Install the [Flutter SDK](https://docs.flutter.dev/get-started/install) and Android build tools.
2. Clone this repository and install its Dart dependencies:

   ```sh
   git clone https://github.com/aqabsam/sbpdcl_ocr.git
   cd sbpdcl_ocr
   flutter pub get
   ```

3. Connect an Android device or start an emulator, then run:

   ```sh
   flutter run
   ```

To build a release APK locally:

```sh
flutter build apk --release
```

The APK is written to `build/app/outputs/flutter-apk/app-release.apk`.

## Data and privacy

Consumer information imported into the app and inspection records are stored in the app's local SQLite database. The app does not require a remote application server. Import only data you are authorized to use, and protect device backups and exported files accordingly. The repository's bundled CSV is sample data; operational consumer spreadsheets are not included.

## Source and releases

- [Source repository](https://github.com/aqabsam/sbpdcl_ocr)
- [All GitHub Releases](https://github.com/aqabsam/sbpdcl_ocr/releases)
- [Latest Android APK](https://github.com/aqabsam/sbpdcl_ocr/releases/latest)
