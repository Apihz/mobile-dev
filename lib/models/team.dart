import 'team_member.dart';

class Team {
  final String id;
  final String name;
  final String leaderId; // uid of the user who created the team
  final String joinCode; // 6-char code for others to join
  final List<String> memberIds; // quick lookup of all member UIDs
  final List<TeamMember> members; // full member objects loaded from subcollection

  Team({
    required this.id,
    required this.name,
    this.leaderId = '',
    this.joinCode = '',
    List<String>? memberIds,
    List<TeamMember>? members,
  })  : memberIds = memberIds ?? [],
        members = members ?? [];

  factory Team.fromMap(String id, Map<String, dynamic> data) {
    return Team(
      id: id,
      name: data['name'] ?? 'Unnamed Team',
      leaderId: data['leaderId'] ?? data['ownerId'] ?? '',
      joinCode: data['joinCode'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
    );
  }

  @override
  bool operator ==(Object other) => other is Team && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
