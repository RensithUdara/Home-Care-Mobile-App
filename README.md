# 🏠 Home Care App

A comprehensive Flutter mobile application for managing home appliances and services with Firebase backend integration.

## 📱 About

Home Care App is a modern Flutter application designed to help users manage their home appliances, schedule maintenance, and track service records. The app features a completely redesigned modern UI with enhanced animations, comprehensive error handling, and cloud-based data storage.

## ✨ Latest Features & Updates

### 🔐 Enhanced Authentication System
- **Advanced User Registration & Login** with comprehensive error handling
- **Email/Password Authentication** via Firebase Auth with custom error messages
- **Password Visibility Toggle** with animated eye icon
- **Forgot Password Functionality** - Fully implemented with email reset
- **Real-time Form Validation** with immediate feedback
- **Password Strength Indicator** with visual progress bar
- **Loading States** with smooth animations during authentication
- **Enhanced Error Messages** - User-friendly error descriptions
- **Social Login UI** (Apple & Google - Ready for implementation)
- **Haptic Feedback** for better user interaction

### 🏠 Redesigned Home Management
- **Modern Dashboard** with greeting based on time of day
- **Statistics Cards** showing total items, categories, and active appliances
- **Advanced Search & Filter** - Real-time search with category filtering
- **Smart Product Discovery** - Search by name or location
- **Warranty Status Tracking** - Visual indicators for expiring/expired warranties
- **Interactive Category Pills** with smooth animations
- **Enhanced Product Cards** with status badges and modern design

### 📱 Modern User Interface
- **Complete UI Redesign** with Material Design 3 principles
- **Gradient Backgrounds** and enhanced visual depth
- **Smooth Animations** with fade-in effects and scale transitions
- **Hero Animations** for seamless navigation
- **Haptic Feedback** throughout the app
- **Enhanced Shadows** and modern card designs
- **Custom Floating Action Button** spanning full width
- **Empty State Designs** with engaging call-to-action
- **Light & Dark Theme** support with improved color schemes
- **Responsive Design** optimized for all screen sizes

### 🎯 Smart Appliance Management
- **Warranty Monitoring** - Smart alerts for expiring warranties
- **Status Indicators** - Active, Expiring, and Expired badges
- **Product Categories** - Television, Refrigerator, AC, Washing Machine, Laptop, Speaker, Vacuum Cleaner, Fan, and more
- **Location Tracking** - Organize appliances by room/location
- **Interactive Product Cards** with tap animations
- **Quick Actions** - Easy access to product details and editing

### 🔧 Service Management
- **Service Records** - Track maintenance and repairs
- **Direct Calling** - Contact service providers directly
- **Service History** - Complete maintenance timeline
- **Warranty Tracking** - Monitor warranty periods with visual indicators

### ☁️ Cloud Integration
- **Firebase Firestore** - Real-time database with offline support
- **Enhanced Error Handling** - Network error detection and user feedback
- **Data Synchronization** - Seamless cloud backup and restore
- **Secure Authentication** - Firebase Auth with comprehensive error handling

## 🛠️ Tech Stack

- **Framework:** Flutter 3.2.3+
- **Language:** Dart
- **Backend:** Firebase
  - Firebase Core 3.0.0
  - Firebase Auth 5.0.0 (Enhanced error handling)
  - Cloud Firestore 5.0.0
- **State Management:** Provider 6.1.2
- **UI/UX:** 
  - Google Fonts 6.1.0
  - Material Design 3
  - Custom gradients and shadows
- **Other Dependencies:**
  - URL Launcher 6.0.20
  - Flutter Phone Direct Caller 2.1.1
  - Device Preview 1.1.0
  - Intl 0.19.0

## 📁 Project Structure

