# Knox CRM

<div align="center">
  <img src="KnoxScreenshots.png" alt="Knox CRM App Screenshots" width="100%"/>
</div>

A comprehensive Flutter-based Customer Relationship Management (CRM) application designed for field sales and service businesses. Knox CRM empowers sales teams to efficiently manage leads, schedule appointments, track sales analytics, and visualize customer locations on interactive maps—all from a single, intuitive mobile application.

---

## ✨ Key Features

### 🔐 **Secure Authentication System**

- **Email/Password Authentication**: Secure user registration and login powered by Firebase Authentication
- **Session Management**: Automatic session handling with persistent login
- **User Data Isolation**: Complete data privacy with user-specific data segregation
- **Remember Me**: Convenient login persistence option
- **Password Recovery**: Built-in forgot password functionality

### 📊 **Comprehensive Lead Management**

- **Lead Creation & Tracking**: Create and manage customer leads with detailed information
- **Status Management**: Track leads through multiple statuses:
  - New leads
  - Quoted
  - Got Contact
  - Next Year follow-ups
- **Lead Filtering**: Filter leads by status for quick access
- **Contact Information**: Store and manage customer contact details (name, email, phone)
- **Notes & Details**: Add comprehensive notes and descriptions for each lead
- **Lead to Appointment Conversion**: Seamlessly convert leads into scheduled appointments

### 📅 **Advanced Appointment Scheduling**

- **Interactive Calendar View**:
  - Two-week calendar view for better visibility
  - Visual appointment markers with color coding
  - Today highlighting and date selection
  - Smooth navigation between months
- **Weekly Schedule View**:
  - Hourly timeline from 4 AM to 10 PM
  - Visual appointment blocks with time ranges
  - Color-coded appointments (owner vs. shared)
  - Week navigation with previous/next controls
- **Appointment Management**:
  - Create appointments with detailed information
  - Edit existing appointments
  - Swipe-to-delete functionality
  - Appointment details including:
    - Customer name and contact info
    - Time range (start and end times)
    - Location address
    - Job description and price
    - Owner information
    - Creation date and notes
- **Real-time Updates**: Automatic synchronization with Firebase Firestore

### 📈 **Sales Analytics & Reporting**

- **Revenue Tracking**:
  - Today's revenue display
  - Monthly revenue summaries
  - Visual bar charts for sales trends
- **Performance Metrics**:
  - Sale conversion rate tracking
  - Lead conversion rate monitoring
  - Success rate calculations
- **Data Visualization**:
  - Interactive charts using FL Chart
  - Time-based analysis (daily/monthly views)
  - Visual representation of sales performance
- **Date Range Selection**: Filter analytics by specific date ranges

### 🗺️ **Geographic Visualization**

- **Interactive Google Maps Integration**:
  - Visualize all customer locations on an interactive map
  - Custom markers for different appointment types:
    - Lead markers
    - Sale markers
    - No response markers
    - Rejection markers
- **Location-based Management**:
  - View customer locations geographically
  - Plan routes between appointments
  - Territory visualization
- **Real-time Location Updates**: Automatic location synchronization

### 📱 **Modern User Interface**

