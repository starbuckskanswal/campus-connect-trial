import 'package:flutter/material.dart';

const kPrimaryColor = Color(0xFF1b4332);
const kPrimaryLightColor = Color(0xFFF1E6FF);

const kCardColor = Color(0xFF84AB5C);
const kTextColor = Color(0xFF202E2E);
const kTextLigntColor = Color(0xFF7286A5);
const kNoticeboardAdminEmail = 'collegeadmin@example.com';

const kDefaultPadding = 20.0;
const kDefaultShadow = BoxShadow(
  offset: Offset(0,4),
  blurRadius: 4,
  color: Colors.black26
);

const headingStyle = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.bold,
  color: Colors.black,
  height: 1.5,
);

final otpInputDecoration = InputDecoration(
  contentPadding: const EdgeInsets.symmetric(vertical: 16),
  border: outlineInputBorder(),
  focusedBorder: outlineInputBorder(),
  enabledBorder: outlineInputBorder(),
);

OutlineInputBorder outlineInputBorder() {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: const BorderSide(color: kTextColor),
  );
}
