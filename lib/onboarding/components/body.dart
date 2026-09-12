import 'package:flutter/material.dart';
import 'package:stephenscalender2024/constants.dart';
import 'package:stephenscalender2024/login/login_page.dart';
import 'package:stephenscalender2024/onboarding/components/onboarding_content.dart';
import 'package:stephenscalender2024/welcomescreen/components/rounded_button.dart';

class Body extends StatefulWidget {
  const Body({super.key});

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> {
  int currentPage = 0;
  List<Map<String, String>> splashData = [
    {
      "text": "Welcome to Campus Connect",
      "image": "assets/images/welcome.svg"
    },
    {
      "text": "Discover every society event in one place",
      "image": "assets/images/signup1.svg"
    },
    {"text": "Track what you like and mute what you don't", "image": "assets/images/loginpage.svg"},
  ];
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
              flex: 3,
              child: PageView.builder(
                onPageChanged: (value){
                  setState(() {
                    currentPage = value;
                  });
                },
                  itemCount: splashData.length,
                  itemBuilder: (context, index) => OnboardingContent(
                        text: splashData[index]["text"].toString(),
                        image: splashData[index]["image"].toString(),
                      ))),
          Expanded(
              flex: 2,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                        splashData.length, (index) => buildDot(index)),
                  ),
                  RoundedButton(text:"CONTINUE", press: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context){
                      return const LoginScreen();
                    }));
                  },)
                ],
              ))
        ],
      ),
    );
  }

  AnimatedContainer buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(seconds: 1),
      margin: const EdgeInsets.only(right: 5),
      height: 6,
      width: currentPage == index ? 20 : 6,
      decoration: BoxDecoration(
          color: currentPage == index ? kPrimaryColor : const Color(0xFFD8D8D8), borderRadius: BorderRadius.circular(3)),
    );
  }
}
