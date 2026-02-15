# 🎉 Ta-Daa - Week 6: Provider State Management

A professional Flutter Todo app with **Provider state management**, Firebase integration, real-time sync, push notifications, and beautiful UI/UX animations.

---

## 📱 Week 6 Features & Enhancements

### ✨ State Management
- ✅ **Provider Pattern** - Clean, scalable state management
- ✅ **AuthProvider** - Authentication state management
- ✅ **TaskProvider** - Task CRUD operations with real-time Firestore sync & optimistic UI updates
- ✅ **ThemeProvider** - Dark/Light mode management
- ✅ **Riverpod Example** - Advanced state management demo (`providers/riverpod_providers.dart`)

### 🔔 Push Notifications
- ✅ **Firebase Cloud Messaging (FCM)** - Receive push notifications (see `services/notification_service.dart`)

### 🎨 Redesigned UI & Animations
- ✅ **Sliding Login/Signup Panel** - Smooth animated transition
- ✅ **Main Screen with Filters** - All, Pending, Completed
- ✅ **Pin Important Tasks** - Keep priority tasks at the top
- ✅ **Dark/Light Theme Toggle** - Seamless theme switching
- ✅ **Enhanced Profile Screen** - Change password and username
- ✅ **Staggered List Animations** - Tasks animate in
- ✅ **OpenContainer Transitions** - Profile navigation
- ✅ **AnimatedSwitcher** - Auth/main screen transitions

### 🚀 Performance Optimizations
- ✅ Efficient state management with Provider & Riverpod
- ✅ Real-time Firestore streams with local cache
- ✅ Optimistic UI updates for instant feedback
- ✅ Selector widgets & caching to reduce rebuilds
- ✅ RepaintBoundary for rendering optimization
- ✅ Smooth 60fps animations

---

## 📂 Project Structure

```
lib/
├── main.dart                          # App entry with MultiProvider
├── firebase_options.dart              # Firebase configuration
│
├── models/
│   ├── app_user.dart                  # User profile model
│   └── todo_model.dart                # Task model with isPinned
│
├── providers/
│   ├── auth_provider.dart             # Authentication state
│   ├── task_provider.dart             # Task management state
│   ├── theme_provider.dart            # Theme state
│   └── riverpod_providers.dart        # Riverpod advanced state management (bonus)
│
├── screens/
│   ├── auth/
│   │   └── auth_screen.dart           # Sliding login/signup panel
│   ├── main/
│   │   └── main_screen.dart           # Main app screen with filters, stats, animations
│   └── profile/
│       └── profile_screen.dart        # Profile with settings
│
├── services/
│   ├── firebase_auth_service.dart     # Auth service
│   ├── firestore_service.dart         # Firestore operations
│   └── notification_service.dart      # FCM push notifications
│
└── widgets/
    ├── profile_tab.dart               # Profile UI
    └── tasks_tab.dart                 # Task list UI
```

---

## 🛠️ Tech Stack

### Core
- **Flutter SDK**: 3.38.5
- **Dart**: 3.0+

### State Management
- **Provider**: ^6.1.1
- **flutter_riverpod**: ^2.6.1 (bonus)

### Firebase
- **Firebase Core**: ^3.8.1
- **Firebase Auth**: ^5.3.3
- **Cloud Firestore**: ^5.5.2
- **Firebase Messaging**: ^15.1.6
- **Google Sign-In**: ^6.2.2

### Utilities
- **Shared Preferences**: ^2.3.3
- **Animations**: ^2.0.11
- **Intl**: ^0.19.0

---

## 🚀 Installation & Setup

### 1. Clone the Repository
```bash
git clone https://github.com/AlizayAhmed/Ta-Daa.git
cd Ta-Daa
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Firebase Setup
Follow the [Firebase Setup Guide](https://firebase.google.com/docs/flutter/setup) for your platform:

#### Android
1. Add `google-services.json` to `android/app/`
2. Update `android/build.gradle` and `android/app/build.gradle`

#### iOS
1. Add `GoogleService-Info.plist` to `ios/Runner/`
2. Update `ios/Runner/Info.plist`

#### Web
1. Initialize Firebase in `web/index.html`

### 4. Run the App
```bash
# For development (any port)
flutter run

