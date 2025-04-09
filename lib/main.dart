import 'package:adboard/screens/home_screens/home.dart';
import 'package:adboard/screens/main_screen.dart';
import 'package:adboard/screens/onboarding.dart';
import 'package:adboard/services/payment_service.dart';
import 'package:adboard/services/booking_service.dart';
import 'package:adboard/theme/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:adboard/screens/payment_screens/payment_screen.dart';
import 'package:adboard/screens/payment_screens/test_payment_screen.dart';
import 'package:adboard/screens/auth_screens/login.dart';
import 'package:adboard/screens/auth_screens/create_account.dart';
import 'package:adboard/screens/form_screens/post_ad.dart';
import 'package:adboard/screens/auth_screens/account.dart';
import 'package:adboard/screens/payment_screens/advertiser_payments.dart';
import 'package:adboard/screens/admin/withdrawal_requests.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await PaymentService.initialize();
  BookingService.startExpiryCheck();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Themed App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.lightTheme,
      themeMode: ThemeMode.system,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData) {
            return const MainScreen();
          } else {
            return const OnboardingScreen();
          }
        },
      ),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/create-account': (context) => const CreateAccountScreen(),
        '/post-ad': (context) => const PostAdScreen(),
        '/account': (context) => const AccountScreen(),
        '/payments': (context) => const AdvertiserPaymentsScreen(),
        '/test-payment': (context) => const TestPaymentScreen(),
        '/admin/withdrawals': (context) => const WithdrawalRequestsScreen(),
      },
    );
  }
}
