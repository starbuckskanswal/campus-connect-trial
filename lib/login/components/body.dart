import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stephenscalender2024/homepage/homepage.dart';
import 'package:stephenscalender2024/login/components/already_have_an_account_check.dart';
import 'package:stephenscalender2024/login/components/background.dart';
import 'package:stephenscalender2024/login/components/rounded_input_field.dart';
import 'package:stephenscalender2024/login/components/rounded_password_field.dart';
import 'package:stephenscalender2024/signup/components/or_divider.dart';
import 'package:stephenscalender2024/signup/components/social_sign_in.dart';
import 'package:stephenscalender2024/signup/signup.dart';
import 'package:stephenscalender2024/welcomescreen/components/rounded_button.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../Society.dart';

class Body extends StatefulWidget {
  const Body({Key? key}) : super(key: key);

  @override
  _BodyState createState() => _BodyState();
}

class _BodyState extends State<Body> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController resetEmailController = TextEditingController();
  bool isLoading = false;
  String errorMessage = '';
  bool _passwordVisible = false;

  void togglePasswordVisibility() {
    setState(() {
      _passwordVisible = !_passwordVisible;
    });
  }

  void _navigateToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomePage()),
      (route) => false,
    );
  }

  Future<List<Society>> getSocieties() async {
    try {
      final snapshot =
      await FirebaseFirestore.instance.collection('nsysuclubs').get();

      final societies =
      snapshot.docs.map((d) => Society.fromFirestore(d)).toList();

      await storeSocieties(societies); // now includes icon in JSON
      return societies;
    } catch (e) {
      print('Error retrieving societies: $e');
      return [];
    }
  }

  Future<void> storeSocieties(List<Society> societies) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = societies.map((s) => jsonEncode(s.toJson())).toList();
      await prefs.setStringList('societies', listJson);
    } catch (e) {
      print('Error storing societies: $e');
    }
  }

  Future<List<Society>> loadSocieties() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = prefs.getStringList('societies');
      if (listJson == null) return [];

      final societies = listJson.map((s) {
        try {
          final map = jsonDecode(s) as Map<String, dynamic>;
          return Society.fromJson(map);
        } catch (e) {
          print('Skipping invalid society entry: $s, error: $e');
          return null;
        }
      }).whereType<Society>().toList();

      return societies;
    } catch (e) {
      print('Error retrieving societies: $e');
      return [];
    }
  }

  bool _isValidEmail(String value) {
    final email = value.trim();
    return RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _showForgotPasswordDialog() async {
    resetEmailController.text = emailController.text.trim();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reset password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your email address and we will send you a password reset link.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: resetEmailController,
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final email = resetEmailController.text.trim();
                if (!_isValidEmail(email)) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid email address.')),
                  );
                  return;
                }

                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                  if (!dialogContext.mounted || !mounted) return;
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Password reset link sent to $email')),
                  );
                } on FirebaseAuthException catch (error) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_forgotPasswordErrorMessage(error))),
                  );
                }
              },
              child: const Text('Send link'),
            ),
          ],
        );
      },
    );
  }

  String _forgotPasswordErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'That email address does not look valid.';
      case 'user-not-found':
        return 'No account was found for that email address.';
      case 'too-many-requests':
        return 'Too many reset attempts right now. Please try again in a little while.';
      default:
        return error.message ?? 'Could not send the password reset email.';
    }
  }

  String _loginErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          return 'Email or password is incorrect.';
        case 'too-many-requests':
          return 'Too many login attempts. Please wait a bit and try again.';
        default:
          return error.message ?? 'Could not log you in right now.';
      }
    }

    return 'Could not log you in right now.';
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    resetEmailController.dispose();
    super.dispose();
  }







  // Future<List<String>> getSocietyNames() async {
  //   try {
  //     QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('nsysuclubs').get();
  //     List<String> societyNames = querySnapshot.docs.map((doc) => doc['name'] as String).toList();
  //     await storeSocietyNames(societyNames);
  //     return societyNames;
  //   } catch (e) {
  //     print('Error retrieving society names: $e');
  //     return [];
  //   }
  // }
  //
  // Future<void> storeSocietyNames(List<String> societyNames) async {
  //   try {
  //     SharedPreferences prefs = await SharedPreferences.getInstance();
  //     await prefs.setStringList('societyNames', societyNames);
  //     print(societyNames);
  //   } catch (e) {
  //     print('Error storing society names: $e');
  //   }
  // }


  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Background(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "LOGIN",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            SvgPicture.asset(
              "assets/images/loginpage.svg",
              height: size.height * 0.35,
            ),
            RoundedInputField(
              hintText: "Your Email",
              controller: emailController,
            ),
            RoundedPasswordField(
              controller: passwordController,
              isVisible: _passwordVisible,
              onChanged: (value) {},
              toggleVisibility: togglePasswordVisibility,
            ),
            SizedBox(
              width: size.width * 0.8,
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _showForgotPasswordDialog,
                  child: const Text('Forgot password?'),
                ),
              ),
            ),
            RoundedButton(
              text: "LOGIN",
              press: () async {
                setState(() {
                  isLoading = true;
                  errorMessage = '';
                });
                try {
                  await FirebaseAuth.instance.signInWithEmailAndPassword(
                    email: emailController.text.trim(),
                    password: passwordController.text.trim(),
                  );
                  SharedPreferences prefs =
                  await SharedPreferences.getInstance();
                  prefs.setBool('isLoggedIn', true);
                  prefs.setString('email', emailController.text.toString());
                  await getSocieties();
                  await loadSocieties();
                  if (!mounted) return;
                  _navigateToHome();
                } catch (e) {
                  setState(() {
                    isLoading = false;
                    errorMessage = _loginErrorMessage(e);
                  });
                }
              },
            ),
            Visibility(
              visible: errorMessage.isNotEmpty,
              child: Text(
                errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ),
            Visibility(
              visible: isLoading,
              child: const CircularProgressIndicator(),
            ),
            AlreadyHaveanAccountCheck(
              press: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignupScreen()),
                );
              },
            ),
            const OrDivider(),
            const SocialSignin(),
          ],
        ),
      ),
    );
  }
}
