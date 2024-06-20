import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iconsax/iconsax.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:social_media_app/features/authentication/screens/onboarding/widgets/onboardingpage.dart';
import 'package:social_media_app/utils/device/device_utility.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/image_strings.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/helpers/helper_fuctions.dart';
import '../login/authpage.dart';
import '../login/login.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({super.key});

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  final controller = PageController(initialPage: 0);
  int _currentPage = 0;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _completeOnBoarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onBoardingCompleted', true);
  }

  @override
  Widget build(BuildContext context) {
    final dark = SMAHelperFunctions.isDarkMode(context);

    return Scaffold(
      body: Stack(children: [
        PageView(
          controller: controller,
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
          },
          children: const [
            OnBoardingPage(
              image: SMAImages.onBoardingImage1,
              title: SMATexts.onBoardingTitlel,
              subTitle: SMATexts.onBoardingSubTitlel,
            ),
            OnBoardingPage(
              image: SMAImages.onBoardingImage2,
              title: SMATexts.onBoardingTitle2,
              subTitle: SMATexts.onBoardingSubTitle2,
            ),
            OnBoardingPage(
              image: SMAImages.onBoardingImage3,
              title: SMATexts.onBoardingTitle3,
              subTitle: SMATexts.onBoardingSubTitle3,
            ),
          ],
        ),
        Positioned(
            top: SMASizes.appBarHeight,
            right: SMASizes.defaultSpace,
            child: TextButton(
              onPressed: () {
                controller.animateToPage(2,
                    duration: const Duration(seconds: 1),
                    curve: Curves.easeInOut);
              },
              child: Text("Skip"),
              style: TextButton.styleFrom(
                foregroundColor: SMAColors.textSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            )
        ),
        Positioned(
            bottom: SMADeviceUtils.getBottomNavigationBarHeight() + 25,
            left: SMASizes.defaultSpace,
            child: SmoothPageIndicator(
              controller: controller,
              count: 3,
              effect: ExpandingDotsEffect(
                dotHeight: 6,
                activeDotColor: dark ? SMAColors.light : SMAColors.dark,
              ),
            )
        ),
        Positioned(
            right: SMASizes.defaultSpace,
            bottom: SMADeviceUtils.getBottomNavigationBarHeight(),
            child: ElevatedButton(
              onPressed: () async {
                if (_currentPage == 2) {
                  await _completeOnBoarding();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                } else {
                  controller.nextPage(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeInOut,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                backgroundColor: dark ? SMAColors.primary : Colors.black,
              ),
              child: const Icon(Iconsax.arrow_right_3),
            )
        ),
      ]),
    );
  }
}
