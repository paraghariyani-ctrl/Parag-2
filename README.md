# CrewFlow

A Flutter Android app for event calendar, crew assignment and quotation management.

## What is fixed in this version

- `flutter_contacts` is pinned to `1.4.5+1`.
- Contacts permission uses the API supported by that pinned version.
- Contact names handle nullable `displayName`.
- PDF text no longer uses the unsupported `leading` parameter.
- Android READ_CONTACTS permission is included.
- Java 17 is configured for Android.
- GitHub Actions builds a release APK and uploads it as an artifact.
- Data is stored locally with SharedPreferences.

## GitHub

1. Replace your existing `lib/main.dart` with the included `lib/main.dart`.
2. Replace `pubspec.yaml`.
3. Replace `.github/workflows/build-apk.yml`.
4. Make sure the Android files from this project are present.
5. Push to GitHub.
6. Open **Actions → Build CrewFlow APK → Run workflow**.
7. When complete, open the workflow run and download **crewflow-release-apk**.

## Important

The Google button on the login screen is a local UI/login placeholder in this build. It does not implement real Google authentication.
