<div align="center">
  <img src="https://github.com/user-attachments/assets/fd58adc0-4f96-4e52-9d48-c995ebe80284" alt="BoardPAC logo" width="180" />

  # BoardPAC

  **Secure, efficient, and paperless board management**

  Manage meetings, agendas, board papers, approvals, and collaboration in one place.

  ![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
  ![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
  ![Riverpod](https://img.shields.io/badge/Riverpod-6B57FF?style=for-the-badge&logoColor=white)
</div>

---

## Overview

BoardPAC is a cross-platform Flutter application for board administration. It gives administrators, board secretaries, and board members role-based tools to organize meetings, review papers, manage approvals, and access organizational resources.
<img width="505" height="306" alt="Screenshot 2026-09-27 215222" src="https://github.com/user-attachments/assets/ca13f4bf-d84c-4939-9dff-9e0368b5790c" />
<img width="316" height="504" alt="Screenshot 2026-09-27 221735" src="https://github.com/user-attachments/assets/fccf16bf-7d2d-4e16-a044-90cc4c8ab5c0" />



## Features

| Area | Capabilities |
| --- | --- |
| Security and access | Secure login, two-factor authentication, role-based access, user and device management, privileges, and audit logs |
| Meetings | Meeting and participant management, agendas, agenda items, and reminders |
| Documents | Board papers, attachments, PDF viewing and annotations, offline paper storage, favorites, and a member document library |
| Collaboration | Comments, reactions, document sharing, and paper approval workflows |
| Organization | News, announcements, global search, and administrative reports |
| Experience | Light and dark themes, responsive layouts, and local notifications |

## Technology

- **Framework:** Flutter and Dart
- **State management:** Riverpod
- **API client:** Dio
- **Secure storage:** Flutter Secure Storage
- **PDF viewing:** Syncfusion PDF Viewer
- **Notifications:** Local notifications with timezone support

## Platforms

Android · iOS · Web · Windows · macOS · Linux

> Platform availability depends on the Flutter toolchain and configuration for each target.

## Getting started

### Prerequisites

- Flutter SDK with Dart 3.11.4 or later
- Android Studio or Visual Studio Code
- Android SDK for Android builds
- Xcode on macOS for iOS and macOS builds
- A running BoardPAC backend API

### Run locally

1. Verify your Flutter setup:

   ```bash
   flutter doctor
   ```

2. From the project directory, install dependencies:

   ```bash
   flutter pub get
   ```

3. Configure the backend API endpoint using the project's environment or configuration settings.

4. Start the app on an available device:

   ```bash
   flutter devices
   flutter run
   ```

For a web build, use `flutter run -d chrome` after enabling Flutter web support.

## User roles

- **Administrators:** Manage users, devices, privileges, reports, and audit records.
- **Board secretaries:** Organize meetings, agendas, participants, papers, and approvals.
- **Board members:** Review meeting materials, annotate PDFs, collaborate, and access their document library.

---

<div align="center">
  <sub>BoardPAC · Board management, made simpler.</sub>
</div>
