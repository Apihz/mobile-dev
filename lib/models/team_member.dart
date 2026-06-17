import 'package:cloud_firestore/cloud_firestore.dart';

class TeamMember {
  final String uid;
  final String name;
  final String email;
  final String role; // 'leader' | 'member'
  final DateTime joinedAt;

  TeamMember({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.joinedAt,
  });

  factory TeamMember.fromMap(String uid, Map<String, dynamic> data) {
    return TeamMember(
      uid: uid,
      name: data['name'] ?? 'Unknown',
      email: data['email'] ?? '',
      role: data['role'] ?? 'member',
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'joinedAt': FieldValue.serverTimestamp(),
    };
  }
}
