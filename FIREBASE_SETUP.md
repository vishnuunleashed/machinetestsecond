# Firebase Setup

Steps required in the Firebase Console before this app will authenticate or
sync — none of these can be done from the app's code.

Project: **machinetestsecond** (Android app `com.example.machinetestsecond`,
config already committed at `android/app/google-services.json`).

## 1. Enable Email/Password sign-in

Firebase Console → **Authentication** → **Sign-in method** → enable
**Email/Password**.

## 2. Publish Firestore security rules

Firebase Console → **Firestore Database** → **Rules** → paste the contents
of [`firestore.rules`](firestore.rules) → **Publish**:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /tasks/{taskId} {
      allow read, update, delete: if request.auth != null
        && request.auth.uid == resource.data.userId;
      allow create: if request.auth != null
        && request.auth.uid == request.resource.data.userId;
    }
  }
}
```

Every task document must carry a `userId` field matching the signed-in
user's uid — the app stamps this automatically, but any data created
outside the app (e.g. seeded manually in the console) needs it too, or
these rules will reject it.

## 3. Confirm the Firestore database exists

Firebase Console → **Firestore Database** should already show a database
in production mode for this project. If not, create one (any region).

## Android build requirements

Already configured in this repo, listed here for reference if you're
setting up a new Firebase-connected Android app from scratch:

- `android/settings.gradle.kts` — `com.google.gms.google-services` plugin
  declared in the `plugins {}` block.
- `android/app/build.gradle.kts` — the plugin applied, plus
  `compileSdk = 36`, `minSdk = 23`, `ndkVersion = "27.0.12077973"` (current
  Firebase Android SDKs require all three).
- `android/app/src/main/AndroidManifest.xml` — `INTERNET` and
  `ACCESS_NETWORK_STATE` permissions.

## Adding iOS or Web

Only the Android app is registered in this Firebase project. To add
another platform:

1. Register the app in Firebase Console → Project settings → Add app.
2. Run `flutterfire configure` (requires the Firebase CLI and
   `firebase login`) to generate `lib/firebase_options.dart` covering all
   registered platforms.
3. Change `Firebase.initializeApp()` in `lib/main.dart` to
   `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`.

## Troubleshooting

- **"Unable to establish connection on channel ...initializeCore"** at
  startup: stale Gradle build cache from an earlier failed build. Run
  `flutter clean` and rebuild.
- **Auth/Firestore calls fail even with working WiFi**: confirm
  `AndroidManifest.xml` has the `INTERNET` permission (missing it blocks
  all network access regardless of connectivity state) and that a full
  rebuild (not hot reload) picked up any recent manifest/Gradle changes.
