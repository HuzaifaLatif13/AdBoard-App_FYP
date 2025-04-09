import 'package:adboard/screens/home_screens/search.dart';
import 'package:flutter/material.dart';

import '../modals/ad_modal.dart';
import '../screens/auth_screens/account.dart';
import '../screens/form_screens/post_ad.dart';
import '../screens/home_screens/home.dart';
import '../screens/home_screens/my_ads.dart';

class MainNavigationScreen extends StatefulWidget {
  final Future<List<AdModel>> ads;
  const MainNavigationScreen({super.key, required this.ads});

  @override
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;



  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      const HomeScreen(),
      FutureBuilder<List<AdModel>>(
        future: widget.ads,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No ads found.'));
          } else {
            return SearchResultsScreen(
              ads: snapshot.data!,
              query: '',
            );
          }
        },
      ),
      const PostAdScreen(),
      const MyAdsScreen(),
      const AccountScreen(),
    ];

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Add'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'My Ads'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }
}
