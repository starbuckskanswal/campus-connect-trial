import 'package:cloud_firestore/cloud_firestore.dart';

/// A single DU college in the `colleges` registry collection.
///
/// This is a curated, read-only-to-clients list (see firestore.rules) used
/// to populate college pickers in the app and the admin portal signup
/// flow, and to give the feed's college filter stable, spelling-consistent
/// values instead of free text.
class College {
  final String id; // Firestore document id, e.g. 'st-stephens'
  final String name; // Display name, e.g. "St. Stephen's College"
  final String shortCode; // e.g. 'SSC', shown in compact chips/badges
  final List<String> emailDomains; // e.g. ['ststephens.edu']
  final bool active;

  College({
    required this.id,
    required this.name,
    required this.shortCode,
    this.emailDomains = const [],
    this.active = true,
  });

  factory College.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return College(
      id: doc.id,
      name: (data['name'] ?? '') as String,
      shortCode: (data['shortCode'] ?? '') as String,
      emailDomains: List<String>.from(data['emailDomains'] ?? const []),
      active: (data['active'] ?? true) as bool,
    );
  }
}

class CollegeService {
  static Query<Map<String, dynamic>> _activeCollegesQuery() {
    return FirebaseFirestore.instance
        .collection('colleges')
        .where('active', isEqualTo: true)
        .orderBy('name');
  }

  static Future<List<College>> fetchColleges() async {
    try {
      final snapshot = await _activeCollegesQuery().get();
      return snapshot.docs.map(College.fromFirestore).toList();
    } catch (e) {
      // Conservative fallback: an empty list means pickers show nothing
      // rather than crashing, and callers can decide how to handle that.
      print('Error fetching colleges: $e');
      return [];
    }
  }

  static Stream<List<College>> streamColleges() {
    return _activeCollegesQuery().snapshots().map(
          (snapshot) => snapshot.docs.map(College.fromFirestore).toList(),
        );
  }
}
