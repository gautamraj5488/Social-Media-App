import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


import 'app.dart';
import 'firebase_options.dart';

void main() async {
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // TODO : Add widget Binding
  // TODO : Local Storage
  // TODO : Splash screen
  // TODO : Firebase
  // TODO : Authentication

  runApp(const MyApp());

}





