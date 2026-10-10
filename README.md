# PetCareHub – Android app (Flutter + Firebase)

A Mobile Pet Health and Service Management System, built from the PetCareHub
concept paper and the 15 wireframes.

| Wireframe | Screen in the app | File |
|---|---|---|
| 01 Login | Log in, show/hide password, forgot password (email reset link) | `lib/screens/auth/login_screen.dart` |
| 02 Register | Create account with validation + Terms checkbox | `lib/screens/auth/register_screen.dart` |
| 03 Dashboard | Greeting, live stats, vaccine reminder banner, pets row, upcoming bookings, quick actions, side menu, notification badge | `lib/screens/dashboard_screen.dart` |
| 04 My Pets | Search, pet cards, swipe left → Edit / Delete, + button | `lib/screens/pets/pets_screen.dart` |
| 05 Pet profile | Photo, Age/Gender/Weight, Vaccines / Appointments / Notes tabs, edit, delete, book | `lib/screens/pets/pet_profile_screen.dart` |
| 06 Add Pet | Photo (camera/gallery), name, species, breed, birthdate, weight, gender — also used for editing | `lib/screens/pets/add_pet_screen.dart` |
| 07 Vaccinations | Filter by pet, search, “Due soon” + history, tap a record to edit/delete | `lib/screens/vaccines/vaccinations_screen.dart` |
| 08 Add Vaccination | Pet, vaccine, date given, next due (auto +1 year), clinic, 3-day reminder | `lib/screens/vaccines/add_vaccine_screen.dart` |
| 09 Services | Search, category chips, grid with pictures | `lib/screens/services/services_screen.dart` |
| 10 Service detail | Banner image, rating/duration/price, includes, hours, tap-to-call, open in Google Maps | `lib/screens/services/service_detail_screen.dart` |
| 11 Booking | Step indicator, pet picker, service, calendar (Sundays closed), live time slots (taken slots are crossed out), notes, 1-day reminder, total | `lib/screens/booking/booking_screen.dart` |
| 12 Confirm dialog | Summary with Edit / Confirm | inside `booking_screen.dart` |
| 13 Success | Booking ID, details, reminder time, buttons | `lib/screens/booking/booking_success_screen.dart` |
| 14 My Appointments | Upcoming / Past / Cancelled tabs, Reschedule, Cancel (24-hour rule), status legend, search | `lib/screens/appointments/appointments_screen.dart` |
| 15 Notifications | Today / Earlier, unread dots, mark all read, swipe to delete | `lib/screens/notifications_screen.dart` |

Extras: Profile screen (edit name/mobile, change password, log out), phone
reminders that still fire when the app is closed, a time slot can't be
double-booked by two users, past bookings are marked *Completed* automatically,
and when an appointment's status is changed to `confirmed` in Firestore the
user gets an “Appointment confirmed” notification.

Pet photos are compressed and saved inside Firestore, so you **don't need
Firebase Storage or the paid Blaze plan** — the free Spark plan is enough.

---

## What you need

1. **Flutter SDK 3.27 or newer** – https://docs.flutter.dev/get-started/install
   (`flutter --version` to check; `flutter upgrade` to update)
2. **Android Studio** (for the Android SDK and an emulator) – or a real Android phone with USB debugging on
3. **VS Code** with the *Flutter* and *Dart* extensions
4. **Node.js** (for the Firebase CLI) – https://nodejs.org
5. A Google account for Firebase

Run `flutter doctor` and fix anything marked ✗ for Android.

---

## Setup (do these once, in order)

Open the unzipped `petcarehub` folder in VS Code, then open the terminal
(**Terminal → New Terminal**) and run:

### 1. Generate the Android project files
```bash
flutter create --platforms android --org com.petcarehub --project-name petcarehub .
```
(The dot at the end matters. This only adds missing files; it won't touch the
code in `lib/`.)

### 2. Patch the Android build settings
```bash
dart run tool/setup_android.dart
```
This enables desugaring (needed for reminders) and sets minSdk to 23 (needed by
Firebase Auth).

