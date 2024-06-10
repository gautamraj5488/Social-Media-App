import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../navigation_menu.dart';
import '../../../../services/firestore.dart';
import 'login.dart';

class AuthPage extends StatelessWidget {
   AuthPage({super.key,});


  @override
  Widget build(BuildContext context)  {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context , snapshot) {
          if(snapshot.hasData){
            return Navigation();
          }
          else{
            return LoginScreen();
          }
        },

      ),
    );
  }
}