# For web (port 8080 for Google Sign-In)
flutter run -d chrome --web-port=8080
```

---

## 🎯 Features Guide

### Authentication
1. **Email/Password Sign Up**
   - Enter name, email, and password
   - Form validation with helpful error messages
   - Automatic profile creation in Firestore

2. **Email/Password Login**
   - Enter credentials
   - Remember Me option for auto-login
   - Forgot password functionality

3. **Google Sign-In**
   - One-tap authentication
   - Automatic profile sync
   - Works on web (port 8080), Android, and iOS

### Task Management
1. **Create Tasks**
   - Tap the floating action button
   - Enter title (required) and description (optional)
   - Tasks save instantly to Firestore
   - **Optimistic UI**: Task appears instantly, even before Firestore confirms

2. **Complete Tasks**
   - Check/uncheck checkbox
   - Visual strikethrough for completed tasks
   - Real-time status update

3. **Pin Tasks**
   - Tap the pin icon
   - Pinned tasks appear at the top
   - Visual indicator for pinned status

4. **Delete Tasks**
   - Swipe left on any task
   - Confirmation dialog
   - Permanent deletion from Firestore
   - **Race condition safe**: Real-time stream and UI always in sync

5. **Filter Tasks**
   - **All** - View all tasks
   - **Pending** - View incomplete tasks only
   - **Completed** - View completed tasks only

### Theme Management
1. **Toggle Theme**
   - Tap the sun/moon icon in app bar
   - Smooth transition between light/dark
   - Preference saved locally

2. **Theme Persistence**
   - Your theme choice is saved
   - Auto-applies on app restart

### Profile Management
1. **View Profile**
   - See your name, email, and avatar
   - View task statistics
   - Access settings

2. **Change Username**
   - Tap edit icon next to name
   - Enter new name
   - Updates in Firestore

3. **Change Password**
   - Enter current password
   - Enter new password
   - Confirm new password
   - Secure re-authentication

4. **Logout**
   - Confirmation dialog
   - Clears local session
   - Returns to auth screen

### Push Notifications
1. **Receive Notifications**
   - FCM integrated for push notifications
   - Handles background and foreground messages
   - Topic subscription per user

### Advanced State Management (Bonus)
1. **Riverpod Example**
   - See `providers/riverpod_providers.dart` for advanced state management
   - Compare with Provider for learning

---

## 📊 State Management Architecture

### Provider & Riverpod Setup
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProxyProvider<AuthProvider, TaskProvider>(
      create: (_) => TaskProvider(),
      update: (_, auth, tasks) => tasks?..setUserId(auth.user?.uid),
    ),
    // Riverpod example: see providers/riverpod_providers.dart
  ],
  child: MyApp(),
)
```

### Provider Usage
```dart
// Read once
final authProvider = context.read<AuthProvider>();
await authProvider.signIn(email, password);

// Listen to changes
Consumer<TaskProvider>(
  builder: (context, taskProvider, child) {
    return ListView.builder(
      itemCount: taskProvider.tasks.length,
      itemBuilder: (context, index) => TaskItem(taskProvider.tasks[index]),
    );
  },
)

// Watch for changes
final tasks = context.watch<TaskProvider>().tasks;
```

---

## 🎨 UI/UX Features

- Modern, responsive design
- Staggered list animations
- OpenContainer transitions
- AnimatedSwitcher for auth/main
- Smooth theme switching
- Profile and settings dialogs

---

## 🔔 Push Notifications (FCM)
- Integrated with Firebase Messaging
- Handles background/foreground
- User topic subscription
- See `services/notification_service.dart`

---

## 🧪 Testing

### Manual Testing Checklist
- ✅ Sign up with email/password
- ✅ Login with email/password
- ✅ Login with Google
- ✅ Remember Me functionality
- ✅ Create task
- ✅ Complete/Incomplete task
- ✅ Pin/Unpin task
- ✅ Delete task
- ✅ Filter tasks (All/Pending/Completed)
- ✅ Toggle theme
- ✅ Change username
- ✅ Change password
- ✅ Logout
- ✅ Theme persists across sessions
- ✅ Tasks sync in real-time

### Performance Testing
- ✅ App loads in < 2 seconds
- ✅ Smooth scrolling at 60fps
- ✅ No memory leaks
- ✅ Optimized Firestore queries
- ✅ Efficient state updates

---

## 🚀 Future Enhancements

### Planned Features
- [ ] Task categories and tags
- [ ] Due dates and reminders
- [ ] Task search functionality
- [ ] Collaborative tasks
- [ ] Offline mode improvements
- [ ] Task export to CSV

### Advanced State Management
- [x] Riverpod example included
- [ ] Implement BLoC pattern
- [ ] Compare performance

---

## 📚 Learning Resources

### Provider
- [Provider Documentation](https://pub.dev/packages/provider)
- [Flutter State Management](https://docs.flutter.dev/development/data-and-backend/state-mgmt/simple)

### Firebase
- [FlutterFire](https://firebase.flutter.dev/)
- [Firestore Best Practices](https://firebase.google.com/docs/firestore/best-practices)

### Flutter
- [Flutter Documentation](https://docs.flutter.dev/)
- [Material Design 3](https://m3.material.io/)

---

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

---

## 📄 License

This project is for educational purposes as part of a Flutter internship program.

---

## 📞 Support

For issues or questions:
1. Check the troubleshooting section
2. Review the documentation
3. Open a GitHub issue

---

## 🎓 Academic Integrity

This project is completed as part of Week 6 requirements:
- ✅ Provider state management implemented
- ✅ Enhanced UI with animations
- ✅ Performance optimizations
- ✅ Real-time sync & optimistic updates
- ✅ Push notifications (FCM)
- ✅ Riverpod example (bonus)
- ✅ Comprehensive documentation
- ✅ Video walkthrough created

---

**Built with ❤️ using Flutter, Provider, Riverpod, and Firebase**

---

**Version**: 2.0.0
**Last Updated**: February 2026
**Flutter Version**: 3.38.5
**Provider Version**: 6.1.1