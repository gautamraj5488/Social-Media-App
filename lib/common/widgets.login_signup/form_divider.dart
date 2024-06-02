import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../utils/constants/colors.dart';


class SMAFormDivider extends StatelessWidget {
  const SMAFormDivider({
    super.key,
    required this.dark, required this.text,

  });

  final bool dark;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.center, children: [
      Flexible(
          child: Divider(
              color: dark ? SMAColors.darkGrey : SMAColors.grey,
              thickness: 0.5,
              indent: 60,
              endIndent: 5)),
      Text(text,
          style: Theme.of(context).textTheme.labelMedium),
      Flexible(
          child: Divider(
              color: dark ? SMAColors.darkGrey : SMAColors.grey,
              thickness: 0.5,
              indent: 5,
              endIndent: 60)),
    ]);
  }
}