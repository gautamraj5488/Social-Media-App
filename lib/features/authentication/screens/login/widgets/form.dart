

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:social_media_app/navigation_menu.dart';


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
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();


  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16.0),
                Text("Signing in..."),
              ],
            ),
          ),
        );
      },
    );
  }

  void _hideLoadingDialog() {
    Navigator.of(context, rootNavigator: true).pop();
  }

  void signUserIn() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    _showLoadingDialog();

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      _hideLoadingDialog();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed in successfully')),
      );
      Navigator.push(context, MaterialPageRoute(builder: (context)=>const Navigation()));
    } on FirebaseAuthException catch (e) {
      _hideLoadingDialog();

      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found for that email.';
          break;
        case 'wrong-password':
          errorMessage = 'Wrong password provided.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          break;
        case 'user-disabled':
          errorMessage = 'User has been disabled.';
          break;
        case 'invalid-credential':
          errorMessage = 'The supplied auth credential is incorrect. Consider creating an account.';
          break;
        default:
          errorMessage = 'An unknown error occurred.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      _hideLoadingDialog();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred. Please try again.')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    bool _passwordVisible = false;

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
              decoration:  InputDecoration(
                prefixIcon: const Icon(Iconsax.password_check),
                labelText: SMATexts.password,
                suffixIcon: IconButton(
                  icon: Icon(
                    _passwordVisible
                        ? Iconsax.eye
                        : Iconsax.eye_slash,
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
              Row(children: [
                Checkbox(value: true, onChanged: (value) {}),
                const Text(SMATexts.rememberMe),
              ]),
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
}
