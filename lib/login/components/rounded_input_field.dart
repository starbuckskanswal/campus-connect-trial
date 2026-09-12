import 'package:flutter/material.dart';
import 'package:stephenscalender2024/constants.dart';
import 'package:stephenscalender2024/login/components/text_field_container.dart';

class RoundedInputField extends StatelessWidget {
  final String hintText;
  final IconData icon;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator; // Add validator parameter

  const RoundedInputField({
    Key? key,
    required this.hintText,
    this.icon = Icons.person,
    this.controller,
    this.onChanged,
    this.validator, // Add validator parameter
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFieldContainer(
      child: TextFormField(
        controller: controller,
        onChanged: onChanged,
        validator: validator, // Assign the validator
        decoration: InputDecoration(
          icon: Icon(
            icon,
            color: kPrimaryColor,
          ),
          hintText: hintText,
          border: InputBorder.none,
        ),
      ),
    );
  }
}


