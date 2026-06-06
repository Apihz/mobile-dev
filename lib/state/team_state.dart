import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/team.dart';

class TeamState extends ChangeNotifier {
  Team? _currentTeam;
  List<Team> _teams = [];
  bool _isLoading = false;

  Team? get currentTeam => _currentTeam;
  List<Team> get teams => _teams;
  bool get isLoading => _isLoading;

  //fetch all projects the logged-in user is a member of
  Future<void> loadTeams() async {
    _isLoading = true;
    notifyListeners();

    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      QuerySnapshot snap = await FirebaseFirestore.instance
          .collection('projects')
          .where('memberIds', arrayContains: uid)
          .get();

      _teams = snap.docs
          .map((d) => Team.fromMap(d.id, d.data() as Map<String, dynamic>))
          .toList();

      //auto select first team if none is selected yet
      if (_teams.isNotEmpty && _currentTeam == null) {
        _currentTeam = _teams.first;
      }
    } catch (e) {
      _teams = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  void selectTeam(Team team) {
    _currentTeam = team;
    notifyListeners();
  }

  //create a new project and auto select it
  Future<void> createTeam(String name) async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    String userName = FirebaseAuth.instance.currentUser!.email ?? 'Member';

    //generate a simple 6-char join code from the current timestamp
    String joinCode = DateTime.now().millisecondsSinceEpoch
        .toString()
        .substring(7);

    DocumentReference ref = await FirebaseFirestore.instance
        .collection('projects')
        .add({
          'name': name,
          'joinCode': joinCode,
          'ownerId': uid,
          'memberIds': [uid],
          'members': {uid: userName},
          'sprint': null,
          'createdAt': FieldValue.serverTimestamp(),
        });

    Team newTeam = Team(id: ref.id, name: name);
    _teams.add(newTeam);
    _currentTeam = newTeam;
    notifyListeners();
  }

  //clear state on logout so next login starts fresh
  void reset() {
    _currentTeam = null;
    _teams = [];
    notifyListeners();
  }
}
