# MNIT Attendance - Native iOS Application (Swift & SwiftUI)

This is the native iOS counterpart to the MNIT Attendance Android application, built using **Swift 5.9+**, **SwiftUI**, **Core Location**, **AVFoundation**, and **iOS Keychain Services**. It directly integrates with the existing Laravel Sanctum backend API without modifying any backend code or the original Kotlin project.

---

## Project Structure

```
Attendance-iOS/
├── Attendance.xcodeproj/               # Xcode project file (open in Xcode)
│   └── project.pbxproj
├── Package.swift                       # Swift Package Manager manifest
├── Attendance/
│   ├── App/
│   │   ├── AttendanceApp.swift         # App entry point, routing & location init
│   │   └── AppConfig.swift             # Base URL, API constants, timeouts, thresholds
│   ├── Core/
│   │   ├── Camera/
│   │   │   └── CameraCaptureView.swift # AVFoundation front camera, preview & image downscaling
│   │   ├── Location/
│   │   │   └── LocationManager.swift   # CoreLocation GPS tracking, accuracy & anti-spoofing
│   │   ├── Network/
│   │   │   ├── APIClient.swift         # URLSession async client, auth interceptor, 401 handler
│   │   │   ├── APIEndpoints.swift      # 9 REST endpoint definitions with multipart & query params
│   │   │   ├── MultipartFormData.swift # RFC-compliant multipart form builder
│   │   │   └── NetworkMonitor.swift    # NWPathMonitor real-time online/offline reachability
│   │   └── Storage/
│   │       ├── DatabaseManager.swift   # Offline SQLite/JSON persistence for punches (Room equivalent)
│   │       ├── KeychainManager.swift   # Secure Keychain for auth_token and persistent device_uid
│   │       └── PreferencesManager.swift# Cached user profile, leave quotas, holidays
│   ├── Models/
│   │   ├── AttendancePunchRecord.swift # Local punch entity matching AttendancePunchEntity
│   │   ├── AuthModels.swift            # Login, register, profile requests & responses
│   │   ├── LeaveModels.swift           # Leave types, leave applications, leave balance data
│   │   ├── PunchModels.swift           # Server punches, holidays, sync results
│   │   ├── Resource.swift              # Generic async state wrapper (Loading, Success, Error)
│   │   └── User.swift                  # User profile model
│   ├── Repositories/
│   │   ├── AttendanceRepository.swift  # Offline punch recording, auto-sync, history caching
│   │   └── AuthRepository.swift        # Login, registration, profile fetch, logout
│   ├── ViewModels/
│   │   ├── HomeViewModel.swift         # Core dashboard, live timer, punch actions, leave sync
│   │   ├── LoginViewModel.swift        # Sign-in validation & state
│   │   ├── PendingViewModel.swift      # Account review status polling & logout
│   │   ├── SignupViewModel.swift       # Employee registration & validation
│   │   └── SplashViewModel.swift       # Session check & routing state
│   ├── Views/
│   │   ├── Auth/
│   │   │   ├── LoginScreen.swift       # Sign-in screen matching Android LoginScreen
│   │   │   └── SignupScreen.swift      # Registration form with date picker
│   │   ├── Home/
│   │   │   ├── Components/
│   │   │   │   ├── PunchRecordRow.swift   # Punch list item with selfie thumbnail & sync pill
│   │   │   │   └── SelfieCameraModal.swift# In-app front camera capture with face guide
│   │   │   ├── Tabs/
│   │   │   │   ├── HomeTabContent.swift   # Live clock, daily punch state machine, today list
│   │   │   │   ├── LeaveRequestTab.swift  # Quotas card, application form, my applications
│   │   │   │   ├── MonthlyCalendarTab.swift # Interactive monthly calendar, hours calculation
│   │   │   │   ├── ProfileTab.swift       # Employee details, hardware Device UID, logout
│   │   │   │   └── PunchesHistoryTab.swift# Complete historical device punch log
│   │   │   └── HomeScreen.swift        # Top bar, 5-tab bottom navigation bar, location alert
│   │   ├── Pending/
│   │   │   └── PendingApprovalScreen.swift # Pending approval holding screen with details
│   │   ├── Splash/
│   │   │   └── SplashScreen.swift      # Branding splash with loader
│   │   └── Theme/
│   │       ├── Colors.swift            # BrandIndigo, Emerald, Rose, Slate palette
│   │       └── Components/
│   │           └── CustomCard.swift    # Styled card container, PrimaryButton, StatusPill
│   ├── Info.plist                      # Camera, Location When In Use & Always, Background Modes
│   └── Assets.xcassets/                # App icon & logo assets
```

---

## How to Open and Run in Xcode

1. Open Xcode on macOS.
2. Select **File > Open...** and navigate to:
   `Attendance-App/Attendance-iOS/Attendance.xcodeproj`
   *(Alternatively, open `Attendance-App/Attendance-iOS/Package.swift`)*
3. Select your target:
   - For UI / workflow testing: Select any **iOS Simulator** (e.g. *iPhone 15 Pro*).
   - For real camera and GPS testing: Connect a **physical iPhone**.
4. Press **⌘R** (Run) to build and launch the application.

---

## Physical iPhone vs Simulator Testing

| Feature | Simulator Behavior | Physical iPhone Requirement |
| :--- | :--- | :--- |
| **Front Camera Capture** | Simulators do not have camera hardware. The app provides a smart fallback identity avatar with the employee's initials and timestamp for testing. | Required for live AVFoundation camera preview, orientation mirroring, and photo capture. |
| **GPS Location Fix** | Emits simulated location (Apple HQ / Custom). | Required for live GPS satellite lock and verifying horizontal accuracy (≤ 50m). |
| **Keychain Persistence** | Operates normally; cleared if simulator content is erased. | Required to test persistent `device_uid` retention across app reinstallation. |
| **Network Reachability** | Can be tested by disconnecting Mac Wi-Fi. | Required for real cellular/Wi-Fi handover and offline sync. |

