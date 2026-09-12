import 'package:flutter/material.dart';
import 'package:stephenscalender2024/constants.dart';

class TitleIconWidget extends StatelessWidget {
  const TitleIconWidget({
    super.key,
    required this.text, required this.iconData
  });

  final String text;
  final IconData iconData;
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(iconData),
        const SizedBox(height: kDefaultPadding / 4,),
        RichText(text: TextSpan(
            style: const TextStyle(color: Colors.black,fontWeight: FontWeight.bold, fontSize: 15),
            children: [
              TextSpan(
                  text: text
              )
            ]
        ))
      ],
    );
  }
}
