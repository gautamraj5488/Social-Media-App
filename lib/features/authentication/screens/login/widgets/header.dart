import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../utils/constants/image_strings.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';

class SMALoginHeader extends StatelessWidget {
  const SMALoginHeader({
    super.key,
    required this.dark,
  });

  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image(
            height: 150,
            image: AssetImage(
                dark ? SMAImages.darkAppLogo : SMAImages.lightAppLogo)),
        Text(
          SMATexts.loginTile,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(
          height: SMASizes.sm,
        ),
        Text(
          SMATexts.loginSubTile,
          style: Theme.of(context).textTheme.bodyMedium,
        )
      ],
    );
  }
}