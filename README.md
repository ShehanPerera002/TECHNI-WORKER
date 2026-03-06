# TECHNI Worker Frontend

TECHNI Worker Frontend is a Flutter mobile application for skilled workers (plumbers, electricians, carpenters, painters, and others) to sign in with phone OTP, complete onboarding, upload profile/NIC files, and manage incoming work.

This repository is the frontend app only. It integrates with Firebase and a separate backend API service.

## Features

- Phone sign-in and OTP verification using Firebase Authentication
- Worker onboarding flow:
	- Welcome screen
	- Sign-in screen
	- OTP verification
	- Profile creation (name, age, NIC)
	- Category selection
- File uploads:
	- Profile image
	- NIC front and NIC back images
	- Certification document picker (UI flow)
- Worker home UI:
	- Weekly earnings card
	- New job requests tab
	- Scheduled jobs tab

## Tech Stack

Frontend:

- Flutter (Dart SDK `^3.10.4`)
- Firebase Core/Auth/Firestore/Storage/Messaging
- Dio for API communication
- `image_picker` and `file_picker` for media/document selection

Backend integration (separate repository/folder):

- Node.js + Express
- Firebase Admin SDK
- Multer (file upload middleware)
- Optional MongoDB connection support

## App Navigation Flow

Defined in `lib/app/routes.dart`:

- `/` -> Welcome
- `/signin` -> Worker sign-in
- `/otp` -> OTP verification
- `/verified` -> Verified screen
- `/profile` -> Create profile
- `/category` -> Select category
- `/home` -> Worker home

## Project Structure

```text
lib/
	app/
		routes.dart
		theme.dart
	core/
		assets.dart
	screens/
		welcome_screen.dart
		worker_signin_screen.dart
		otp_verification_screen.dart
		verified_screen.dart
		create_profile_screen.dart
		select_category_screen.dart
		worker_home_screen.dart
	services/
		auth_service.dart
		upload_service.dart
	widgets/
```

## Firebase Configuration (Frontend)

- Firebase app init is done in `lib/main.dart`.
- Platform options are in `lib/firebase_options.dart`.
- Android config file exists at `android/app/google-services.json`.

Current platform support in this repo:

- Configured: Android, Web, iOS, macOS
- Not configured: Windows, Linux (throws `UnsupportedError`)

If you need to regenerate Firebase config:

```bash
flutterfire configure
```

## Backend Integration

The app upload service (`lib/services/upload_service.dart`) calls worker endpoints under:

- Android emulator default: `http://10.0.2.2:5000/api/workers`
- Web/other platforms default: `http://localhost:5000/api/workers`

Override backend URL at runtime:

```bash
flutter run --dart-define=API_BASE_URL=https://your-domain.com/api/workers
```

Auth integration details:

- Frontend signs in via Firebase phone auth and obtains Firebase ID token.
- Token is sent as `Authorization: Bearer <token>` for protected backend routes.
- Backend verifies token using Firebase Admin middleware.

## Backend API Used By Frontend

Based on current routes in `TECHNI-WORKER_BACKEND-/src/routes/workerRoutes.js`:

- `POST /api/workers/profile` -> create worker profile
- `GET /api/workers/me` -> get current worker profile
- `PATCH /api/workers/nic-number` -> update NIC number
- `POST /api/workers/profile-image` -> upload profile image (`multipart/form-data`, field: `image`)
- `POST /api/workers/nic-image` -> upload NIC image (`multipart/form-data`, fields: `image`, `side`)
- `GET /api/health` -> server health check

Important note:

- Frontend has `uploadDocument()` in `UploadService` calling `POST /api/workers/document`.
- This route is not present in current backend routes, so certification upload is currently picker/UI only unless backend adds that endpoint.

## Running With Local Backend

If you run the backend locally from `TECHNI-WORKER_BACKEND-`:

1. Install dependencies:

```bash
npm install
```

2. Create `.env` and set required values.

Suggested backend environment variables (from backend code):

- `PORT=5000`
- `NODE_ENV=development`
- `ALLOWED_ORIGINS=*` or comma-separated origins
- `FIREBASE_STORAGE_BUCKET=project-techni.appspot.com`
- `FIREBASE_SERVICE_ACCOUNT_JSON={...}` or provide `src/config/serviceAccountKey.json`
- `ALLOW_DEV_AUTH_BYPASS=true` (dev-only option for API testing)
- `ENABLE_MONGODB=true` and `MONGODB_URI=...` (optional, if MongoDB needed)

3. Start backend server:

```bash
npm run dev
```

Server default base URL:

- `http://localhost:5000`

## Frontend Setup

1. Install Flutter dependencies:

```bash
flutter pub get
```

2. Run app:

```bash
flutter run
```

3. Optional custom backend URL:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000/api/workers
```

## Build Commands

Android APK:

```bash
flutter build apk --release
```

Web:

```bash
flutter build web --release
```

## Known Gaps

- Worker home data is still mock/sample UI data.
- Windows/Linux Firebase config is not yet generated.
- Certification upload API endpoint (`/document`) is not yet implemented on backend.

## Contributing

1. Create a branch from main.
2. Keep commits focused and descriptive.
3. For UI changes, include screenshots in PR.
4. For API changes, update this README endpoint section.

## Repository Scope

- This repo contains the Flutter frontend app.
- Backend service code lives in `TECHNI-WORKER_BACKEND-`.

## License

Private/internal by default (`publish_to: none` in `pubspec.yaml`).
