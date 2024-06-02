import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../navigation_menu.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../signup/signup.dart';

class SMALoginForm extends StatelessWidget {
  const SMALoginForm({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Padding(
        padding:
        EdgeInsets.symmetric(vertical: SMASizes.spaceBtwSections),
        child: Column(
          children: [
            TextFormField(
              decoration: const InputDecoration(
                  prefixIcon: Icon(Iconsax.direct_right),
                  labelText: SMATexts.email),
            ),
            const SizedBox(height: SMASizes.spaceBtwInputFields),
            TextFormField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Iconsax.password_check),
                labelText: SMATexts.password,
                suffixIcon: Icon(Iconsax.eye_slash),
              ),
            ),
            const SizedBox(height: SMASizes.spaceBtwInputFields / 2),
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Checkbox(value: true, onChanged: (value) {}),
                    const Text(SMATexts.rememberMe),
                  ]),
                  TextButton(
                      onPressed: () {},
                      child: const Text(SMATexts.forgetPassword)),
                ]),
            const SizedBox(height: SMASizes.spaceBtwSections),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context)=>Navigation()));
                    },
                    child: const Text(SMATexts.signIn))),
            const SizedBox(height: SMASizes.spaceBtwItems),
            SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context)=>SignUpScreen()));
                    },
                    child: const Text(SMATexts.createAccount))),
          ],
        ),
      ),
    );
  }
}