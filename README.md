# Campus Incident Reporting App

Flutter app (Android/iOS) for students to report campus issues and for staff to
review them and update their status.

**Stack:** Flutter, Riverpod (`flutter_riverpod`), Firebase Auth, Cloud Firestore,
Firebase Storage, `image_picker`.

## Features
- Email/password sign-up and sign-in with form validation, sign-out
- Roles: `student` (report, browse, track) and `staff` (everything + update status, dashboard)
- Submit a report: title, category, location, description, optional photo (camera/gallery, compressed, upload progress)
- Real-time list of reports (Firestore streams), search, category and status filters, pull-to-refresh
- "My reports" tab, status badges, report detail with status timeline
- Staff dashboard with counts per status and a queue of new reports
- Loading / empty / error states, light and dark theme
- Security enforced by Firestore and Storage rules, not just the UI

## Architecture
```
lib/
  core/        theme, constants (enums), validators, shared widgets, Firebase providers
  features/
    auth/      models, AuthRepository, providers (AuthController), screens
    incidents/ models, IncidentRepository, providers, screens, widgets
    staff/     staff dashboard
```
UI -> Riverpod providers/controllers -> Repositories -> Firebase. Widgets never call Firebase directly.

## Firestore data model
- `users/{uid}`: name, email, role (`student|staff`), createdAt
- `incidents/{id}`: title, description, category, status, location, imageUrl, reporterId, reporterName, createdAt, updatedAt, lastNote
- `incidents/{id}/statusHistory/{eventId}`: oldStatus, newStatus, changedBy, changedByName, note, timestamp
- Storage: `incident_images/{uid}/{incidentId}.jpg`

## Setup (first time)
1. Install Flutter, then create the native platform folders **inside this folder**:
   ```
   flutter create . --project-name campus_incident_app --org com.example
   ```
   (This adds `android/` and `ios/` without touching `lib/`.)
2. Create a Firebase project at https://console.firebase.google.com and enable:
   - **Authentication -> Email/Password**
   - **Firestore Database** (production mode)
   - **Storage**
3. Connect the app (this overwrites `lib/firebase_options.dart`):
   ```
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
4. Android: in `android/app/build.gradle(.kts)` set `minSdk = 23` (Firebase requires it).
   iOS: add to `ios/Runner/Info.plist`:
   `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` (any text).
5. Publish the rules: paste `firestore.rules` into Firestore -> Rules and
   `storage.rules` into Storage -> Rules (or `firebase deploy --only firestore:rules,storage`).
6. Run:
   ```
   flutter pub get
   flutter run
   ```
   Use an Android emulator / iOS simulator / real device (not Chrome).

## Creating a staff account (for the demo / graders)
1. Register normally in the app (it creates a `student`).
2. In Firebase console -> Firestore -> `users/{that user's uid}` -> change `role` to `staff`.
3. Sign out and sign in again.

Test credentials (replace with yours before submitting):
- Student: `student@example.com` / `Password123`
- Staff: `staff@example.com` / `Password123`

## Tests
```
flutter test
```
Covers validators, search/filter logic, model parsing, the filter notifier and a widget test.

## Access control
| Action | Student | Staff |
|---|---|---|
| Create report (as self, status `submitted`) | yes | yes |
| Read reports | yes | yes |
| Change report status / add history | no | yes |
| Change own role | no | no |
| Staff dashboard | hidden | yes |

## Possible extensions
Push notifications on status change (Cloud Functions + FCM), report upvotes, map picker for location, CSV export for staff.
