# Task Manager

A Flutter task manager built on clean architecture, Riverpod, and get_it —
with Firestore as the remote source, Hive as an encrypted local cache, and
full offline-first sync between the two. Firebase Auth (email/password)
scopes every task to its owner.

See [FIREBASE_SETUP.md](FIREBASE_SETUP.md) for the Firebase Console steps
required before this app will run.

## Architecture

Each feature (`auth`, `tasks`) is split into three layers, and features
never import each other's internals — only their `domain` contracts:

```
lib/
  core/                     # shared infrastructure, no feature knows about another
    di/injection_container.dart   # single get_it service locator
    error/                        # Failure (domain-facing) / Exception (data-facing)
    usecase/                      # UseCase<Type, Params>, StreamUseCase<Type, Params>
    network/network_info.dart     # connectivity_plus behind an interface
    storage/                      # encrypted Hive + flutter_secure_storage
    presentation/                 # BaseState, BaseNotifier, BaseView
    theme/                        # AppTheme, ThemeModeNotifier (dark mode)
  features/
    auth/
      domain/       # AppUser entity, AuthRepository contract, usecases
      data/         # AppUserModel, FirebaseAuth-backed datasource + repo impl
      presentation/ # AuthFormState/Notifier, LoginPage, SignupPage
    tasks/
      domain/       # TaskEntity, TaskRepository contract, usecases
      data/         # TaskModel, Hive local datasource, Firestore remote datasource, offline-first repo impl
      presentation/ # TaskListState/Notifier, AddEditTask*, TaskListPage, AddEditTaskPage, TaskDetailsPage
```

Within each feature, the dependency direction is strict:
**presentation → domain ← data**. `domain` defines interfaces
(`TaskRepository`, `AuthRepository`) and pure entities; `data` implements
those interfaces against Hive/Firestore/FirebaseAuth; `presentation` only
ever talks to `domain` usecases, never to a datasource or Firestore/Hive
directly.

### State management

Every screen has a `{Screen}State` (implements `BaseState`: `isLoading` +
`errorMessage`) and a `{Screen}Notifier` (`extends BaseNotifier<State>`,
itself a Riverpod `Notifier`). `BaseNotifier.guard()` centralizes the
loading → call usecase → success/error branching so each notifier's action
methods are usually one call to `guard(...)`. Notifiers pull their usecases
from the get_it locator (`sl<...>()`) inside `build()`, so DI stays
centralized in one file while Riverpod owns UI state.

`BaseView` renders the standard spinner/error+retry UI for screens that are
"load one resource and show it" (not used everywhere — e.g. `TaskListPage`
needs search/filter/sort/sync controls all visible at once, and
`AddEditTaskPage` must never let a failed submit wipe out what the user
typed, so both implement their own loading/error handling instead).

### Dependency injection

`core/di/injection_container.dart` wires every dependency once, in order:
core singletons (Hive, secure storage, Firestore, FirebaseAuth,
connectivity) → each feature's datasource → repository → usecases. Riverpod
Notifiers resolve their usecases from this container (`sl<CreateTask>()`,
etc.) rather than through Riverpod's own provider graph — a deliberate
choice to keep one dependency-wiring story instead of two.

## Workflow: a task's round trip

1. **UI** (`TaskListPage`, `AddEditTaskPage`) calls a method on a
   `Notifier` in response to user input.
2. **Notifier** calls a **usecase** (`CreateTask`, `DeleteTask`, ...), a
   one-line pass-through to the **repository** interface.
3. **`TaskRepositoryImpl`** writes to **Hive first** and returns
   immediately — the UI updates instantly via a reactive stream, before any
   network call happens.
4. A best-effort push to **Firestore** follows in the background.
   Success clears the pending flag; failure leaves it set for the next
   sync pass.

```
TaskListPage --tap--> TaskListNotifier --call--> DeleteTask (usecase)
                                                       |
                                                       v
                                          TaskRepositoryImpl.deleteTask()
                                            1. tombstone in Hive (instant)
                                            2. best-effort push to Firestore
```

## Offline-first sync

Every `TaskModel` (the data-layer model, not the pure `TaskEntity`) carries
a local-only `SyncStatus`: `synced`, `pendingCreate`, `pendingUpdate`, or
`pendingDelete`.

