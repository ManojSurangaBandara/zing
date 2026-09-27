# zing.lk - Sri Lankan Dating App 🇱🇰 ❤️

A simple, genuine, and secure Android dating application built with Flutter and Firebase.

Designed specifically for Sri Lanka with manual Super Admin verification (Selfie & both sides of National Identity Card - NIC) to eliminate fake profiles, district & town filters, radius distance discovery, and in-app chat.

---

## 🌟 Key Features

### 1. Manual Super Admin Verification System
- **Registration requirements**:
  - Email & Password
  - Full Name, Age, Gender, Looking For (Preference)
  - District & Town / City
  - Introduction / Bio & Dating Interests
  - **Live Selfie Photo**
  - **Sri Lankan NIC (Front Side)**
  - **Sri Lankan NIC (Back Side)**
- **Verification Workflow**:
  - Profile is created in `pending` status.
  - User cannot interact until approved.
  - Dedicated **Super Admin Portal** to inspect selfie, NIC front, and NIC back in high-res zoom.
  - **One-click Approve**: Enables account, notifies user via app notification.
  - **Reject with Reason**: Super Admin enters specific feedback (e.g., *"NIC front is blurry"*, *"Selfie does not match NIC"*). User is notified with the exact reason and can re-upload right from the status screen.

### 2. Search & Discovery with Geo Radius & Filters
- **Filter by 25 Sri Lankan Districts**: Colombo, Kandy, Galle, Gampaha, Kurunegala, Jaffna, etc.
- **Filter by Town / City**: Search specific neighborhoods (e.g. Kollupitiya, Peradeniya, Galle Fort).
- **Distance Radius Filter**: Slider from 5 km to 150 km calculated using GPS coordinates (Haversine formula).
- **Preference & Gender Filters**: Filter Men, Women, or Everyone.
- **Interactive Profile Cards**: Photo count badge, verified NIC badge, distance tag, quick connect button.

### 3. Connect Requests & Real-time In-App Messaging
- Send Connect Requests with optional personalized greeting.
- Incoming requests tab: **Accept** or **Decline**.
- When accepted: A mutual match is formed, both users receive notification, and 1-on-1 private messaging unlocks!
- Real-time chat with message bubbles, timestamps, and read receipts.

### 4. Profile Management & 10 Compressed Photos
- Upload **up to 10 photos**.
- **Automatic Client-Side Image Compression** (`flutter_image_compress`):
  - Photos are compressed before uploading to Firebase Storage/Firestore.
  - Reduces data usage by ~75-80% while retaining sharp clarity.
- Manage Bio, Preferences, Interests tags, Height, Occupation, Education, and Relationship Goals.

---

## 👑 Super Admin Account (Firebase Seeded)

All demo/sample accounts have been removed. The application only contains the **Super Admin** account, which is automatically verified and created in **Firebase Auth** and **Cloud Firestore** upon launch:

| Role | Email | Default Password | Features & Permissions |
| :--- | :--- | :--- | :--- |
| **Super Admin** | `admin@zing.lk` | `Admin@Zing2026!` *(or `admin123`)* | Access to Super Admin Review Portal, inspect Selfie & NIC front/back of newly registered real users, one-click verification approval, or rejection with reason. |

All other profiles in the app are **real user registrations**:
- Users register via the Registration screen by uploading their Selfie, NIC Front, and NIC Back.
- New registrations are saved to Firebase in `pending` status.
- The Super Admin reviews and activates them from the Admin Portal.

---

## 🔌 Connecting Your Real Firebase Project

The app is engineered with a unified `BackendService`:
- If `google-services.json` is present and Firebase is initialized, it connects to **Firebase Auth**, **Cloud Firestore**, and **Firebase Storage**.
- If running without Firebase credentials, it automatically falls back to the in-memory engine so development and testing never stall!

### Steps to connect real Firebase:
1. Go to [Firebase Console](https://console.firebase.google.com/) and create a project named `zing-lk`.
2. Add an Android app with package name `com.example.zing`.
3. Download `google-services.json` and place it in:
   ```
   android/app/google-services.json
   ```
4. In Firebase Console:
   - Enable **Authentication** (Email/Password provider).
   - Enable **Cloud Firestore** in production or test mode.
   - Enable **Firebase Storage**.
5. Run the app:
   ```bash
   flutter run
   ```

---

## 📱 Architecture & Folder Structure

```
lib/
├── constants/
│   ├── app_theme.dart          # Romantic coral & rose palette with clean Material 3 design
│   └── sri_lanka_data.dart     # 25 Sri Lanka districts, coordinates, towns, and dating interests
├── models/
│   ├── user_model.dart         # User profile with NIC & Selfie verification fields
│   ├── connect_request_model.dart # Sent and received connection requests
│   ├── message_model.dart      # Chat messages and match records
│   └── notification_model.dart # In-app alerts (verification status, requests, messages)
├── services/
│   ├── backend_service.dart    # Unified Firebase & reactive persistence repository
│   ├── image_compression_service.dart # Compresses images before Firebase upload
│   ├── location_service.dart   # GPS coordinates and distance radius calculation
│   └── mock_data.dart          # Preloaded Sri Lankan profiles and pending submissions
└── screens/
    ├── admin/
    │   └── super_admin_screen.dart # Admin review dashboard for Selfie & NIC approval/rejection
    ├── auth/
    │   ├── welcome_screen.dart # Onboarding & quick demo buttons
    │   ├── login_screen.dart   # Email/password authentication & autofill helpers
    │   ├── register_screen.dart# 3-step registration with Selfie, NIC Front & NIC Back upload
    │   └── verification_status_screen.dart # Status tracking & re-submission for users
    ├── chat/
    │   ├── matches_and_chat_screen.dart # Active matches and chat conversations
    │   └── chat_detail_screen.dart      # Real-time messaging screen
    ├── discover/
    │   ├── discover_screen.dart        # Feed with district, town, and radius filters
    │   └── profile_detail_screen.dart  # 10-photo carousel, bio, details, connect button
    ├── profile/
    │   └── my_profile_screen.dart      # 10-photo manager, compression, details editor
    └── home_shell.dart         # Bottom navigation & notification center
```
