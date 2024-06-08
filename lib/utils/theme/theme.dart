import "package:flutter/material.dart";
import "package:social_media_app/utils/theme/custom_theme/appbar_theme.dart";
import "package:social_media_app/utils/theme/custom_theme/check_box_theme.dart";
import "package:social_media_app/utils/theme/custom_theme/chip_theme.dart";
import "package:social_media_app/utils/theme/custom_theme/elevated_button_theme.dart";
import "package:social_media_app/utils/theme/custom_theme/outlined_button_theme.dart";
import "package:social_media_app/utils/theme/custom_theme/text_field_theme.dart";
import "package:social_media_app/utils/theme/custom_theme/text_theme.dart";

class SMAAppTheme{
  SMAAppTheme._();
  static ThemeData lightTheme = ThemeData(

    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: Colors.blue,
    scaffoldBackgroundColor: Colors.white,
    textTheme: SMATextTheme.lightTextTheme,
    chipTheme: SMAChipTheme.lightChipTheme,
    appBarTheme: SMAAppBarTheme.lightAppBarTheme,
    checkboxTheme: SMACheckboxTheme.lightCheckboxTheme,
    elevatedButtonTheme: SMAElevatedButtonTheme.lightElevatedButtonTheme,
    outlinedButtonTheme: SMAOutlinedButtonTheme.lightOutlinedButtonTheme,
    inputDecorationTheme: SMATextFormFieldTheme.lightInputDecorationTheme
  );
  static ThemeData darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: Colors.blue,
      scaffoldBackgroundColor: Colors.black,
      textTheme: SMATextTheme.darkTextTheme,
      chipTheme: SMAChipTheme.darkChipTheme,
      appBarTheme: SMAAppBarTheme.darkAppBarTheme,
      checkboxTheme: SMACheckboxTheme.darkCheckboxTheme,
      elevatedButtonTheme: SMAElevatedButtonTheme.darkElevatedButtonTheme,
      outlinedButtonTheme: SMAOutlinedButtonTheme.darkOutlinedButtonTheme,
      inputDecorationTheme: SMATextFormFieldTheme.darkInputDecorationTheme
  );
}