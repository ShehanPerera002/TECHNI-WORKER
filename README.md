# TECHNI Worker Frontend

Flutter application for the worker-side experience in TECHNI (phone OTP login, onboarding, profile setup, uploads, and job management UI).

This folder (`TECHNI-WORKER`) contains only the frontend app. Backend APIs are in the sibling folder `TECHNI-WORKER_BACKEND-`.

## Features

- Firebase phone authentication (OTP send/verify/resend)
- Worker onboarding flow:
	- Welcome
	- Sign in
	- OTP verification
	- Verified screen
	- Create profile
	- Category selection
- Worker home experience:
	- Weekly earnings card
	- New job requests and scheduled jobs tabs
	- Accept/decline actions
	- Pull-to-refresh
	- Job details and earnings details screens
- File selection/upload support:
	- Profile image upload
	- NIC image upload (front/back)
	- Document picker flow

## Tech Stack

- Flutter (Dart SDK `^3.10.4`)
- Firebase:
	- `firebase_core`
	- `firebase_auth`
	- `cloud_firestore`
	- `firebase_storage`
	- `firebase_messaging`
- Networking: `dio`
- Media and docs: `image_picker`, `file_picker`

## App Routes

Defined in `lib/app/routes.dart`:

- `/` -> `WelcomeScreen`
- `/signin` -> `WorkerSignInScreen`
- `/otp` -> `OtpVerificationScreen`
- `/verified` -> `VerifiedScreen`
- `/profile` -> `CreateProfileScreen`
- `/category` -> `SelectCategoryScreen`
- `/terms` -> `TermsScreen`
- `/privacy` -> `PrivacyScreen`
- `/home` -> `WorkerHomeScreen`

## Project Structure

```text
lib/
	app/
		routes.dart
		techni_worker_app.dart
		theme.dart
	core/
		assets.dart
	models/
		job_model.dart
	services/
		auth_service.dart
		job_service.dart
		upload_service.dart
		screens/
			create_profile_screen.dart
			earnings_details_screen.dart
			job_details_screen.dart
			otp_verification_screen.dart
			privacy_screen.dart
			select_category_screen.dart
			terms_screen.dart
			verified_screen.dart
			welcome_screen.dart
			worker_home_screen.dart
			worker_signin_screen.dart
	widgets/
		app_header.dart
		input_field.dart
		primary_button.dart
	firebase_options.dart
	main.dart
```

## Prerequisites

- Flutter SDK installed
- Dart SDK compatible with `^3.10.4`
- Android Studio/Xcode (depending on target platform)
- Firebase project configured for this app

## Frontend Setup

1. Install dependencies:

```bash
flutter pub get
```

2. Run the app:

```bash
flutter run
```

3. Run with custom backend base URL (optional):

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000/api/workers
```

## Backend Integration

`lib/services/upload_service.dart` uses this default logic:

- Android emulator: `http://10.0.2.2:5000/api/workers`
- Web/other: `http://localhost:5000/api/workers`

Use `API_BASE_URL` to override in any environment.

### Authentication Flow

- Frontend signs in with Firebase Phone Auth.
- Firebase ID token is attached to protected API requests:
	- `Authorization: Bearer <firebase_id_token>`
- Backend validates token using Firebase Admin middleware.

### Backend Endpoints Used

Based on `TECHNI-WORKER_BACKEND-/src/routes/workerRoutes.js`:

- `POST /api/workers/profile`
- `GET /api/workers/me`
- `PATCH /api/workers/nic-number`
- `POST /api/workers/profile-image` (`multipart/form-data`, field: `image`)
- `POST /api/workers/nic-image` (`multipart/form-data`, fields: `image`, `side`)

Note:

- Frontend currently has `uploadDocument()` calling `POST /api/workers/document`.
- That route is not available in current backend routes, so document upload needs backend support to be fully functional.

## Firebase Configuration

- Firebase is initialized in `lib/main.dart`.
- Platform config lives in `lib/firebase_options.dart`.
- Android config file: `android/app/google-services.json`.

If Firebase settings change, regenerate config with FlutterFire CLI:

```bash
flutterfire configure
```

## Build Commands

- Android APK:

```bash
flutter build apk --release
```

- Web build:

```bash
flutter build web --release
```

## Current Limitations

- `JobService` currently uses in-memory sample data (not backend-synced yet).
- Document upload API route (`/api/workers/document`) is missing in backend.

## Related Repositories/Folders

- Frontend: `TECHNI-WORKER`
- Backend: `TECHNI-WORKER_BACKEND-`

## License

Private/internal project (`publish_to: none`).