### 3. Get the packages
```bash
flutter pub get
```

### 4. Create the Firebase project
1. Go to https://console.firebase.google.com → **Add project** → name it `PetCareHub` (Analytics can be off).
2. **Build → Authentication → Get started → Sign-in method → Email/Password → Enable → Save.**
3. **Build → Firestore Database → Create database** → pick a location (e.g. `asia-southeast1`) → start in **production mode**.
4. Open the **Rules** tab, delete everything, paste the contents of `firestore.rules` from this project, and click **Publish**.

### 5. Connect the app to Firebase (no CLI needed)
1. Firebase Console → ⚙ **Project settings** → **Your apps** → click the **Android** icon.
2. **Android package name:** `com.petcarehub.petcarehub` (must match exactly) → **Register app**.
3. **Download `google-services.json`** and put it in `android/app/`.
4. In the VS Code terminal run:
   ```bash
   dart run tool/make_firebase_options.dart
   ```
   This fills in `lib/firebase_options.dart` with your project's keys.

*Alternative:* `npm install -g firebase-tools`, `firebase login`,
`dart pub global activate flutterfire_cli`, `flutterfire configure --platforms=android`
does the same thing automatically.

### 6. (Optional) App icon
```bash
dart run flutter_launcher_icons
```

### 7. Run it
Start an emulator (or plug in your phone), then press **F5** in VS Code or run:
```bash
flutter run
```
Build an installable APK with `flutter build apk --release`
(output: `build/app/outputs/flutter-apk/app-release.apk`).

---

## How to demo every feature

1. **Sign up** → you land on the dashboard. Allow notifications when asked.
2. **Add Pet** (Quick Actions or Pets tab +) → add a photo, species, breed, birthdate.
3. **Add Vaccine** → set *Next due date* to a few days from now → the dashboard
   shows the yellow reminder banner and Notifications shows “Vaccine due in N days”.
4. **Services** → pick one → **Book This Service** → choose a date and time → **Review & Confirm** → **Confirm**.
5. **Bookings** tab → Reschedule or Cancel (allowed until 24 hours before).
6. To show the **Confirmed** status: Firebase Console → Firestore →
   `users/{yourUid}/appointments/{id}` → change `status` to `confirmed`. The app
   updates live and sends an “Appointment confirmed” notification.
7. Log in with a **second account** and try booking the same service, date and
   time — that slot shows as crossed out.

## Firestore structure
```
users/{uid}                     fullName, email, mobile
users/{uid}/pets/{id}           name, species, breed, birthdate, weight, gender, photoBase64, notes
users/{uid}/vaccinations/{id}   petId, petName, vaccineName, dateGiven, nextDueDate, clinic, remind
users/{uid}/appointments/{id}   bookingId, petId, serviceId, dateTime, slot, status, price, notes, remind
users/{uid}/notifications/{id}  title, body, type, read, createdAt, showAt
bookedSlots/{serviceId_date}    slots: ["10:00 AM", ...]
```
The service list (prices, clinics, pictures) is in `lib/data/catalog.dart` —
edit it to change services.

## Troubleshooting
- **“Firebase is not configured yet”** → you skipped step 5 (the keys in `lib/firebase_options.dart` are still placeholders).
- **Build error about desugaring / `coreLibraryDesugaring`** → run step 2 again, then `flutter clean` and `flutter run`.
- **“requires Android NDK …” message** → open `android/app/build.gradle.kts` and set `ndkVersion = "<the version in the message>"`.
- **Version conflict during `flutter pub get`** → run `flutter pub upgrade --major-versions`.
- **`PERMISSION_DENIED` from Firestore** → the rules from step 4 weren't published.
- **Login says “Incorrect email or password” for a new account** → Email/Password sign-in isn't enabled (step 4.2).
- **Reminders don't appear** → Android Settings → Apps → PetCareHub → Notifications → allow. Reminders are scheduled for 1 day before an appointment and 3 days (9:00 AM) before a vaccine due date, so to test quickly book something 2+ days away and change the phone's clock, or just check the instant “Booking received” notification.
