import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:social_media_app/common/widgets.login_signup/form_divider.dart';
import 'package:social_media_app/common/widgets.login_signup/social_button.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/helpers/helper_fuctions.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  @override
  Widget build(BuildContext context) {
    final dark = SMAHelperFunctions.isDarkMode(context);
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(SMASizes.defaultSpace),
          child: Column(
            children: [
              Text(SMATexts.signupTitle,
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: SMASizes.spaceBtwSections),
              Form(
                child: Column(
                  children: [
                    Row(children: [
                      Expanded(
                        child: TextFormField(
                          expands: false,
                          decoration: const InputDecoration(
                              labelText: SMATexts.firstName,
                              prefixIcon: Icon(Iconsax.user)),
                        ),
                      ),
                      const SizedBox(width: SMASizes.spaceBtwInputFields),
                      Expanded(
                        child: TextFormField(
                          expands: false,
                          decoration: const InputDecoration(
                              labelText: SMATexts.lastName,
                              prefixIcon: Icon(Iconsax.user)),
                        ), // TextFormField
                      ),
                    ]),
                    const SizedBox(height: SMASizes.spaceBtwInputFields),
                    TextFormField(
                      expands: false,
                      decoration: const InputDecoration(
                          labelText: SMATexts.userName,
                          prefixIcon: Icon(Iconsax.user_edit)),
                    ),
                    const SizedBox(height: SMASizes.spaceBtwInputFields),
                    TextFormField(
                      decoration: const InputDecoration(
                          labelText: SMATexts.email,
                          prefixIcon: Icon(Iconsax.direct)),
                    ), // TextFormField
                    const SizedBox(height: SMASizes.spaceBtwInputFields),

                    /// Phone Number
                    TextFormField(
                      decoration: const InputDecoration(
                          labelText: SMATexts.phoneNumber,
                          prefixIcon: Icon(Iconsax.call)),
                    ), // TextFormField
                    const SizedBox(height: SMASizes.spaceBtwInputFields),

                    /// Password
                    TextFormField(
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: SMATexts.password,
                        prefixIcon: Icon(Iconsax.password_check),
                        suffixIcon: Icon(Iconsax.eye_slash),
                      ), // InputDecoration
                    ), // TextFormField
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
                    const SizedBox (height: SMASizes.spaceBtwSections),
                    SizedBox(width: double.infinity,child: ElevatedButton(onPressed: (){},child: Text(SMATexts.createAccount),),),

                  ],
                ),
              ),
              const SizedBox (height: SMASizes.spaceBtwSections),
              SMAFormDivider(dark: dark, text: SMATexts.orSignUpWith),
              const SizedBox (height: SMASizes.spaceBtwSections),
              SMASocialButton(),
            ],
          ),
        ),
      ),
    );
  }
}
