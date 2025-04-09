import 'package:adboard/screens/auth_screens/edit_account.dart';
import 'package:adboard/screens/auth_screens/login.dart';
import 'package:adboard/screens/auth_screens/my_orders.dart';
import 'package:adboard/screens/form_screens/post_ad.dart';
import 'package:adboard/screens/home_screens/contact_us_screen.dart';
import 'package:adboard/screens/home_screens/faq_screen.dart';
import 'package:adboard/screens/home_screens/home.dart';
import 'package:adboard/screens/home_screens/my_ads.dart';
import 'package:adboard/screens/payment_screens/advertiser_payments.dart';
import 'package:adboard/screens/payment_screens/payment_screen.dart';
import 'package:adboard/screens/payment_screens/test_payment_screen.dart';
import 'package:adboard/widgets/bottom_navigation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  void navigateTo(String routeName, BuildContext context) {
    // Replace with actual navigation logic
    Navigator.pushNamed(context, routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Account',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          _buildAccountItem(
            context,
            title: "My Orders",
            icon: Icons.shopping_bag_outlined,
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MyOrderScreen()));
            },
          ),
          _buildAccountItem(
            context,
            title: "Pending Payments",
            icon: Icons.payment_outlined,
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PaymentScreen()));
            },
          ),
          _buildAccountItem(
            context,
            title: "My Details",
            icon: Icons.person_outline,
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const EditAccountScreen()));
            },
          ),
          _buildAccountItem(
            context,
            title: "Payments and Withdrawals",
            icon: Icons.credit_card_outlined,
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AdvertiserPaymentsScreen()));
            },
          ),
          const Divider(height: 32, thickness: 1, color: Colors.grey),
          _buildAccountItem(
            context,
            title: "FAQs",
            icon: Icons.help_outline,
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const FAQScreen()));
            },
          ),
          _buildAccountItem(
            context,
            title: "Help Center",
            icon: Icons.support_agent_outlined,
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ContactUsScreen()));
            },
          ),
          const Divider(height: 32, thickness: 1, color: Colors.grey),
          _buildLogoutItem(context),
        ],
      ),
    );
  }

  Widget _buildAccountItem(BuildContext context,
      {required String title,
        required IconData icon,
        required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      trailing:
      const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildLogoutItem(BuildContext context) {
    return ListTile(
        leading: const Icon(Icons.logout, color: Colors.red),
        title: const Text(
          "Logout",
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w500, color: Colors.red),
        ),
        onTap: () async {
          showDialog(
            context: context,
            barrierDismissible:
            false, // Prevents closing the dialog by tapping outside
            builder: (BuildContext context) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            },
          );

          try {
            // Perform sign-out
            await FirebaseAuth.instance.signOut();

            // Navigate to the login screen
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (Route<dynamic> route) => false, // Removes all previous routes
            );
          } catch (e) {
            Navigator.pop(
                context); // Close the loading indicator if sign-out fails
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error signing out: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
  }
}