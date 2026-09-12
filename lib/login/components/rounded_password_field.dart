import 'package:flutter/material.dart';
import 'package:stephenscalender2024/constants.dart';
import 'package:stephenscalender2024/login/components/text_field_container.dart';
import 'package:stephenscalender2024/signup/components/body.dart';
// Inside RoundedPasswordField widget

class RoundedPasswordField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool isVisible; // Add isVisible parameter
  final VoidCallback? toggleVisibility; // Add toggleVisibility callback

  const RoundedPasswordField({
    Key? key,
    this.controller,
    this.onChanged,
    required this.isVisible,
    this.toggleVisibility, // Initialize toggleVisibility callback
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFieldContainer(
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        obscureText: !isVisible,
        decoration: InputDecoration(
          hintText: "Password",
          icon: Icon(
            Icons.lock,
            color: kPrimaryColor,
          ),
          suffixIcon: GestureDetector(
            onTap: toggleVisibility, // Call toggleVisibility callback
            child: Icon(
              isVisible ? Icons.visibility : Icons.visibility_off,
              color: kPrimaryColor,
            ),
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
