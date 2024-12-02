import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './providers/course_provider.dart';
import './screens/home_page.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import './navigation/app_navigation.dart';
import './screens/onboarding_page.dart'; // Import the onboarding page

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CourseProvider(),
      child: MaterialApp(
        title: 'Attendance App',
        theme: AppTheme.theme,
        home: const OnboardingPage(), // Set OnboardingPage as home
      ),
    );
  }
}