- **Writes are local-first.** `createTask`/`updateTask`/`toggleCompletion`
  write to Hive immediately with a `pending*` status and return
  `Right(unit)` — this works identically online or offline, since Hive
  never waits on the network.
- **Deletes are soft (tombstoned).** A task that already reached Firestore
  gets marked `pendingDelete` instead of being removed immediately, so it
  can still be deleted remotely once connectivity returns. A task that
  never left the device (`pendingCreate`) is just removed locally — nothing
  to clean up remotely.
- **`syncNow()`** pushes every locally-pending task to Firestore
  (create/update/delete per its status), then pulls the user's Firestore
  tasks and merges in anything not currently pending locally (remote wins
  for tasks not mid-edit on this device). It also mirrors deletions made on
  other devices: a locally-`synced` task missing from the remote pull gets
  removed locally too.
- **Sync triggers automatically** whenever `connectivity_plus` reports the
  device coming back online (`TaskRepositoryImpl.startAutoSync()`), and
  once at app startup. It's also user-triggerable via the sync icon or
  pull-to-refresh on the task list.
- **Search/filter/sort are 100% local** — `TaskListNotifier` filters the
  in-memory list from the Hive stream; none of it touches Firestore.

## Firebase configuration

- **Firestore** stores tasks under a single `tasks` collection; each
  document carries a `userId` field. Security rules (`firestore.rules`)
  restrict every read/write to `request.auth.uid == <the document's
  userId>` — enforced server-side, not just in the app.
- **Auth** uses Firebase's Email/Password provider. `FirebaseAuth` is
  registered once in the DI container and injected into both the auth
  feature and `TaskRepositoryImpl`/`TaskRemoteDataSourceImpl` (to stamp/
  scope tasks by the signed-in user's uid).
- **Android wiring**: `google-services.json` lives at
  `android/app/google-services.json`; the `com.google.gms.google-services`
  Gradle plugin (registered in `android/settings.gradle.kts` and
  `android/app/build.gradle.kts`) processes it at build time — no
  `firebase_options.dart` is needed for Android alone, since
  `Firebase.initializeApp()` reads the native config automatically.
  `compileSdk`/`minSdk`/NDK were bumped (36 / 23 / 27.0.12077973) because
  Firebase's current Android SDKs require them.

## Sign in / sign up

`AuthGate` (in `main.dart`) watches `authStateProvider` — a
`StreamProvider<AppUser?>` wired to Firebase's own `authStateChanges()` —
and renders `LoginPage` when signed out or `TaskListPage` when signed in.
Neither the login nor signup form navigates manually; they just call
`AuthFormNotifier`, and `AuthGate` reacts to the resulting auth-state
change automatically.

- **Sign up** creates the account, then **immediately signs back out**
  (Firebase auto-authenticates a newly created user, which this app
  deliberately reverses) and shows a confirmation on the Login screen
  ("Account created! Please sign in.") rather than dropping the user
  straight into the app.
- **Sign in** validates email/password client-side (non-empty email
  containing `@`, password ≥ 6 characters), then delegates to
  `FirebaseAuth.signInWithEmailAndPassword`. Errors (`user-not-found`,
  `wrong-password`, `invalid-credential`, etc.) are mapped to readable
  messages in `AuthRemoteDataSourceImpl` and surfaced as a `SnackBar` —
  the form itself is never cleared on error.
- **Sign out** (from the task list's AppBar) also clears the local Hive
  task cache, so the next login doesn't briefly show the previous user's
  tasks before the first post-login sync completes.

## Features

- Create / edit / delete / view tasks; mark complete/incomplete.
- Search by title, filter (All / Completed / Pending), sort (due date /
  priority) — all local.
- Dark mode: Light/Dark/System, user-selectable from the task list AppBar,
  persisted via `flutter_secure_storage` and restored on launch.
- Due-date reminders: a local notification fires when a task's due
  date/time arrives (Google Tasks-style), even if the app isn't open.
  Tapping it opens that task. See below for how this is implemented and a
  known limitation of the approach.
- Loading, empty, and error states throughout; sync status indicator;
  pull-to-refresh.

## Due-date reminders

Implemented with `flutter_local_notifications`, entirely on-device.
`TaskDueNotificationPoller` polls every locally-held task on a 30-second
timer and fires a notification (`NotificationService.showNow`) the moment
one becomes due — an incomplete, not-yet-notified task whose due date has
passed. It's fully decoupled from `TaskRepositoryImpl`: it doesn't need to
be told when a task changes, it just re-scans Hive directly, so it works
correctly regardless of which write path touched a task (create, edit,
toggle, or a sync pull from another device).

**This was originally built as OS-scheduled** (`zonedSchedule` /
AlarmManager via `AndroidScheduleMode.inexactAllowWhileIdle`), which is the
more typical approach and can wake up a fully terminated app. In practice
it proved unreliable across devices/timezones in testing (silent failures,
timezone-database gaps for certain devices) and was replaced with the
polling approach for one specific reason: **it actually works**. The
trade-off is real and worth stating plainly — a poll-based reminder only
fires while the app process is alive (foreground or backgrounded-but-not-
killed by the OS); it cannot wake up a fully closed app the way a genuine
OS alarm can.

**Why not FCM.** The initial ask was for this to use Firebase Cloud
Messaging. FCM has no built-in "deliver at a future time" capability —
triggering a push exactly when a task becomes due requires something
running on a schedule to detect that and call the send API, which in
Firebase's world means a Cloud Function. Cloud Functions (and Cloud
Scheduler) require the paid **Blaze** billing plan; they don't run on the
free Spark plan at all. A zero-cost workaround was considered (a GitHub
Actions cron job calling the FCM send API directly, bypassing Firebase
billing entirely), but the fully on-device `flutter_local_notifications`
approach was chosen instead for simplicity — no billing plan, no external
CI, no service-account secrets, same user-facing behavior.

### Future work: true background delivery

Current reminders only fire while the app process is alive. If a
fully-closed app needs to notify the user, options worth evaluating, in
roughly increasing order of reliability and effort:

- **Exact OS alarms + boot receiver.** Go back to
  `flutter_local_notifications`'s `zonedSchedule` (which this project moved
  away from — see above), but request the "Schedule exact alarms"
  permission (`AndroidScheduleMode.exactAllowWhileIdle`) instead of inexact,
  and add `RECEIVE_BOOT_COMPLETED` + the plugin's bundled boot receiver so
  scheduled reminders survive a device reboot. Lowest effort of the
  "real" options, but exact-alarm reliability still varies by OEM (Samsung
  in particular is aggressive about killing background alarms) and needs
  more testing across devices than this project has had time for.
