import 'package:cloud_firestore/cloud_firestore.dart';

class Society {
  final String id;      // Firestore document id
  final String name;
  final String icon;    // URL of the icon

  Society({
    required this.id,
    required this.name,
    required this.icon,
  });

  factory Society.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Society(
      id: doc.id,
      name: (data['name'] ?? '') as String,
      icon: (data['icon'] ?? '') as String,
    );
  }

  factory Society.fromJson(Map<String, dynamic> json) {
    return Society(
      id: (json['id'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      icon: (json['icon'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
    };
  }
}
