import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'constants/constants.dart';
import 'screens/caregiver/caregiver_home_screen.dart';
import 'screens/clinic/clinic_home_screen.dart';
import 'screens/doctor/doctor_home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/patient/patient_home_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/signup_success_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const ProviderScope(
      child: CuroMeApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(child: CuroMeApp());
  }
}

class CuroMeApp extends StatelessWidget {
  const CuroMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CuroME',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: AppColors.greyBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.indigo,
          primary: AppColors.indigo,
          secondary: AppColors.purple,
          tertiary: AppColors.emerald,
          error: AppColors.danger,
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: AppColors.patientText,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            borderSide: const BorderSide(color: AppColors.patientBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            borderSide: const BorderSide(color: AppColors.patientBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            borderSide: const BorderSide(color: AppColors.indigo, width: 1.5),
          ),
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/signin': (_) => const SignInScreen(),
        '/signup': (_) => const SignUpScreen(),
        '/signup_success': (_) => const SignupSuccessScreen(),
        '/doctor': (_) => const DoctorHomeScreen(),
        '/caregiver': (_) => const CaregiverHomeScreen(),
        '/patient': (_) => const PatientHomeScreen(),
        '/clinic': (_) => const ClinicHomeScreen(),
      },
      onUnknownRoute: (_) => MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }
}
