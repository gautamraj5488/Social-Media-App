import 'package:flutter/material.dart';
import 'package:social_media_app/common/styles/spacing_style.dart';
import 'package:social_media_app/features/authentication/screens/login/widgets/form.dart';
import 'package:social_media_app/features/authentication/screens/login/widgets/header.dart';
import 'package:social_media_app/utils/constants/text_strings.dart';
import 'package:social_media_app/utils/helpers/helper_fuctions.dart';

import '../../../../common/widgets.login_signup/form_divider.dart';
import '../../../../common/widgets.login_signup/social_button.dart';
import '../../../../services/firestore.dart';
import '../../../../utils/constants/sizes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key,});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final FireStoreServices _firestoreServices = FireStoreServices();

  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    _initializeFCMToken();
  }

  Future<void> _initializeFCMToken() async {
    String? token = await _firestoreServices.getFCMToken();
    if (mounted) {
      setState(() {
        _fcmToken = token;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = SMAHelperFunctions.isDarkMode(context);
    if (_fcmToken == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: SMASpacingStyle.paddingWithAppBarHeight,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SMALoginHeader(dark: dark),
              SMALoginForm(FCMtoken: _fcmToken!,),
              SMAFormDivider(dark: dark,text: SMATexts.orSignInWith,),
              SizedBox(
                height: SMASizes.spaceBtwSections,
              ),
              SMASocialButton(),
            ]),
          ),
        )
    );
  }
}
