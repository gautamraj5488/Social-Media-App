import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:social_media_app/services/firestore.dart';
import 'package:social_media_app/utils/constants/colors.dart';
import 'package:social_media_app/utils/helpers/helper_fuctions.dart';

import 'common/widgets/appbar/appbar.dart';
import 'features/social_media/screens/chat/chat_home.dart';
import 'features/social_media/screens/home/create_post.dart';
import 'features/social_media/screens/home/home.dart';
import 'features/social_media/screens/profile/profile_page.dart';
import 'features/social_media/screens/search/search_screen.dart';

class Navigation extends StatefulWidget {
  const Navigation({super.key});

  @override
  State<Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  int _selectedIndex = 0;

  final FireStoreServices _firestoreServices = FireStoreServices();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    _initializeFCMToken();
    //_firestoreServices.updateFCMtoken(FCMtoken: _fcmToken!, uid: _auth.currentUser!.uid);
  }

  Future<void> _initializeFCMToken() async {
    String? token = await _firestoreServices.getFCMToken();
    if (token != null) {
      setState(() {
        _fcmToken = token;
      });
      _updateFCMToken(token);
    }
  }
  Future<void> _updateFCMToken(String token) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestoreServices.updateFCMtoken(FCMtoken: token, uid: user.uid);
    }
  }

  // List of widgets representing each page


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void signUserOut() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final dark = SMAHelperFunctions.isDarkMode(context);

    final List<Widget> _pages = [
      HomeScreen(),
      SearchScreen(),
      ChatHomePage(),
      ProfilePage(uid: _auth.currentUser!.uid, username: '', fromChat: false,),
    ];

    return Scaffold(

        bottomNavigationBar: NavigationBar(
          height: 80,
          elevation: 0,
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          backgroundColor: dark ? SMAColors.black : Colors.white,
          indicatorColor: dark
              ? SMAColors.white.withOpacity(0.1)
              : SMAColors.black.withOpacity(0.1),
          destinations: [
            NavigationDestination(icon: Icon(Iconsax.home), label: 'Home'),
            NavigationDestination(
                icon: Icon(Iconsax.search_normal), label: 'Search'),
            // NavigationDestination(icon: Icon(Iconsax.message), label: 'Chat'),
            Stack(

              children: [
                NavigationDestination(icon: Icon(Iconsax.message), label: 'Chat'),
                Positioned(
                  top: 7,
                  right: 33,
                  child: Container(
                  padding: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(width: 1,color: dark? SMAColors.white : SMAColors.black)
                  ),
                  child: Text('',style: TextStyle(fontSize: 10,fontWeight: FontWeight.w600),),
                ),),

              ],
            ),
            NavigationDestination(icon: Icon(Iconsax.user), label: 'Profile'),
          ],
        ),
        body: _pages[_selectedIndex]);
  }
}


