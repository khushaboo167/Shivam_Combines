# Shivam Combines — Demo-ready Flutter + Firebase project

This package is prepared so the app can be demonstrated **without a Firebase project**. It defaults to an in-memory DEMO MODE, while retaining the Firebase backend for the real deployment.

## 1. Demo run — no Firebase account required

Prerequisite: install Flutter and have `flutter` available in PATH.

### Windows
Double-click `run_demo.bat`.

### macOS/Linux
Run `./run_demo.sh`.

The script creates the missing Android/Web platform folders, gets packages, and launches with `DEMO_MODE=true`.

### Demo accounts
- Service customer: `customer@demo.com` / `Demo1234`
- Service admin: `admin@demo.com` / `Demo1234`
- Power Monitor: `power@demo.com` / `Demo1234`

### Demo flow to verify
1. Service → log in as customer → New complaint → submit.
2. Log out → Service → log in as admin → open the complaint → change status.
3. Power Monitor → log in → see the sample live meter.
4. Tap `+` → pair a demo meter → verify Device ID + API key screen.

## 2. Real Firebase setup

You said you currently have no Firebase files. That is okay; do **not** invent `google-services.json` or a service-account key.

1. Create a Firebase project.
2. Enable Email/Password Authentication and Firestore.
3. Run `firebase login` and `firebase init` from this project if needed.
4. From `app/`, run `flutterfire configure` to generate `lib/firebase_options.dart` and register the Android app.
5. Put the generated Android `google-services.json` in `app/android/app/`.
6. Set `DEMO_MODE=false` (or remove the define; the source default is demo mode until Firebase is configured).
7. Install backend dependencies: `cd backend-functions && npm install`.
8. Deploy: `firebase deploy --only functions,firestore`.
9. Pair a real meter from the app, then put the returned Device ID/API key and the deployed `ingest` URL into the ESP32 sketch.

## Security changes made
- Client signup can no longer create or change an admin account.
- Firestore rules prevent client-side admin self-promotion.
- Admins must be provisioned server-side/through a controlled Firebase process.
- Firebase credentials are excluded by `.gitignore`.

## ESP32
`esp32_meter_firebase.ino` is retained for the real RS-485/Modbus path. The meter register map and Modbus word order must be verified against the actual meter before field deployment.

## Important
The demo mode is a local UI/functionality test; it does **not** prove that Firebase, Cloud Functions, the real RS-485 meter, or an Android production build are connected until those external pieces are configured.
