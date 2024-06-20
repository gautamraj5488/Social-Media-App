import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:social_media_app/common/widgets.login_signup/form_divider.dart';
import 'package:social_media_app/common/widgets.login_signup/social_button.dart';
import 'package:social_media_app/common/widgets/appbar/appbar.dart';
import 'package:social_media_app/utils/device/device_utility.dart';

import '../../../../services/firestore.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/helpers/helper_fuctions.dart';
import '../login/login.dart';


class SignUpScreen extends StatefulWidget {
  final String FCMtoken;
  const SignUpScreen({super.key, required this.FCMtoken});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  void _clearForm() {
    _formKey.currentState?.reset();
    _firstNameController.clear();
    _lastNameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _phoneNumberController.clear();
    _usernameController.clear();
    _confirmPasswordController.clear();
  }

  final FireStoreServices _fireStoreServices = FireStoreServices();
  bool _isLoading = false;

  Future<void> _signUp() async {
    if (_formKey.currentState?.validate() == true) {
      showDialog(
          context: context,
          builder: (context) {
            return  Center(child: Image.asset("assets/gifs/loading.gif"));
          });

      try {
        // Check if username or email is already in use
        bool isUsernameTaken = await _fireStoreServices.isUsernameInUse(_usernameController.text.trim());
        bool isEmailTaken = await _fireStoreServices.isEmailInUse(_emailController.text.trim().toLowerCase());

        print(isUsernameTaken);
        print(isEmailTaken);

        if (isUsernameTaken) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('The username is already in use.')),
          );
          SMADeviceUtils.hideKeyboard(context);
          return;
        }

        if (isEmailTaken) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('The email is already in use by another account.')),
          );
          SMADeviceUtils.hideKeyboard(context);
          return;
        }

        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        await userCredential.user?.sendEmailVerification();

        await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Verify Your Email'),
              content: Text(
                  'An email verification link has been sent to your email address. Please verify your email before proceeding.'),
              actions: <Widget>[
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );

          await _fireStoreServices.createUser(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            username: _usernameController.text.trim(),
            email: _emailController.text.trim().toLowerCase(),
            phoneNumber: _phoneNumberController.text.trim(),
            password: _passwordController.text.trim(),
            uid: _fireStoreServices.getCurrentUser()!.uid,
            following: [],
            followers: [],
            requested: [],
            requestToConfirm: [],
            profilePicture: '',
            FCMtoken: widget.FCMtoken,
          );

          _showSnackBar('User created successfully');
          _clearForm();
          Navigator.pop(context);

      } on FirebaseAuthException catch (e) {
        Navigator.pop(context);
        if (e.code == 'email-already-in-use') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('The email is already in use by another account.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.message}')),
          );
        }
      } catch (e) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating user: $e')),
        );
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  @override
  Widget build(BuildContext context) {
    final dark = SMAHelperFunctions.isDarkMode(context);
    return Scaffold(
      appBar: SMAAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(bottom: SMASizes.defaultSpace,right: SMASizes.defaultSpace,left: SMASizes.defaultSpace),
          child: Column(
            children: [
              Text(SMATexts.signupTitle,
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: SMASizes.spaceBtwSections),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstNameController,
                          expands: false,
                          decoration: const InputDecoration(
                              labelText: SMATexts.firstName,
                              prefixIcon: Icon(Iconsax.user)),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your first name';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: SMASizes.spaceBtwInputFields),
                      Expanded(
                        child: TextFormField(
                          controller: _lastNameController,
                          expands: false,
                          decoration: const InputDecoration(
                              labelText: SMATexts.lastName,
                              prefixIcon: Icon(Iconsax.user)),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your last name';
                            }
                            return null;
                          },
                        ), // TextFormField
                      ),
                    ]),
                    const SizedBox(height: SMASizes.spaceBtwInputFields),
                    TextFormField(
                      controller: _usernameController,
                      expands: false,
                      decoration: const InputDecoration(
                          labelText: SMATexts.userName,
                          prefixIcon: Icon(Iconsax.user_edit)),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a username';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: SMASizes.spaceBtwInputFields),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                          labelText: SMATexts.email,
                          prefixIcon: Icon(Iconsax.direct)),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        return null;
                      },
                    ), // TextFormField
                    const SizedBox(height: SMASizes.spaceBtwInputFields),

                    /// Phone Number
                    TextFormField(
                      controller: _phoneNumberController,
                      decoration: const InputDecoration(
                          labelText: SMATexts.phoneNumber,
                          prefixIcon: Icon(Iconsax.call)),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        else if(value.length < 10){
                          return 'Atleast 10 digits required';
                        } else if(value.length >10){
                          return "Provide phone number without country code";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: SMASizes.spaceBtwInputFields),

                    /// Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: SMATexts.password,
                        prefixIcon: Icon(Iconsax.password_check),
                        //suffixIcon: Icon(Iconsax.eye_slash),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: SMASizes.spaceBtwInputFields),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: SMATexts.confirmPassword,
                        prefixIcon: Icon(Iconsax.password_check),
                        //suffixIcon: Icon(Iconsax.eye_slash),
                      ),
                      validator: (value) {
                        if ( value!.isEmpty) {
                          return 'Please confirm your password';
                        } else if(value != _passwordController.text){
                          return "Password doesn't matches";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: SMASizes.spaceBtwSections),
                    Row(children: [
                      SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(value: true, onChanged: (value) {})),
                      const SizedBox(width: SMASizes.spaceBtwItems),
                      Text.rich(
                        TextSpan(children: [
                          TextSpan(
                              text: '${SMATexts.iAgreeto} ',
                              style: Theme.of(context).textTheme.bodySmall),
                          TextSpan(
                              text: '${SMATexts.privacyPolicy} ',
                              style:
                                  Theme.of(context).textTheme.bodyMedium!.apply(
                                        color: dark
                                            ? SMAColors.white
                                            : SMAColors.primary,
                                        decoration: TextDecoration.underline,
                                        decorationColor: dark
                                            ? SMAColors.white
                                            : SMAColors.primary,
                                      )),
                          TextSpan(
                              text: '${SMATexts.and} ',
                              style: Theme.of(context).textTheme.bodySmall),
                          TextSpan(
                              text: SMATexts.termsOfUse,
                              style:
                                  Theme.of(context).textTheme.bodyMedium!.apply(
                                        color: dark
                                            ? SMAColors.white
                                            : SMAColors.primary,
                                        decoration: TextDecoration.underline,
                                        decorationColor: dark
                                            ? SMAColors.white
                                            : SMAColors.primary,
                                      )),
                        ]),
                      ),
                    ]),
                    const SizedBox(height: SMASizes.spaceBtwSections),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => _signUp(),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                          valueColor:
                          AlwaysStoppedAnimation<Color>(
                              Colors.white),
                        )
                            : const Text(SMATexts.createAccount),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: SMASizes.spaceBtwSections),
              SMAFormDivider(dark: dark, text: SMATexts.orSignUpWith),
              const SizedBox(height: SMASizes.spaceBtwSections),
              const SMASocialButton(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}


