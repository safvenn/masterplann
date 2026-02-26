# Trip Planner Flutter App — Firebase Setup Guide

## 🔥 Firebase Project Setup (Required Before Running)

### Step 1: Create a Firebase Project
1. Go to **[https://console.firebase.google.com](https://console.firebase.google.com)**
2. Click **Add Project** → name it `trip-planner`
3. Disable Google Analytics (optional) → **Create Project**

---

### Step 2: Enable Firebase Services

#### Authentication
1. In Firebase Console → **Build > Authentication**
2. Click **Get started** → **Sign-in method**
3. Enable **Email/Password** provider → Save

#### Firestore Database
1. **Build > Firestore Database** → **Create database**
2. Choose **Start in test mode** (for development)
3. Pick a region closest to you → **Done**

---

### Step 3: Add Apps to Firebase

#### Android
1. **Project Settings** > **Add app** → Android icon
2. Android package name: `com.tripplanner.tripPlannerApp`
3. Download `google-services.json`
4. Place it at: `android/app/google-services.json`

#### iOS
1. **Add app** → Apple icon
2. Bundle ID: `com.tripplanner.tripPlannerApp`
3. Download `GoogleService-Info.plist`
4. Place it at: `ios/Runner/GoogleService-Info.plist`

#### Web
1. **Add app** → Web icon
2. Register app name
3. Copy the Firebase config values

---

### Step 4: Configure the App

**Option A — FlutterFire CLI (Recommended)**
```bash
# Install the CLI
dart pub global activate flutterfire_cli

# In the project root:
flutterfire configure

# This auto-generates lib/firebase_options.dart
```

**Option B — Manual**
Open `lib/firebase_options.dart` and replace all `YOUR_*` placeholders with real values from **Firebase Console > Project Settings > Your Apps**.

---

### Step 5: Set up Android gradle files

In `android/build.gradle` (project level), add:
```gradle
plugins {
    id 'com.google.gms.google-services' version '4.4.0' apply false
}
```

In `android/app/build.gradle`, add at the bottom:
```gradle
apply plugin: 'com.google.gms.google-services'
```

---

### Step 6: Firestore Security Rules (Production)
Replace the default test rules with:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    // Anyone can read packages, hotels, destinations
    match /packages/{id} { allow read: if true; allow write: if request.auth.token.isAdmin == true; }
    match /hotels/{id} { allow read: if true; allow write: if request.auth.token.isAdmin == true; }
    match /destinations/{id} { allow read: if true; allow write: if request.auth.token.isAdmin == true; }
    // Bookings: users manage their own
    match /bookings/{id} {
      allow read: if request.auth != null && (resource.data.userId == request.auth.uid);
      allow create: if request.auth != null;
    }
  }
}
```

---

### Step 7: Make a User an Admin
In Firestore Console, open the `users` collection, find your user document, and set:
```json
{ "isAdmin": true }
```

---

## 🚀 Running the App

```bash
# Get dependencies
flutter pub get

# Run on Android emulator / device
flutter run

# Run on Chrome (web)
flutter run -d chrome

# Release build
flutter build apk --release       # Android
flutter build ios --release        # iOS
flutter build web --release        # Web
```

---

## 📁 Project Structure
```
lib/
├── main.dart                    # App entry + Firebase init
├── router.dart                  # GoRouter navigation
├── firebase_options.dart        # Firebase config (you fill this)
├── models/
│   ├── package_model.dart
│   ├── hotel_model.dart
│   ├── destination_model.dart
│   ├── booking_model.dart
│   └── user_model.dart
├── services/
│   ├── auth_service.dart        # Firebase Auth wrapper
│   └── firestore_service.dart   # Firestore CRUD + streams
├── providers/
│   ├── auth_provider.dart       # Auth state management
│   └── trip_provider.dart       # Packages, bookings, CRUD
├── utils/
│   └── app_theme.dart           # Dark theme colors + styles
└── screens/
    ├── home/home_screen.dart          # Package listing
    ├── package/package_detail_screen.dart  # Detail + day planner
    ├── booking/
    │   ├── booking_screen.dart        # Confirmation
    │   └── my_bookings_screen.dart    # User's trips
    ├── auth/
    │   ├── login_screen.dart
    │   └── register_screen.dart
    └── admin/admin_screen.dart        # Full CRUD admin panel
```

## ✨ Features
- **Real-time data** via Firestore streams
- **Firebase Authentication** (email/password)
- **Dark theme** matching the web version
- **Day Planner** per-day destination + hotel selection
- **Admin Panel** with full CRUD for packages, hotels, destinations
- **Booking system** stored in Firestore
- **Go Router** navigation with auth guards
- **Cached network images** with shimmer loading