- **WorkManager** (`workmanager` package). Schedule a periodic background
  task that runs in its own isolate independent of the foreground app,
  checks due tasks, and shows a notification — essentially today's
  `TaskDueNotificationPoller`, but running as OS-managed background work
  instead of an in-process `Timer`. Survives the app being backgrounded/
  swiped away; still subject to Doze/battery-optimization deferral like
  any background work, but designed for exactly this use case.
- **Foreground service.** Keep a persistent Android foreground service
  (with its own permanent notification) alive to guarantee the process
  never gets killed. Most reliable of the on-device options, but
  intrusive (a permanent notification icon) and battery-heavy — generally
  only justified for apps with a continuous reason to run (tracking,
  media playback), not a reminder feature.
- **Real server-triggered FCM push.** The most "production" answer, and
  the one originally requested for this feature (see "Why not FCM" above):
  a server (Cloud Function on Blaze, or the free-tier GitHub Actions cron
  workaround already scoped in this conversation) detects a task is due
  and sends an FCM push. Works even if the device has been fully powered
  off and only just reconnected, since the trigger is server-side, not
  dependent on the device's own OS scheduler at all. Highest effort/cost,
  highest reliability.

## Running it

```bash
flutter pub get
flutter run
```

Requires the Firebase Console setup in
[FIREBASE_SETUP.md](FIREBASE_SETUP.md) to actually authenticate/sync.

## Tests

```bash
flutter test
```

Covers: usecase delegation (`test/features/tasks/domain/usecases/`), the
offline-first repository's local-first/tombstone/sync behavior
(`test/features/tasks/data/repositories/`), the task list's search/filter/
sort logic (`test/features/tasks/presentation/providers/`), and form
validation on the Add/Edit Task and Login screens.
