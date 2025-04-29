# Todo App

A modern, feature-rich Todo application built with Flutter and Firebase, supporting real-time updates, task sharing, and cross-platform functionality.

## Features

- **User Authentication**: Secure email/password authentication using Firebase Auth
- **Real-time Updates**: Instant task synchronization across devices using Firebase Realtime Database
- **Task Management**:
  - Create, read, update, and delete tasks
  - Mark tasks as complete/incomplete
  - Sort tasks by creation and modification time
- **Task Sharing**:
  - Share tasks with other users
  - Accept or reject shared tasks
  - View shared tasks in a separate section
- **Cross-Platform Support**:
  - Web
  - Android
  - iOS
  - macOS
  - Windows
  - Linux

## Technologies Used

- **Frontend**: Flutter with Material Design 3
- **Backend**: Firebase
  - Firebase Authentication
  - Firebase Realtime Database
  - Firebase Hosting
- **State Management**: Provider
- **Architecture**: MVVM (Model-View-ViewModel)

## Project Structure

```
lib/
├── models/       # Data models
├── services/     # Firebase and authentication services
├── viewmodels/   # Business logic and state management
├── views/        # UI screens
└── widgets/      # Reusable UI components
```

## Getting Started

### Prerequisites

- Flutter (latest version)
- Firebase account
- Git

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd todo_app
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure Firebase:
   - The project is already configured with Firebase
   - Uses the following services:
     - Firebase Auth for authentication
     - Realtime Database for data storage
     - Firebase Hosting for web deployment

4. Run the application:
   ```bash
   flutter run
   ```

## Features In Detail

### Authentication
- Email/password authentication
- Persistent login state
- Secure user session management

### Task Management
- Real-time task synchronization
- Task sharing capabilities
- Automatic sorting and organization

### User Interface
- Material Design 3 implementation
- Responsive layout
- Cross-platform consistent experience

## Deployment

The application is deployed on Firebase Hosting and can be accessed at:
https://todo-app-fresh.web.app

## Firebase Configuration

This app uses Firebase for authentication and data storage. To set up Firebase in your local environment:

1. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Enable Authentication and Realtime Database in your Firebase project
3. Copy `firebase_config.template.dart` to `lib/firebase_options.dart`
4. Fill in your Firebase configuration values in `firebase_options.dart`
5. Download and add platform-specific Firebase configuration files:
   - For Android: Download `google-services.json` and place it in `android/app/`
   - For iOS: Download `GoogleService-Info.plist` and place it in `ios/Runner/`
   - For Web: Configuration is handled in `firebase_options.dart`

> Note: The actual Firebase configuration files are not included in this repository for security reasons.

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Flutter Team for the amazing framework
- Firebase for the powerful backend services
- All contributors who have helped shape this project
