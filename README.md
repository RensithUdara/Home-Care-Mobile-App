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
├── components/           # Reusable UI components
│   ├── add_product.dart
│   ├── app_icon.dart
│   ├── bottom_add_bar.dart
│   ├── call_button.dart
│   ├── edit_product_bottom_sheet.dart
│   ├── item_tile.dart
│   ├── main_button.dart
│   ├── search_bar.dart
│   └── text_input_field.dart
├── models/              # Data models
│   └── products.dart
├── screens/             # App screens
│   ├── home.dart
│   ├── login.dart
│   ├── product.dart
│   ├── profile.dart
│   └── register.dart
├── services/            # Business logic
│   ├── auth/           # Authentication services
│   └── firestore/      # Database services
├── themes/             # App theming
│   ├── dark_mode.dart
│   ├── light_mode.dart
│   └── theme_provider.dart
├── utils/              # Utility functions
├── firebase_options.dart
└── main.dart           # App entry point
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

## 📸 Screenshots

### Authentication Screens
- **Login Screen**: Modern design with gradient background, enhanced input fields with shadows, password visibility toggle
- **Register Screen**: Comprehensive form with password strength indicator, real-time validation

### Main App Screens
- **Home Dashboard**: Clean appliance inventory with search and filter options
- **Product Details**: Detailed view with service history and direct calling
- **Profile Management**: User settings and theme toggle

## 🎨 UI/UX Features

### Enhanced Design Elements
- **Gradient Backgrounds**: Subtle gradients for visual depth
- **Shadow Effects**: Enhanced shadows on buttons and input fields
- **Rounded Corners**: Modern 12px border radius throughout
- **Password Eye Icon**: Toggle password visibility with smooth animations
- **Social Login Buttons**: Sleek Apple and Google login options
- **Color Theming**: Carefully crafted light and dark color schemes

### Responsive Design
- Adaptive layouts for different screen sizes
- Touch-friendly button sizes
- Proper spacing and typography scaling

## 🔧 Configuration

### Environment Variables

Create a `.env` file (optional) for additional configuration:
```
APP_NAME=Home Care App
VERSION=1.0.0
ENVIRONMENT=development
```

### Theme Customization

The app supports custom theming through `theme_provider.dart`. You can modify colors in:
- `themes/light_mode.dart`
- `themes/dark_mode.dart`

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
