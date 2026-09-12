import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum AppUserRole { student, societyPoc }

class UserRoleService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<AppUserRole> getCurrentUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return AppUserRole.student;
    }

    if (await _isAllowlistedByEmail(user.email ?? '')) {
      return AppUserRole.societyPoc;
    }

    return AppUserRole.student;
  }

  static Future<bool> canManageEvents() async {
    return (await getCurrentUserRole()) == AppUserRole.societyPoc;
  }

  /// The college the signed-in POC is allowlisted under. This is the
  /// server-trusted value from their own `society_admins` doc — the same
  /// value firestore.rules checks event writes against — so events they
  /// create should always be tagged with this, not a value typed in the
  /// UI, to avoid a mismatch that the security rules would reject anyway.
  static Future<String?> getCurrentUserCollege() async {
    final user = FirebaseAuth.instance.currentUser;
    final email = (user?.email ?? '').trim().toLowerCase();
    if (email.isEmpty) {
      return null;
    }

    try {
      final doc = await _firestore.collection('society_admins').doc(email).get();
      final data = doc.data();
      final college = (data?['college'] as String?)?.trim();
      return (college == null || college.isEmpty) ? null : college;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> _isAllowlistedByEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      return false;
    }

    try {
      final directDoc = await _firestore
          .collection('society_admins')
          .doc(normalizedEmail)
          .get();

      if (directDoc.exists) {
        final data = directDoc.data();
        return (data?['active'] ?? true) == true;
      }
    } catch (_) {
      // Treat lookup failures as non-admin to keep access conservative.
    }

    return false;
  }
}
