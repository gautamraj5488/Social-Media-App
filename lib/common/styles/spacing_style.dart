import 'package:flutter/cupertino.dart';

import '../../utils/constants/sizes.dart';

class SMASpacingStyle{
  static const EdgeInsetsGeometry paddingWithAppBarHeight = EdgeInsets.only(
      top: SMASizes.appBarHeight,
      left: SMASizes.defaultSpace,
      bottom: SMASizes.defaultSpace,
      right: SMASizes.defaultSpace
  );
}