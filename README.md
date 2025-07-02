# Knox CRM

A comprehensive Flutter-based Customer Relationship Management (CRM) application designed for field sales and service businesses. Knox CRM helps sales teams manage leads, schedule appointments, track sales analytics, and visualize customer locations on interactive maps.

## 🚀 Features

### 📊 Lead Management

- Create, view, and manage customer leads
- Track lead status (New, Quoted, Got Contact, Next Year)
- Add detailed notes and contact information
- Convert leads to appointments seamlessly

### 📅 Appointment Scheduling

- Interactive calendar view for appointment management
- Schedule appointments with time slots
- Track appointment status and details
- Calendar integration with event management

### 📈 Sales Analytics

- Visual sales performance tracking with charts
- Revenue analytics and reporting
- Performance metrics dashboard
- Data visualization using FL Chart

### 🗺️ Location Mapping

- Interactive Google Maps integration
- Visualize customer locations with custom markers
- Track leads and sales geographically
- Location-based customer management

### 🔐 Authentication & Security

- Firebase Authentication integration
- Secure user registration and login
- User-specific data isolation
- Session management

### 📱 Modern UI/UX

- Material Design 3 implementation
- Responsive design for all screen sizes
- Custom Google Fonts integration
- Smooth animations and transitions

## 🛠️ Technology Stack

- **Framework**: Flutter 3.7+
- **Backend**: Firebase (Firestore, Authentication)
- **Maps**: Google Maps Flutter
- **Charts**: FL Chart
- **Calendar**: Calendar View & Table Calendar
- **State Management**: Provider pattern
- **Fonts**: Google Fonts

## 📦 Dependencies

```yaml
dependencies:
  flutter: sdk
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
```

## 🔧 Setup & Installation

### Prerequisites

- Flutter SDK 3.7 or higher
- Dart SDK
- Firebase project setup
- Google Maps API key

### Installation Steps

1. **Clone the repository**

   ```bash
   git clone https://github.com/ZinMK/KNOX.git
   cd KNOX
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Firebase Setup**

   - Create a new Firebase project
   - Enable Authentication and Firestore
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place them in the appropriate platform directories

4. **Google Maps Setup**

   - Get a Google Maps API key
   - Enable Maps SDK for Android/iOS
   - Add the API key to platform-specific configuration files

5. **Run the application**
   ```bash
   flutter run
   ```

## 📁 Project Structure

```
lib/
├── main.dart                          # App entry point
├── firebase_options.dart              # Firebase configuration
├── FirebaseFunctions/                 # Firebase service functions
│   ├── Auth/                         # Authentication functions
│   └── DatabaseFunctions/            # Firestore operations
└── screens/                          # UI screens
    ├── DataModels/                   # Data models
    │   └── appointmentModel.dart     # Lead & Appointment models
    ├── widgets/                      # Reusable widgets
    ├── LoginPage.dart               # Authentication screens
    ├── SingUpPage.dart
    ├── splashScreen.dart
    ├── onboarding.dart
    ├── leads_page.dart              # Lead management
    ├── createApptPage.dart          # Appointment creation
    ├── calendar_view.dart           # Calendar interface
    ├── schedule_calendar.dart       # Appointment scheduling
    ├── salesAnalytics.dart          # Analytics dashboard
    ├── mapscreen.dart               # Google Maps integration
    ├── leadcard.dart                # Lead display components
    └── RateCards.dart               # Rate information
```

## 🎯 Key Features Breakdown

### Lead Management System

- **Lead Creation**: Add new potential customers with contact details
- **Status Tracking**: Monitor lead progression through sales pipeline
- **Note Management**: Add detailed notes and follow-up reminders
- **Filter & Search**: Quickly find leads by status or other criteria

### Appointment Scheduler

- **Calendar Integration**: Visual calendar interface for scheduling
- **Time Slot Management**: Flexible appointment timing
- **Customer Association**: Link appointments to existing leads
- **Status Updates**: Track appointment completion and outcomes

### Analytics Dashboard

- **Sales Metrics**: Track conversion rates and revenue
- **Performance Charts**: Visual representation of sales data
- **Time-based Analysis**: Monitor trends over time periods
- **Custom Reports**: Generate insights for business decisions

### Geographic Visualization

- **Customer Mapping**: Plot customer locations on interactive maps
- **Route Planning**: Optimize travel between appointments
- **Territory Management**: Visualize sales territories
- **Location-based Insights**: Analyze geographic sales patterns

## 🔑 Configuration

### Firebase Configuration

1. Update `firebase_options.dart` with your project settings
2. Configure Firestore security rules for user data isolation
3. Set up authentication providers (Email/Password)

### Google Maps Configuration

- Add API key to `android/app/src/main/AndroidManifest.xml`
- Add API key to `ios/Runner/AppDelegate.swift`
- Configure location permissions

## 📱 Platform Support

- ✅ Android
- ✅ iOS
- ✅ Web (with limitations on maps/location)
- ✅ Windows
- ✅ macOS
- ✅ Linux

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:

- Create an issue on GitHub
- Check the documentation
- Review the Flutter and Firebase documentation

## 🔄 Version History

- **v1.0.2** - Current version with core CRM functionality
- Enhanced lead management
- Improved calendar integration
- Advanced analytics dashboard

---

Built with ❤️ using Flutter and Firebase
s
