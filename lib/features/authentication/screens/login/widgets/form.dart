

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:social_media_app/navigation_menu.dart';
import 'package:social_media_app/utils/device/device_utility.dart';
import 'package:social_media_app/utils/helpers/helper_fuctions.dart';


import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../signup/signup.dart';

class SMALoginForm extends StatefulWidget {
  SMALoginForm({
    super.key,
  });

  @override
  State<SMALoginForm> createState() => _SMALoginFormState();
}

class _SMALoginFormState extends State<SMALoginForm> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _passwordVisible = false;
  final _formKey = GlobalKey<FormState>();


  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            content: Row(
              children: [
                Image.asset("assets/gifs/loading.gif"),
                SizedBox(width: 20),
                Text('Loading...'),
              ],
            ),
          ),
        );
      },
    );
  }

  void _hideLoadingDialog() {
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  void signUserIn() async {
    if (_formKey.currentState?.validate() != true) {
      SMADeviceUtils.vibrate(Duration(milliseconds: 500));
      return;
    }

    // bool isConnected = await SMADeviceUtils.hasInternetConnection();
    // if (!isConnected) {
    //   SMAHelperFunctions.showSnackBar(context,"No internet connection");
    //   SMADeviceUtils.vibrate(Duration(milliseconds: 500));
    //   return;
    // }

    //_showLoadingDialog();

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      SMAHelperFunctions.showSnackBar(context,"Signed in successfully");
      _hideLoadingDialog();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Navigation()),
      );
    } on FirebaseAuthException catch (e) {
      _hideLoadingDialog();

      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found for that email.';
          SMADeviceUtils.vibrate(Duration(milliseconds: 100));
          break;
        case 'wrong-password':
          errorMessage = 'Wrong password provided.';
          SMADeviceUtils.vibrate(Duration(milliseconds: 500));
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          SMADeviceUtils.vibrate(Duration(milliseconds: 500));
          break;
        case 'user-disabled':
          errorMessage = 'User has been disabled.';
          SMADeviceUtils.vibrate(Duration(milliseconds: 500));
          break;
        case 'invalid-credential':
          errorMessage = 'The supplied auth credential is incorrect';
          SMADeviceUtils.vibrate(Duration(milliseconds: 500));
          break;
        default:
          errorMessage = 'An unknown error occurred.';
          SMADeviceUtils.vibrate(Duration(milliseconds: 500));
      }

      SMAHelperFunctions.showSnackBar(context,errorMessage);
    } catch (e) {
      _hideLoadingDialog();
      SMAHelperFunctions.showSnackBar(context,'An error occurred. Please try again.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred. Please try again.')),
      );
      SMADeviceUtils.vibrate(Duration(milliseconds: 500));
    }
  }

  @override
  Widget build(BuildContext context) {

    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: SMASizes.spaceBtwSections),
        child: Column(
          children: [
            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(
                  prefixIcon: Icon(Iconsax.direct_right),
                  labelText: SMATexts.email),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: SMASizes.spaceBtwInputFields),
          TextFormField(
            controller: passwordController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Iconsax.password_check),
              labelText: 'Password',
              suffixIcon: IconButton(
                icon: Icon(
                  _passwordVisible ? Iconsax.eye : Iconsax.eye_slash,
                ),
                onPressed: () {
                  setState(() {
                    _passwordVisible = !_passwordVisible;
                  });
                },
              ),
            ),
            obscureText: !_passwordVisible,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
            const SizedBox(height: SMASizes.spaceBtwInputFields / 2),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              // Row(children: [
              //   Checkbox(value: true, onChanged: (value) {}),
              //   const Text(SMATexts.rememberMe),
              // ]),
              Spacer(),
              TextButton(
                  onPressed: () {}, child: const Text(SMATexts.forgetPassword)),
            ]),
            const SizedBox(height: SMASizes.spaceBtwSections),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: () {
                      signUserIn();
                    },
                    child: const Text(SMATexts.signIn))),
            const SizedBox(height: SMASizes.spaceBtwItems),
            SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SignUpScreen()));
                    },
                    child: const Text(SMATexts.createAccount))),
          ],
        ),
      ),
    );
  }
  @override
  void dispose() {
    passwordController.dispose();
    emailController.dispose();
    super.dispose();
  }
}

