import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stephenscalender2024/constants.dart';

class OnboardingContent extends StatelessWidget {
  final String text, image;
  const OnboardingContent({
    super.key,
    required this.text,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        const Text(
          "CAMPUS CONNECT",
          style: TextStyle(
              fontSize: 25, color: kPrimaryColor, fontWeight: FontWeight.bold),
        ),
        Text(text),
        SvgPicture.asset(
          image,
          height: 300,
          width: 300,
        )
      ],
    );
  }
}
