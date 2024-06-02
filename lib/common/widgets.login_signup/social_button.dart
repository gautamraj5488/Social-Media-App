import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../utils/constants/colors.dart';
import '../../utils/constants/image_strings.dart';
import '../../utils/constants/sizes.dart';

class SMASocialButton extends StatelessWidget {
  const SMASocialButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
              border: Border.all(color: SMAColors.grey),
              borderRadius: BorderRadius.circular(100)),
          child: IconButton(
            onPressed: () {},
            icon: const Image(
              width: SMASizes.iconMd,
              height: SMASizes.iconMd,
              image: AssetImage(SMAImages.google),
            ),
          ),
        ),
        const SizedBox(width: SMASizes.spaceBtwItems),
        Container(
          decoration: BoxDecoration(
              border: Border.all(color: SMAColors.grey),
              borderRadius: BorderRadius.circular(180)),
          child: IconButton(
            onPressed: () {},
            icon: const Image(
              width: SMASizes.iconMd,
              height: SMASizes.iconMd,
              image: AssetImage(SMAImages.facebook),
            ),
          ),
        ),
      ],
    );
  }
}