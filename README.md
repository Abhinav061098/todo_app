# Todo App

A modern, collaborative Todo application built with Flutter and Firebase, demonstrating real-time updates and cross-platform capabilities.

## 🚀 Live Demo
Visit: [https://todo-app-fresh.web.app](https://todo-app-fresh.web.app)

NOTE: **mostly tested on Android

**Demo Credentials**:
- Email: demo@example.com
- Password: [Available upon request]

## ✨ Key Features

- **Authentication & Security**
  - Secure email/password login
  - Persistent sessions
  - Protected data access

- **Real-time Collaboration**
  - Instant task synchronization
  - Task sharing via deep links
  - Multi-user support

- **Modern UI/UX**
  - Material Design 3
  - Responsive layout
  - Dark/Light theme
  - Cross-platform consistency

## 🛠️ Tech Stack

- **Frontend**: Flutter 3.x
- **Backend**: Firebase
- **Architecture**: MVVM
- **State Management**: Provider
- **Database**: Firebase Realtime DB
- **Authentication**: Firebase Auth
- **Hosting**: Firebase Hosting

## 📱 Supported Platforms
- Web (Progressive Web App)
- Android
- iOS
- Windows
- macOS

## 🔧 Setup for Review

### Prerequisites
1. Install [Flutter](https://flutter.dev/docs/get-started/install)
2. Install [Node.js](https://nodejs.org/)
3. Have a Google account for Firebase

### Quick Start
```bash
# Clone repository
git clone https://github.com/YourUsername/todo_app.git
cd todo_app

# Install dependencies
flutter pub get

# Setup Firebase
dart pub global activate flutterfire_cli
flutterfire configure

# Run the app
flutter run -d chrome  # For web
flutter run -d windows # For Windows
```

## 📁 Project Structure
```
lib/
├── models/       # Data models
├── services/     # Firebase services
├── viewmodels/   # Business logic (MVVM)
├── views/        # UI screens
└── widgets/      # Reusable components
```

## 🎯 Implementation Highlights

- **Clean Architecture**
  - MVVM pattern
  - Separation of concerns
  - Dependency injection

- **Firebase Integration**
  - Real-time data sync
  - Secure authentication
  - Cloud hosting

- **State Management**
  - Provider for state
  - Real-time updates
  - Efficient rebuilds

## 📫 Contact

For questions about the code or setup:
- Email: [Your Email]
- LinkedIn: [Your LinkedIn]
- GitHub: [Your GitHub]

## 📝 License

MIT License - See [LICENSE](LICENSE) for details
