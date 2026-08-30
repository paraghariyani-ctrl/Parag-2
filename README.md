# CrewFlow

CrewFlow event and crew management app.

## Included
- Monthly event calendar
- Add / edit / delete events
- Client name, phone, venue, time and notes
- Multiple team members per role (e.g. 2 Candid, 2 Cinematographers, 3 Drone)
- Roles can be left unassigned when not needed
- Direct phone call button
- Direct WhatsApp button
- Team search and role filters
- Client / event search
- Phone Contacts import with permission
- Dark mode saved on device
- Offline local storage with SharedPreferences
- GitHub Actions workflow that builds a release APK

## GitHub upload
Upload the contents of this folder to the root of a new GitHub repository. Make sure `.github/workflows/build-apk.yml` is included.

After committing to `main`, open **Actions** and select **Build CrewFlow Android APK**. When it succeeds, open the run and download the `PHF-Android-APK` artifact.