- **Material Design 3**: Latest Material Design principles
- **Custom Google Fonts**: Beautiful typography with Google Fonts integration
- **Responsive Design**: Optimized for all screen sizes
- **Smooth Animations**: Fluid transitions and interactions
- **Intuitive Navigation**: Bottom navigation bar with 5 main sections:
  - Scheduler (Today's appointments)
  - Calendar View (Weekly schedule)
  - Maps (Geographic visualization)
  - Stats (Sales analytics)
  - Lead List (Lead management)
- **Color-coded UI**: Visual distinction for different appointment types and statuses

### 🎯 **Additional Features**

- **Onboarding Flow**: User-friendly introduction for new users
- **Splash Screen**: Professional app launch experience
- **Rate Cards**: Display and manage pricing information
- **Appointment Cards**: Beautiful card-based appointment display
- **Search & Filter**: Quick access to specific leads or appointments
- **Offline Support**: Firebase Firestore offline persistence

---

## 🛠️ Technology Stack

### **Frontend Framework**

- **Flutter 3.7+**: Cross-platform mobile development framework
- **Dart SDK**: Modern programming language for Flutter

### **Backend & Cloud Services**

- **Firebase Core**: Firebase platform integration
- **Firebase Authentication**: Secure user authentication
- **Cloud Firestore**: Real-time NoSQL database
  - Real-time data synchronization
  - Offline data persistence
  - User-specific data isolation

### **Maps & Location**

- **Google Maps Flutter**: Interactive map visualization
- **Geolocator**: Location services and geocoding

### **UI Components & Libraries**

- **Table Calendar**: Advanced calendar widget for appointment scheduling
- **Calendar View**: Weekly schedule visualization
- **FL Chart**: Beautiful and interactive charts for analytics
- **Google Fonts**: Custom typography
- **Flutter SpinKit**: Loading animations
- **Cupertino Icons**: iOS-style icons

### **Utilities**

- **Intl**: Internationalization and date formatting
- **HTTP**: API communication (for geocoding)

---

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  intl: ^0.20.2
  firebase_core: ^3.13.0
  firebase_auth: ^5.5.3
  cloud_firestore: ^5.6.7
  table_calendar: ^3.2.0
  calendar_view: ^1.4.0
  google_fonts: ^6.2.1
  flutter_spinkit: ^5.2.1
  fl_chart: ^0.71.0
  google_maps_flutter: ^2.12.1
  geolocator: ^14.0.0
  flutter_launcher_icons: ^0.14.3
```

---

## 🔧 Setup & Installation

### **Prerequisites**

- Flutter SDK 3.7 or higher
- Dart SDK (included with Flutter)
- Android Studio / Xcode (for mobile development)
- Firebase account
- Google Cloud account (for Maps API)

### **Installation Steps**

1. **Clone the Repository**

   ```bash
   git clone https://github.com/ZinMK/KNOX.git
   cd KNOX
   ```

2. **Install Dependencies**

   ```bash
   flutter pub get
   ```

3. **Firebase Setup**

   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Enable **Authentication** (Email/Password provider)
   - Enable **Cloud Firestore Database**
   - Run `flutterfire configure` to generate `firebase_options.dart`
   - Or manually:
     - Download `google-services.json` for Android
     - Download `GoogleService-Info.plist` for iOS
     - Place them in `android/app/` and `ios/Runner/` respectively

4. **Google Maps Setup**

   - Create a project in [Google Cloud Console](https://console.cloud.google.com/)
   - Enable **Maps SDK for Android** and **Maps SDK for iOS**
   - Create an API key
   - Add the API key to:
     - `android/app/src/main/AndroidManifest.xml`
     - `ios/Runner/AppDelegate.swift`
   - Configure location permissions in platform-specific files

5. **Run the Application**
   ```bash
   flutter run
   ```

---

## 📁 Project Structure

```
lib/
├── main.dart                          # App entry point & routing
├── firebase_options.dart              # Firebase configuration (auto-generated)
│
├── FirebaseFunctions/                 # Firebase service layer
│   ├── Auth/
│   │   └── AuthFunctions.dart        # Authentication functions
│   └── DatabaseFunctions/
│       └── db.dart                   # Firestore database operations
│
└── screens/                           # UI Screens
    ├── DataModels/
    │   └── appointmentModel.dart        # Data models (Lead & Appointment)
    │
    ├── widgets/
    │   └── AppointmentCards.dart     # Reusable appointment card widget
    │
    ├── LoginPage.dart                # User login screen
    ├── SingUpPage.dart               # User registration screen
    ├── splashScreen.dart              # App splash screen
    ├── onboarding.dart               # Onboarding flow
    │
    ├── leads_page.dart               # Lead management screen
    ├── leadcard.dart                 # Lead display component
    │
    ├── schedule_calendar.dart        # Main scheduler with calendar
    ├── calendar_view.dart            # Weekly schedule view
    ├── createApptPage.dart           # Create/Edit appointment screen
    │
    ├── salesAnalytics.dart           # Sales analytics dashboard
    │
    ├── mapscreen.dart                # Google Maps visualization
    │
    └── RateCards.dart                # Rate/pricing information
```

---

## 🎯 Feature Details

### **Lead Management System**

- **Create Leads**: Add new potential customers with full contact details
- **Status Pipeline**: Track leads through: New → Quoted → Got Contact → Next Year
- **Lead Details**: Store name, email, phone, notes, and status
- **Quick Actions**: Edit or delete leads with confirmation dialogs
- **Lead Conversion**: Convert leads directly into appointments

### **Appointment Scheduler**

- **Calendar Integration**:
  - Two-week view for better planning
  - Month navigation with arrows
  - Today highlighting
  - Selected date highlighting
  - Event markers (1-3+ appointments per day)
- **Appointment Details**:
  - Customer information
  - Time range (from/to)
  - Location address
  - Job description
  - Price information
  - Owner details
  - Creation timestamp
- **Actions**:
  - Swipe to delete
  - Tap to expand/collapse details
  - Edit appointment
  - Create new appointment (FAB button)

### **Weekly Schedule View**

- **Timeline Display**: Hourly grid from 4 AM to 10 PM
- **Appointment Blocks**: Visual blocks showing appointment duration
- **Color Coding**:
  - Green: Your appointments
  - Blue: Shared/other appointments
- **Week Navigation**: Previous/next week controls
- **Day Selection**: Tap any day to view that week
- **Appointment Interaction**: Tap appointments to view details

### **Sales Analytics Dashboard**

- **Revenue Metrics**:
  - Today's total revenue
  - Monthly total revenue
  - Visual bar charts
- **Conversion Rates**:
  - Sale success rate
  - Lead conversion rate
- **Date Filtering**: Select specific dates for analysis
- **Visual Charts**: Interactive bar charts using FL Chart

### **Maps Integration**

- **Customer Locations**: All appointments/leads plotted on map
- **Custom Markers**: Different markers for:
  - Leads (blue)
  - Sales (green)
  - No response (gray)
  - Rejections (red)
- **Interactive Map**: Zoom, pan, and tap markers for details

---

## 🔑 Configuration

### **Firebase Configuration**

1. The `firebase_options.dart` file is auto-generated and should NOT be committed
2. Configure Firestore security rules:
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /users/{userId}/{document=**} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
     }
   }
   ```
3. Enable Email/Password authentication in Firebase Console

### **Google Maps Configuration**

- **Android**: Add API key to `AndroidManifest.xml`
  ```xml
  <meta-data
      android:name="com.google.android.geo.API_KEY"
      android:value="YOUR_API_KEY"/>
  ```
- **iOS**: Add API key to `AppDelegate.swift`
  ```swift
  GMSServices.provideAPIKey("YOUR_API_KEY")
  ```

---

## 📱 Platform Support

- ✅ **Android** (API 21+)
- ✅ **iOS** (iOS 12+)
- ⚠️ **Web** (with limitations on maps/location features)
- ✅ **Windows**
- ✅ **macOS**
- ✅ **Linux**

---

## 🚀 Getting Started

1. **Set up Firebase**: Create project and enable required services
2. **Configure Maps**: Get Google Maps API key
3. **Install dependencies**: `flutter pub get`
4. **Run the app**: `flutter run`
5. **Create account**: Sign up with email/password
6. **Start managing**: Add leads, create appointments, track sales!

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🆘 Support

For support and questions:

- 📧 Create an issue on [GitHub Issues](https://github.com/ZinMK/KNOX/issues)
- 📚 Check the [Flutter Documentation](https://docs.flutter.dev/)
- 🔥 Review the [Firebase Documentation](https://firebase.google.com/docs)

---

## 🔄 Version History

- **v1.0.2** (Current)
  - Enhanced calendar integration with date range validation
  - Improved UI/UX with Material Design 3
  - Fixed layout overflow issues
  - Advanced sales analytics dashboard
  - Comprehensive lead management system
  - Interactive maps with custom markers

---

<div align="center">
  <p>Built with ❤️ using Flutter and Firebase</p>
  <p>⭐ Star this repo if you find it helpful!</p>
</div>
