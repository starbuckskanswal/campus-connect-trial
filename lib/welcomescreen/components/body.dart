import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stephenscalender2024/constants.dart';
import 'package:stephenscalender2024/login/login_page.dart';
import 'package:stephenscalender2024/signup/signup.dart';
import 'package:stephenscalender2024/welcomescreen/components/background.dart';
import 'package:stephenscalender2024/welcomescreen/components/rounded_button.dart';

class Body extends StatelessWidget {
  const Body({super.key});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Background(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "WELCOME TO CAMPUS CONNECT",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SvgPicture.asset(
              "assets/images/welcome.svg",
              height: size.height * 0.3,
            ),
            RoundedButton(
              text: "LOGIN",
              press: () {
                Navigator.pushReplacement(context,MaterialPageRoute(builder: (context){
                  return const LoginScreen();
                }));
              },
            ),
            RoundedButton(
              text: "SIGNUP",
              press: () {
                Navigator.pushReplacement(context,MaterialPageRoute(builder: (context){
                  return const SignupScreen();
                }));
              },
              color: kPrimaryLightColor,
              textColor: Colors.black,
            )
          ],
        ),
      ),
    );
  }
}
