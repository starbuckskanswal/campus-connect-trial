import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stephenscalender2024/homepage/homepage.dart';
import 'package:stephenscalender2024/login/components/already_have_an_account_check.dart';
import 'package:stephenscalender2024/login/components/rounded_input_field.dart';
import 'package:stephenscalender2024/login/components/rounded_password_field.dart';
import 'package:stephenscalender2024/login/login_page.dart';
import 'package:stephenscalender2024/onboarding/onboarding.dart';
import 'package:stephenscalender2024/signup/components/background.dart';
import 'package:stephenscalender2024/signup/components/or_divider.dart';
import 'package:stephenscalender2024/signup/components/social_sign_in.dart';
import 'package:stephenscalender2024/welcomescreen/components/rounded_button.dart';

import '../../Society.dart';

class Body extends StatefulWidget {
  const Body({super.key});

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _errorMessage = '';
  bool _isLoading = false;
  bool _passwordVisible = false;

  void togglePasswordVisibility() {
    setState(() {
      _passwordVisible = !_passwordVisible;
    });
  }

  bool _validateEmail(String email) {
    return RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(email);
  }

  bool _validatePassword(String password) {
    return password.length >= 6;
  }

  String _signupErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'That email already has an account. Please log in instead.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Choose a stronger password with at least 6 characters.';
      case 'network-request-failed':
        return 'We could not reach the server. Please check your internet and try again.';
      default:
        return error.message ?? 'Could not create your account right now.';
    }
  }

  Future<void> _handleEmailSignup() async {
    if (_isLoading) return;

    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (!_validateEmail(email) || !_validatePassword(password)) {
      setState(() {
        _errorMessage =
            'Enter a valid email and a password with at least 6 characters.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      final User? user = userCredential.user;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-unavailable',
          message: 'Your account was created, but we could not load it yet.',
        );
      }

      final bool exists = await _checkUserExists(user.uid);
      if (!exists) {
        await userSetup(email);
      }

      await getSocieties();
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('email', email);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => false,
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _signupErrorMessage(error);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not create your account right now.';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Background(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return const OnboardingScreen();
                }));
              },
              child: const Text(
                'SIGNUP',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32),
              ),
            ),
            SvgPicture.asset(
              'assets/images/signup1.svg',
              height: size.height * 0.35,
            ),
            RoundedInputField(
              controller: _emailController,
              hintText: 'Your Email',
              onChanged: (_) {},
            ),
            RoundedPasswordField(
              controller: _passwordController,
              onChanged: (_) {},
              isVisible: _passwordVisible,
              toggleVisibility: togglePasswordVisibility,
            ),
            RoundedButton(
              text: 'SIGNUP',
              press: _handleEmailSignup,
            ),
            if (_isLoading) const CircularProgressIndicator(),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            AlreadyHaveanAccountCheck(
              login: false,
              press: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return const LoginScreen();
                }));
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

Future<bool> _checkUserExists(String uid) async {
  final CollectionReference users =
      FirebaseFirestore.instance.collection('Users');
  final QuerySnapshot querySnapshot =
      await users.where('uid', isEqualTo: uid).get();
  return querySnapshot.docs.isNotEmpty;
}

Future<void> userSetup(String email) async {
  final CollectionReference users =
      FirebaseFirestore.instance.collection('Users');
  final FirebaseAuth auth = FirebaseAuth.instance;
  final String uid = auth.currentUser!.uid;
  // Firestore rules require the stored email to exactly match the auth
  // token's email, so prefer the account email over the typed one.
  await users.add({'uid': uid, 'email': auth.currentUser!.email ?? email});
}

Future<List<Society>> getSocieties() async {
  try {
    final snapshot =
        await FirebaseFirestore.instance.collection('nsysuclubs').get();

    final societies =
        snapshot.docs.map((d) => Society.fromFirestore(d)).toList();

    await storeSocieties(societies);
    return societies;
  } catch (e) {
    debugPrint('Error retrieving societies: $e');
    return [];
  }
}

Future<void> storeSocieties(List<Society> societies) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final listJson = societies.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList('societies', listJson);
  } catch (e) {
    debugPrint('Error storing societies: $e');
  }
}

Future<List<Society>> loadSocieties() async {
  final prefs = await SharedPreferences.getInstance();
  final listJson = prefs.getStringList('societies');
  if (listJson == null) return [];

  return listJson
      .map((s) => Society.fromJson(jsonDecode(s) as Map<String, dynamic>))
      .toList();
}
