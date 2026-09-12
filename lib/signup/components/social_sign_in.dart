import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stephenscalender2024/homepage/homepage.dart';
import 'package:stephenscalender2024/signup/components/social_icon.dart';

import '../../Society.dart';

final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
Future<void>? _googleSignInInitialization;
bool _isGoogleSignInInProgress = false;

class SocialSignin extends StatelessWidget {
  const SocialSignin({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SocialIcon(
          iconSrc: 'assets/icons/facebook.svg',
          press: () {},
        ),
        SocialIcon(
          iconSrc: 'assets/icons/google-plus.svg',
          press: () async {
            await signUpWithGoogle(context);
          },
        ),
        SocialIcon(
          iconSrc: 'assets/icons/twitter.svg',
          press: () {},
        ),
      ],
    );
  }
}

Future<void> signUpWithGoogle(BuildContext context) async {
  if (_isGoogleSignInInProgress) return;
  _isGoogleSignInInProgress = true;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  try {
    await (_googleSignInInitialization ??= _googleSignIn.initialize());

    final GoogleSignInAccount googleSignInAccount =
        await _googleSignIn.authenticate();
    final GoogleSignInAuthentication authentication =
        googleSignInAccount.authentication;
    final String? idToken = authentication.idToken;

    if (idToken == null || idToken.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-google-token',
        message: 'Google sign-in did not return a usable token.',
      );
    }

    final AuthCredential credential = GoogleAuthProvider.credential(
      idToken: idToken,
    );

    final UserCredential userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);
    final User? user = userCredential.user;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-unavailable',
        message: 'Google sign-in completed, but the user account was empty.',
      );
    }

    try {
      await _ensureUserDocument(user);
    } catch (error) {
      debugPrint('Could not sync user profile yet: $error');
    }

    try {
      await _cacheSocieties();
    } catch (error) {
      debugPrint('Could not cache societies yet: $error');
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('email', user.email ?? googleSignInAccount.email);

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomePage()),
      (route) => false,
    );
  } on GoogleSignInException catch (error) {
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_googleSignInErrorMessage(error))),
    );
  } on FirebaseAuthException catch (error) {
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_firebaseGoogleErrorMessage(error))),
    );
  } catch (error) {
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Google sign-in could not finish. Please try again.'),
      ),
    );
    debugPrint('Error signing in with Google: $error');
  } finally {
    _isGoogleSignInInProgress = false;
  }
}

String _googleSignInErrorMessage(GoogleSignInException error) {
  switch (error.code) {
    case GoogleSignInExceptionCode.canceled:
      return 'Google sign-in was canceled.';
    case GoogleSignInExceptionCode.clientConfigurationError:
    case GoogleSignInExceptionCode.providerConfigurationError:
      return 'Google sign-in is not fully configured yet. We likely still need to add the Android SHA-1 fingerprint in Firebase and refresh google-services.json.';
    case GoogleSignInExceptionCode.uiUnavailable:
      return 'Google sign-in could not open properly. Please try again.';
    default:
      return error.description ?? 'Google sign-in could not finish.';
  }
}

String _firebaseGoogleErrorMessage(FirebaseAuthException error) {
  switch (error.code) {
    case 'account-exists-with-different-credential':
      return 'That email already exists with a different sign-in method. Please log in with that method first.';
    case 'network-request-failed':
      return 'We could not reach Firebase. Please check your internet and try again.';
    case 'invalid-credential':
    case 'missing-google-token':
      return 'Google sign-in returned an invalid credential. We may still need to finish the Firebase Android setup.';
    case 'operation-not-allowed':
      return 'Google sign-in is not enabled properly in Firebase yet.';
    default:
      return error.message ?? 'Google sign-in could not finish.';
  }
}

Future<void> _ensureUserDocument(User user) async {
  final QuerySnapshot existingUsers = await FirebaseFirestore.instance
      .collection('Users')
      .where('uid', isEqualTo: user.uid)
      .limit(1)
      .get();

  if (existingUsers.docs.isNotEmpty) {
    return;
  }

  await FirebaseFirestore.instance.collection('Users').add({
    'uid': user.uid,
    'email': user.email,
  });
}

Future<void> _cacheSocieties() async {
  final QuerySnapshot snapshot =
      await FirebaseFirestore.instance.collection('nsysuclubs').get();
  final List<Society> societies =
      snapshot.docs.map((d) => Society.fromFirestore(d)).toList();
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final List<String> listJson =
      societies.map((s) => jsonEncode(s.toJson())).toList();
  await prefs.setStringList('societies', listJson);
}
