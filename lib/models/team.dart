class Team {
  final String id;
  final String name;

  Team({required this.id, required this.name});

  factory Team.fromMap(String id, Map<String, dynamic> data) {
    return Team(id: id, name: data['name'] ?? 'Unnamed Team');
  }

  //compare teams by id so DropdownButton can match value to item
  @override
  bool operator ==(Object other) => other is Team && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
