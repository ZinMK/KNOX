import 'package:calendar_view/calendar_view.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:knox/screens/LoginPage.dart';
import 'package:knox/screens/SingUpPage.dart';
import 'package:knox/screens/schedule_calendar.dart';
import 'package:knox/screens/splashScreen.dart';
import 'firebase_options.dart'; // This file is auto-generated when you configure Firebase

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    EventController ctrl = EventController();

    return CalendarControllerProvider(
      controller: ctrl,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Firebase Auth Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red, width: 1.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.blue,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),

        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // While checking auth state
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            } else if (snapshot.hasData) {
              // User is logged in
              return SplashScreen();
            } else {
              // User is NOT logged in
              return LoginPage();
            }
          },
        ),
        routes: {
          '/signup': (context) => const SignUpPage(),
          '/login':
              (context) => const LoginPage(), // You would need to create this
          '/todayAppointments':
              (context) =>
                  TodayAppointmentsPage(), // You would need to create this
          '/splash': (context) => SplashScreen(),
        },
      ),
    );
  }
}
