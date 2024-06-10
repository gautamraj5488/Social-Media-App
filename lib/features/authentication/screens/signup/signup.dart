import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:social_media_app/common/widgets.login_signup/form_divider.dart';
import 'package:social_media_app/common/widgets.login_signup/social_button.dart';
import 'package:social_media_app/common/widgets/appbar/appbar.dart';

import '../../../../services/firestore.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/helpers/helper_fuctions.dart';


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
                        onPressed: () async {
                          showDialog(
                              context: context,
                              builder: (context){
                                return const Center(
                                    child: CircularProgressIndicator()
                                );
                              }
                          );
                          if (_formKey.currentState?.validate() == true) {
                            try {
                              // Try to create the user with email and password
                              await FirebaseAuth.instance.createUserWithEmailAndPassword(
                                email: _emailController.text,
                                password: _passwordController.text,
                              );

                              // Save user data to Firestore
                              await _fireStoreServices.createUser(
                                firstName: _firstNameController.text.trim().capitalizeFirst!.removeAllWhitespace,
                                lastName: _lastNameController.text.trim().capitalizeFirst!.removeAllWhitespace,
                                username: _usernameController.text.trim(),
                                email: _emailController.text.trim().toLowerCase(),
                                phoneNumber: _phoneNumberController.text.trim(),
                                password: _passwordController.text.trim(),
                                uid: _fireStoreServices.getCurrentUser()!.uid,
                                following: [],
                                followers: [],
                                requested: [],
                                requestToConfirm: [],
                                profilePicture: '', FCMtoken: widget.FCMtoken,
                              );
                              // Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=>AuthPage()), (Route<dynamic> route) => false);

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('User created successfully, Please Login to continue')),
                              );
                              _clearForm();
                              Navigator.pop(context);

                            } on FirebaseAuthException catch (e) {
                              // Check if the email is already in use
                              Navigator.pop(context);
                              if (e.code == 'email-already-in-use') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('The email is already in use by another account.')),
                                );
                              } else {
                                // Show other FirebaseAuthException error messages
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: ${e.message}')),
                                );
                              }
                            } catch (e) {
                              // Handle any other errors
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error creating user: $e')),
                              );
                            }
                          } else{
                            Navigator.pop(context);
                          }
                        },
                        child: const Text(SMATexts.createAccount),
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