```
lib/
├── components/              # Reusable UI components
│   ├── add_product.dart        # Enhanced product addition form
│   ├── app_icon.dart           # Application logo component
│   ├── bottom_add_bar.dart     # Bottom action bar
│   ├── call_button.dart        # Direct calling functionality
│   ├── edit_product_bottom_sheet.dart  # Product editing interface
│   ├── enhanced_item_tile.dart # Modern product card with animations
│   ├── item_tile.dart          # Original product card component
│   ├── main_button.dart        # Enhanced button with gradient design
│   ├── search_bar.dart         # Search functionality component
│   └── text_input_field.dart   # Enhanced input field with eye icon
├── models/                  # Data models
│   └── products.dart           # Product data structure
├── screens/                 # App screens
│   ├── home.dart               # Redesigned modern home dashboard
│   ├── home_original.dart      # Original home screen (backup)
│   ├── login.dart              # Enhanced login with error handling
│   ├── product.dart            # Product details screen
│   ├── profile.dart            # User profile management
│   └── register.dart           # Enhanced signup with password strength
├── services/               # Business logic
│   ├── auth/              # Authentication services
│   │   ├── auth_check.dart     # Authentication state management
│   │   ├── authentication.dart # Enhanced Firebase auth with error handling
│   │   └── login_or_register.dart # Auth flow management
│   └── firestore/         # Database services
│       └── firestore_services.dart # Cloud database operations
├── themes/                # App theming
│   ├── dark_mode.dart         # Enhanced dark theme
│   ├── light_mode.dart        # Enhanced light theme
│   └── theme_provider.dart    # Theme state management
├── utils/                 # Utility functions
│   └── product_utils.dart     # Product helper functions
├── firebase_options.dart   # Firebase configuration
└── main.dart              # App entry point
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>= 3.2.3)
- Dart SDK (>= 3.2.3)
- Android Studio / VS Code
- Firebase project setup
- Android/iOS development environment

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/RensithUdara/Home-Care-Mobile-App.git
   cd Home-Care-Mobile-App
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a new Firebase project
   - Enable Authentication (Email/Password)
   - Enable Password Reset functionality
   - Create Firestore database
   - Download and add configuration files:
     - `android/app/google-services.json`
     - `ios/Runner/GoogleService-Info.plist`
     - `lib/firebase_options.dart`

4. **Run the app**
   ```bash
   flutter run
   ```

### Firebase Configuration

1. **Authentication**
   - Go to Firebase Console > Authentication > Sign-in method
   - Enable Email/Password authentication
   - (Optional) Enable Google and Apple sign-in

2. **Firestore Database**
   - Create a Firestore database in test mode
   - Set up security rules as needed

3. **Storage (Optional)**
   - Enable Firebase Storage for image uploads

## 📸 Screenshots & UI Showcase

### 🔐 Enhanced Authentication Screens
- **Login Screen**: 
  - Modern gradient background with time-based greetings
  - Enhanced input fields with shadows and rounded corners
  - Password visibility toggle with animated eye icon
  - Comprehensive error handling with user-friendly messages
  - Loading states with smooth animations
  - Forgot password functionality fully integrated
  - Social login buttons (Apple & Google) ready for implementation

- **Register Screen**: 
  - Multi-step validation with real-time feedback
  - Password strength indicator with visual progress bar
  - Password requirements checklist with dynamic validation
  - Enhanced error messages and success notifications
  - Smooth animations and haptic feedback

### 🏠 Redesigned Main App Screens
- **Modern Home Dashboard**: 
  - Dynamic greeting based on time of day with emojis
  - Statistics cards showing appliance counts and categories
  - Advanced search with real-time filtering
  - Interactive category pills with smooth animations
  - Enhanced product cards with warranty status badges
  - Hero animations for seamless navigation
  - Custom floating action button spanning full width

- **Enhanced Product Management**: 
  - Smart warranty tracking with visual indicators
  - Status badges (Active, Expiring, Expired)
  - Modern card designs with gradient backgrounds
  - Interactive animations and haptic feedback
  - Improved product details with better organization

- **Profile Management**: 
  - Enhanced user settings interface
  - Theme toggle with smooth transitions
  - Better navigation and user experience

## 🎨 Advanced UI/UX Features

### 🎭 Modern Design System
- **Material Design 3** principles throughout the app
- **Gradient Backgrounds** with subtle depth effects
- **Enhanced Shadows** with proper layering and blur radius
- **Rounded Corners** (12-20px radius) for modern appearance
- **Color-coded Categories** for quick appliance identification
- **Smart Status Indicators** for warranty and maintenance tracking

### ⚡ Interactive Elements
- **Haptic Feedback** for all user interactions
- **Scale Animations** on tap for better feedback
- **Hero Animations** for smooth screen transitions
- **Fade-in Effects** for content loading
- **Smooth Scrolling** with custom physics
- **Interactive Cards** with press animations
- **Loading States** with elegant progress indicators

### 📱 Enhanced User Experience
- **Time-based Greetings** with appropriate emojis
- **Smart Search** with category filtering
- **Real-time Validation** with immediate feedback
- **Empty State Designs** with engaging call-to-action
- **Error Handling** with user-friendly messages
- **Network Status** awareness with appropriate feedback
- **Warranty Monitoring** with proactive notifications

### 🎯 Accessibility & Responsiveness
- **Adaptive Layouts** for different screen sizes
- **Touch-friendly Button Sizes** (minimum 48px)
- **Proper Color Contrast** for readability
- **Semantic Labels** for screen readers
- **Keyboard Navigation** support
- **High-resolution Asset** support

## 🔧 Configuration

### Environment Variables

Create a `.env` file (optional) for additional configuration:
```
APP_NAME=Home Care App
VERSION=1.0.0
ENVIRONMENT=development
```

### Theme Customization

The app supports advanced theming through `theme_provider.dart`. You can modify:
- **Light Mode Colors** in `themes/light_mode.dart`
- **Dark Mode Colors** in `themes/dark_mode.dart`
- **Component Styles** throughout the app
- **Animation Durations** and curves
- **Shadow Effects** and elevations

## 🧪 Testing

Run tests with:
```bash
flutter test
```

For integration testing:
```bash
flutter drive --target=test_driver/app.dart
```

## 📱 Build & Deployment

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Code Style
- Follow Flutter/Dart conventions
- Use meaningful variable and function names
- Add comments for complex logic
- Ensure proper error handling

## 🐛 Known Issues

- Social login implementation pending
- Forgot password functionality needs backend integration
- Some minor linting warnings (non-critical)

## 📋 Roadmap

- [ ] Implement Apple and Google sign-in
- [ ] Add push notifications for service reminders
- [ ] Implement image upload for appliances
- [ ] Add service provider ratings and reviews
- [ ] Create service booking system
- [ ] Add expense tracking for repairs
- [ ] Implement QR code scanning for appliances
- [ ] Add multi-language support

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Rensith Udara**
- GitHub: [@RensithUdara](https://github.com/RensithUdara)
- Project: [Home-Care-Mobile-App](https://github.com/RensithUdara/Home-Care-Mobile-App)

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- Google Fonts for typography
- Material Design for UI guidelines
- The open-source community for various packages

## 📞 Support

If you have any questions or need help, please:
1. Check the [Issues](https://github.com/RensithUdara/Home-Care-Mobile-App/issues) page
2. Create a new issue if needed
3. Contact the maintainer

---

<div align="center">
  <p>Made with ❤️ and Flutter</p>
  <p><strong>Home Care App - Managing your home, simplified.</strong></p>
</div>
