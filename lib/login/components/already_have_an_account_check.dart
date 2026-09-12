import 'package:flutter/material.dart';
import 'package:stephenscalender2024/constants.dart';
class AlreadyHaveanAccountCheck extends StatelessWidget {
  final bool login;
  final Function()? press;
  const AlreadyHaveanAccountCheck({
    super.key, this.login = true, this.press,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          login? "Don't have an Account? " : "Already have an account?",
          style: const TextStyle(color: kPrimaryColor),
        ),
        GestureDetector(
            onTap: press,
            child: Text(
              login? "Sign Up" : "Sign In",
              style: const TextStyle(
                  color: kPrimaryColor, fontWeight: FontWeight.bold),
            ))
      ],
    );
  }
}
