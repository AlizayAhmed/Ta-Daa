# 🔐 Flutter Login & Signup App

A modern, dark-themed authentication application built with Flutter featuring smooth animations, form validation, and a beautiful user interface.

## 📱 About

This is a Flutter mobile application developed as part of **Week 1** of the Flutter Development Internship. It demonstrates fundamental Flutter concepts including UI building, navigation, form validation, and state management.

## ✨ Features

- 🌙 **Dark Mode UI** - Beautiful gradient backgrounds with modern dark theme
- 🎨 **Smooth Animations** - Fade-in transitions and scale animations for enhanced UX
- 🔄 **Dynamic Login/Signup Toggle** - Seamlessly switch between login and signup modes
- ✅ **Form Validation** - Email format validation and password strength checking
- 👁️ **Password Visibility Toggle** - Show/hide password functionality
- 🎯 **Navigation** - Proper navigation flow from login to home screen
- 💳 **Rounded Cards** - Modern card-based layout with rounded corners
- 🎭 **Gradient Accents** - Purple-blue gradient buttons and icons
- 📝 **Forgot Password** - Forgot password option (UI ready)
- ⚡ **Responsive Design** - Adapts to different screen sizes

## 🛠️ Technologies Used

- **Flutter SDK** - UI framework
- **Dart** - Programming language
- **Material Design** - Design system
- **Form Validation** - Built-in Flutter validators

## 📋 Prerequisites

Before running this project, make sure you have:

- Flutter SDK installed (version 3.0.0 or higher)
- Dart SDK (comes with Flutter)
- Android Studio / VS Code with Flutter extensions
- An emulator or physical device for testing

## 🚀 Getting Started

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/flutter-login-app.git
   cd flutter-login-app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Running on Different Platforms

**Chrome (Web):**
```bash
flutter run -d chrome
```

**Android Emulator:**
```bash
flutter run -d android
```

**iOS Simulator (Mac only):**
```bash
flutter run -d ios
```

**Windows:**
```bash
flutter run -d windows
```

## 📂 Project Structure

```
login_app/
├── android/              # Android-specific files
├── ios/                  # iOS-specific files
├── lib/
│   └── main.dart        # Main application file with all code
├── test/                 # Unit tests
├── pubspec.yaml         # Dependencies and project configuration
└── README.md            # This file
```

## 🎯 Features Implemented (Week 1)

- ✅ Basic Flutter project setup
- ✅ Login screen UI with email and password fields
- ✅ Signup screen with additional fields
- ✅ Email validation (proper email format)
- ✅ Password validation (minimum 6 characters)
- ✅ Password confirmation matching
- ✅ Navigation from login to home screen
- ✅ Form validation with error messages
- ✅ Modern UI with animations
- ✅ Dark theme implementation

## 🔐 Form Validation Rules

| Field | Validation Rule |
|-------|----------------|
| Email | Must be valid email format (e.g., user@example.com) |
| Password | Minimum 6 characters required |
| Confirm Password | Must match the password field |
| Full Name | Required for signup (cannot be empty) |

## 🎨 Color Scheme

- **Background Gradient:** Dark blue to purple (`#0A0E21` → `#1D1E33`)
- **Card Background:** Dark navy (`#1D1E33`)
- **Input Fields:** Darker shade (`#111328`)
- **Accent Colors:** Purple-blue gradient (`purpleAccent` → `blueAccent`)
- **Text:** White with varying opacity for hierarchy

## 🎬 Animations

- **Fade-in Animation:** Entire form fades in on screen load (500ms)
- **Scale Animation:** Logo scales from 0 to 1 on load (800ms)
- **Toggle Animation:** Smooth transition when switching between login/signup
- **Hover Effects:** Button and input field interactions

## 📱 How to Use

1. **Login Mode:**
   - Enter your email address
   - Enter your password (minimum 6 characters)
   - Click "Sign In" to navigate to home screen
   - Click "Forgot Password?" for password recovery (UI only)

2. **Signup Mode:**
   - Click "Sign Up" at the bottom
   - Enter your full name
   - Enter a valid email address
   - Create a password (minimum 6 characters)
   - Confirm your password
   - Click "Sign Up" to create account

## 📖 Learning Outcomes

Through this project, I learned:

- Flutter widget tree and composition
- State management using `setState`
- Form validation techniques
- Navigation between screens using `Navigator`
- Animation controllers and Tween animations
- Material Design principles
- Gradient styling and theming
- Responsive UI design

## 📝 Code Highlights

**Custom Text Field with Validation:**
```dart
_buildTextField(
  controller: _emailController,
  label: 'Email',
  icon: Icons.email_outlined,
  validator: (value) {
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  },
)
```

**Gradient Button:**
```dart
decoration: BoxDecoration(
  gradient: LinearGradient(
    colors: [
      Colors.purpleAccent.withOpacity(0.8),
      Colors.blueAccent.withOpacity(0.8),
    ],
  ),
  borderRadius: BorderRadius.circular(15),
)
```





