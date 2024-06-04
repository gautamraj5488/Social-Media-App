import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/utils/theme/theme.dart';

import 'features/authentication/screens/login/authpage.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: SMAAppTheme.lightTheme,
      darkTheme: SMAAppTheme.darkTheme,
      home: AuthPage(),
    );
  }
}