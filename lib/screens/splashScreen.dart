
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:knox/screens/onboarding.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Check user data after a short delay to allow splash screen to be visible
    Future.delayed(const Duration(seconds: 2), () {
      _checkUserData();
    });
  }

  Future<void> _checkUserData() async {
    // Check if user is already signed in
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? user = auth.currentUser;

    if (user != null) {
      // User is signed in, check if profile exists in Firestore

      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (userDoc.exists) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/todayAppointments');
        }
        // User profile exists, navigate to home screen
      } else {
        // User is authenticated but profile doesn't exist, go to onboarding
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
    } else {
      // No user is signed in, create anonymous user and go to onboarding
      final userCredential = await auth.signInAnonymously();

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo or icon
            const Icon(Icons.flutter_dash, size: 100, color: Colors.white),
            const SizedBox(height: 24),
            // App name
            const Text(
              'CRM',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 48),
            // Loading indicator
            const SpinKitDoubleBounce(color: Colors.white, size: 50.0),
          ],
        ),
      ),
    );
  }
}
