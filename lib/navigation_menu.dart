import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:social_media_app/utils/constants/colors.dart';
import 'package:social_media_app/utils/helpers/helper_fuctions.dart';

import 'features/social_media/screens/home.dart';

class Navigation extends StatefulWidget {
  const Navigation({super.key});

  @override
  State<Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  int _selectedIndex = 0;

  // List of widgets representing each page
  final List<Widget> _pages = [
    HomeScreen(),
    StorePage(),
    WishlistPage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {

    final dark = SMAHelperFunctions.isDarkMode(context);
    return Scaffold(
        bottomNavigationBar: NavigationBar(
          height: 80,
          elevation: 0,
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          backgroundColor: dark? SMAColors.black: Colors.white,
          indicatorColor: dark ? SMAColors.white.withOpacity (0.1): SMAColors.black.withOpacity(0.1),
          destinations :const [
            NavigationDestination (icon: Icon (Iconsax.home), label: 'Home'),
            NavigationDestination (icon: Icon (Iconsax.search_normal), label: 'Search'),
            NavigationDestination (icon: Icon (Iconsax.message), label: 'Chat'),
            NavigationDestination (icon: Icon (Iconsax.user), label: 'Profile'),
          ]
        ),
        body: _pages[_selectedIndex]
    );
  }
}

class StorePage extends StatelessWidget {
  const StorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Store Page'),
    );
  }
}

class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Wishlist Page'),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Profile Page'),
    );
  }
}