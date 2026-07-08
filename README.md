# Share — Group Expense Splitting

A Split-styler-style app for splitting expenses with friends and family. Runs on **web, Android, and iOS** from a single Flutter codebase. The backend is **Firebase** (Authentication + Cloud Firestore), so anyone who clones this repo gets their own independent instance with their own data.

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Create the Firebase project](#2-create-the-firebase-project)
3. [Clone and set up the repo](#3-clone-and-set-up-the-repo)
4. [Connect Firebase to Flutter](#4-connect-firebase-to-flutter)
5. [Platform configuration](#5-platform-configuration)
   - [Web](#web)
   - [Android](#android)
   - [iOS](#ios)
6. [Firestore security rules](#6-firestore-security-rules)
7. [Run locally](#7-run-locally)
8. [Deploy to web (Firebase Hosting)](#8-deploy-to-web-firebase-hosting)
9. [Data model](#9-data-model)

---

## 1. Prerequisites

Install the following tools before getting started:

| Tool | Minimum version | Download |
|---|---|---|
| Flutter SDK | 3.22+ | https://docs.flutter.dev/get-started/install |
| Dart SDK | 3.4+ | included with Flutter |
| Node.js | 18+ | https://nodejs.org |
| Firebase CLI | latest | `npm install -g firebase-tools` |
| FlutterFire CLI | latest | `dart pub global activate flutterfire_cli` |
| Git | any | https://git-scm.com |

For iOS you also need a Mac with Xcode 15+ and CocoaPods:

```bash
sudo gem install cocoapods
```

Verify everything is working:

```bash
flutter doctor
```

---

## 2. Create the Firebase project

### 2.1 Create the project

1. Go to [console.firebase.google.com](https://console.firebase.google.com) and sign in with your Google account.
2. Click **Add project**.
3. Choose a name (e.g. `my-share-app`) and follow the wizard. You can disable Google Analytics if you don't need it.

### 2.2 Enable Authentication

1. In the sidebar: **Build → Authentication → Get started**.
2. Go to the **Sign-in method** tab.
3. Enable the providers you want to use:
   - **Email/Password** — always required.
   - **Google** — for Google login (web + Android + iOS).
   - **Apple** — only if you want Apple login on iOS.

### 2.3 Enable Cloud Firestore

1. **Build → Firestore Database → Create database**.
2. Select **Start in production mode** (we'll add security rules in step 6).
3. Choose a region close to your users (e.g. `europe-west1`).

### 2.4 Enable Firebase Hosting (web only)

1. **Build → Hosting → Get started** and follow the wizard steps.
2. No additional configuration needed here; we'll do it from the CLI.

---

## 3. Clone and set up the repo

```bash
git clone https://github.com/YOUR_USERNAME/share.git
cd share
flutter pub get
```

---

## 4. Connect Firebase to Flutter

This is the most important step. The FlutterFire CLI automatically generates `lib/firebase_options.dart` with the keys for **your** Firebase project.

```bash
# Log in to Firebase
firebase login

# Connect the project (run from the repo root)
flutterfire configure
```

The command will ask you to:

- **Select a project**: choose the one you created in step 2.
- **Platforms**: select the ones you need (`web`, `android`, `ios`).

When it finishes, it will have generated/updated:

- `lib/firebase_options.dart` — Dart configuration (for all platforms)
- `android/app/google-services.json` — Android configuration
- `ios/Runner/GoogleService-Info.plist` — iOS configuration

> ⚠️ **Do not share these files** if your repo is public. Add `google-services.json` and `GoogleService-Info.plist` to `.gitignore`. `firebase_options.dart` only contains public SDK keys, but for safety you can also ignore it and have each person run `flutterfire configure` on their own machine.

---

## 5. Platform configuration

### Web

No additional configuration needed. Google login on web works via a popup managed directly by Firebase, with no extra packages. On web, by design, only the email/password form is shown (Google and Apple buttons are automatically hidden with `kIsWeb`).

To test locally:

```bash
flutter run -d chrome
```

---

### Android

#### 5.1 Change the Application ID

Open `android/app/build.gradle.kts` and replace `com.example.share_app` with your own identifier:

```kotlin
android {
    namespace = "com.yourdomain.shareapp"
    defaultConfig {
        applicationId = "com.yourdomain.shareapp"
        // ...
    }
}
```

#### 5.2 Register the SHA-1 fingerprint in Firebase

Google Sign-In on Android requires Firebase to know your keystore's fingerprint:

```bash
# Debug keystore (for development)
keytool -list -v \
  -keystore ~/.android/debug.keystore \
  -alias androiddebugkey \
  -storepass android \
  -keypass android
```

Copy the `SHA1` value and paste it in the Firebase Console:
**Project settings (⚙️) → your Android app → Add fingerprint**.

After adding it, download the updated `google-services.json` and replace the file at `android/app/google-services.json`.

#### 5.3 Add google_sign_in

Google login on mobile requires the `google_sign_in` package. Add it to `pubspec.yaml`:

```yaml
dependencies:
  google_sign_in: ^6.2.1
```

Then open `lib/remote-data-source/firebase/auth_remote_datasource.dart`, add the import:

```dart
import 'package:google_sign_in/google_sign_in.dart';
```

And replace the `if (!kIsWeb)` block inside `signInWithGoogle()` with the real implementation:

```dart
if (!kIsWeb) {
  final googleUser = await GoogleSignIn().signIn();
  if (googleUser == null) throw Exception('Cancelled by user');
  final googleAuth = await googleUser.authentication;
  final credential = fb.GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );
  final userCredential = await _firebaseAuth.signInWithCredential(credential);
  final user = userCredential.user;
  if (user == null) throw Exception('Could not retrieve user');
  return AppUser.fromFirebaseUser(user);
}
```

---

### iOS

#### 5.1 Change the Bundle ID

Open `ios/Runner.xcworkspace` in Xcode:
1. Select the **Runner** target in the left panel.
2. Under the **General** tab, change the **Bundle Identifier** from `com.example.shareApp` to your own identifier (e.g. `com.yourdomain.shareapp`).

It must match the Bundle ID you registered in the Firebase Console when adding the iOS app.

#### 5.2 Configure Google Sign-In on iOS

1. Download the `GoogleService-Info.plist` from the Firebase Console (**Project settings → your iOS app**) and replace `ios/Runner/GoogleService-Info.plist`.

2. Open the file and copy the `REVERSED_CLIENT_ID` value (it looks like `com.googleusercontent.apps.XXXXXX`).

3. In Xcode: **Runner → Info → URL Types → +** and paste the `REVERSED_CLIENT_ID` into the **URL Schemes** field.

4. Add `google_sign_in` to `pubspec.yaml` (same as in Android section 5.3) and apply the same implementation in `auth_remote_datasource.dart`.

#### 5.3 Configure Apple Sign-In on iOS

Apple Sign-In only works on Apple devices and requires an Apple Developer account ($99/year).

1. At [developer.apple.com](https://developer.apple.com): **Certificates, IDs & Profiles → Identifiers → your App ID** → enable **Sign In with Apple**.

2. In the Firebase Console: **Authentication → Sign-in method → Apple** → configure with your Service ID and the keys Apple provides.

3. In Xcode: **Runner → Signing & Capabilities → + Capability → Sign In with Apple**.

The code already handles the full Apple Sign-In flow with a secure nonce in `auth_remote_datasource.dart`.

#### 5.4 Install pods

```bash
cd ios
pod install
cd ..
```

---

## 6. Firestore security rules

Apply these rules in **Firebase Console → Firestore → Rules** so that only group members can access their data:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /groups/{groupId} {
      // Create group: the creator must include themselves in memberIds
      allow create: if request.auth != null
        && request.auth.uid in request.resource.data.memberIds;

      // Read and modify: current members only
      allow read, update: if request.auth != null
        && request.auth.uid in resource.data.memberIds;

      // Delete: creator only
      allow delete: if request.auth != null
        && request.auth.uid == resource.data.createdBy;

      // Subcollections (expenses, settlements): group members only
      match /{subcollection=**}/{docId} {
        allow read, write: if request.auth != null
          && request.auth.uid in get(
            /databases/$(database)/documents/groups/$(groupId)
          ).data.memberIds;
      }
    }
  }
}
```

Click **Publish** to activate them.

---

## 7. Run locally

```bash
# Web
flutter run -d chrome

# Android (with emulator or USB-connected device)
flutter run -d android

# iOS (Mac with Xcode configured only)
flutter run -d ios

# List all available devices
flutter devices
```

---

## 8. Deploy to web (Firebase Hosting)

### First time

```bash
firebase init hosting
```

Answer the wizard:
- **Public directory**: `build/web`
- **Single-page app (rewrite all URLs to /index.html)**: `Yes`
- **Overwrite build/web/index.html**: `No`

### Publish

```bash
flutter build web --release && firebase deploy --only hosting
```

Your app will be available at `https://YOUR-PROJECT.web.app`.

### Custom domain (optional, also free)

In Firebase Console → Hosting → **Add custom domain** and follow the steps to verify domain ownership and configure your DNS records.

---

## 9. Data model

Firestore collection structure:

```
groups/{groupId}
  ├── name: string
  ├── currency: string          ("EUR", "USD", …)
  ├── createdBy: string         (creator's uid)
  ├── createdAt: timestamp
  ├── memberIds: string[]       (array of uids — used in security rules)
  └── members: map[]
        ├── memberId: string
        ├── name: string
        ├── email: string
        ├── photoUrl: string
        ├── joinedAt: timestamp
        └── role: string        ("owner" | "member")

groups/{groupId}/expenses/{expenseId}
  ├── description: string
  ├── amount: number
  ├── currency: string
  ├── category: string
  ├── paidBy: string            (primary payer's uid)
  ├── payments: map[]           (multiple payers; empty if one person pays)
  │     ├── memberId: string
  │     ├── shareAmount: number
  │     └── shareType: string
  ├── date: timestamp
  ├── createdAt: timestamp
  ├── createdBy: string
  ├── notes: string
  └── splits: map[]             (how the expense is split among members)
        ├── memberId: string
        ├── shareAmount: number
        └── shareType: string   ("equal" | "exact" | "percentage")

groups/{groupId}/settlements/{settlementId}
  ├── fromMemberId: string      (who pays)
  ├── toMemberId: string        (who receives)
  ├── amount: number
  ├── currency: string
  ├── date: timestamp
  └── notes: string
```

---

## Features

- **Authentication**: email/password on all platforms; Google and Apple on mobile; email only on web.
- **Groups**: create, join by ID, invite members, edit name and currency, leave, delete.
- **Expenses**: add, edit, delete; equal or custom split per member; single or shared payment among multiple payers.
- **Balances**: automatic calculation of who owes whom, with debt simplification.
- **Settlements**: record payments between members to settle debts.
- **CSV**: import from Split-styler, export group expenses.
- **Statistics**: charts by category and by month.
- **Dark mode**: automatic based on the operating system.
- **Offline support**: Firestore persists data in local cache.

---

## License

MIT
