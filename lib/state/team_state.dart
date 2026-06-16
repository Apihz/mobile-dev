import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../features/team/services/team_service.dart';
import '../models/team.dart';
import '../models/team_member.dart';

// Central state for team selection, member management, and join requests.
// Notify listeners so the UI rebuilds whenever data changes.
class TeamState extends ChangeNotifier {
  final TeamService _teamService = TeamService();

  Team? _currentTeam;
  List<Team> _teams = [];
  bool _isLoading = false;

  // Members of the currently selected team
  List<TeamMember> _members = [];
  StreamSubscription<List<TeamMember>>? _memberSub;

  // Join requests for the current team (leader only)
  List<Map<String, dynamic>> _joinRequests = [];
  StreamSubscription<List<Map<String, dynamic>>>? _requestSub;

  Team? get currentTeam => _currentTeam;
  List<Team> get teams => _teams;
  bool get isLoading => _isLoading;
  List<TeamMember> get members => _members;
  List<Map<String, dynamic>> get joinRequests => _joinRequests;

  // ── Team list management ───────────────────────────────────────────

  // Fetch all projects the logged-in user is a member of
  Future<void> loadTeams() async {
    _isLoading = true;
    notifyListeners();

    try {
      final String uid = FirebaseAuth.instance.currentUser!.uid;
      final QuerySnapshot snap = await FirebaseFirestore.instance
          .collection('projects')
          .where('memberIds', arrayContains: uid)
          .get();

      _teams = snap.docs
          .map((d) => Team.fromMap(d.id, d.data() as Map<String, dynamic>))
          .toList();

      if (_teams.isNotEmpty && _currentTeam == null) {
        _currentTeam = _teams.first;
        // Start listening to members for the auto-selected team
        _listenToMembers(_currentTeam!.id);
        _listenToJoinRequests(_currentTeam!.id);
      }
    } catch (e) {
      _teams = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // User picks a different team from the dropdown
  void selectTeam(Team team) {
    if (_currentTeam?.id == team.id) return;
    _currentTeam = team;
    _members = [];
    _joinRequests = [];
    _listenToMembers(team.id);
    _listenToJoinRequests(team.id);
    notifyListeners();
  }

  // Create a new project. The creator is automatically the leader.
  // [invitedEmails] are stored as pending invites; those users can later join.
  Future<void> createTeam(String name,
      {List<String> invitedEmails = const []}) async {
    final String uid = FirebaseAuth.instance.currentUser!.uid;
    final String userEmail = FirebaseAuth.instance.currentUser!.email ?? '';
    final String userName = userEmail.split('@').first;

    // 6-char join code from the current timestamp
    final String joinCode = DateTime.now()
        .millisecondsSinceEpoch
        .toString()
        .substring(7);

    // 1) Write the project document
    final DocumentReference ref = await FirebaseFirestore.instance
        .collection('projects')
        .add({
          'name': name,
          'joinCode': joinCode,
          'leaderId': uid,
          'ownerId': uid,
          'memberIds': [uid],
          'members': {uid: userName},
          'sprint': null,
          'pendingInvites': invitedEmails,
          'createdAt': FieldValue.serverTimestamp(),
        });

    // 2) Write the creator as a member in the subcollection
    await _teamService.addMember(ref.id, uid, userName, userEmail,
        role: 'leader');

    final Team newTeam = Team(
      id: ref.id,
      name: name,
      leaderId: uid,
      joinCode: joinCode,
      memberIds: [uid],
    );

    _teams.add(newTeam);
    _currentTeam = newTeam;
    _listenToMembers(ref.id);
    _listenToJoinRequests(ref.id);
    notifyListeners();
  }

  // ── Member management ──────────────────────────────────────────────

  // Start real-time listener for members of the given team
  void _listenToMembers(String projectId) {
    _memberSub?.cancel();
    _memberSub = _teamService.watchMembers(projectId).listen((mems) {
      _members = mems;
      notifyListeners();
    });
  }

  // Start real-time listener for pending join requests (leader only)
  void _listenToJoinRequests(String projectId) {
    _requestSub?.cancel();
    _requestSub =
        _teamService.watchJoinRequests(projectId).listen((requests) {
      _joinRequests = requests;
      notifyListeners();
    });
  }

  // Only the team leader can add a member directly.
  // Returns a descriptive error string on failure, null on success.
  Future<String?> addMember(String uid, String name, String email) async {
    if (_currentTeam == null) return 'No team selected';

    final currentUid = FirebaseAuth.instance.currentUser!.uid;

    // Guard: only the leader may add members
    if (currentUid != _currentTeam!.leaderId) {
      return 'Only the team leader can add members';
    }

    // Check if already a member
    if (_members.any((m) => m.uid == uid)) {
      return 'This user is already a member';
    }

    await _teamService.addMember(_currentTeam!.id, uid, name, email);
    return null;
  }

  // Only the leader may remove a member
  Future<String?> removeMember(String uid) async {
    if (_currentTeam == null) return 'No team selected';

    final currentUid = FirebaseAuth.instance.currentUser!.uid;
    if (currentUid != _currentTeam!.leaderId) {
      return 'Only the team leader can remove members';
    }

    // Leader cannot remove themselves
    if (uid == _currentTeam!.leaderId) {
      return 'You cannot remove the team leader';
    }

    await _teamService.removeMember(_currentTeam!.id, uid);
    return null;
  }

  // ── Join requests (for non-leaders to ask the leader) ──────────────

  // Any team member can send a join request to the leader
  Future<void> sendJoinRequest(
      String requesterUid, String requesterName, String requesterEmail) async {
    if (_currentTeam == null) return;
    await _teamService.sendJoinRequest(
      _currentTeam!.id,
      requesterUid: requesterUid,
      requesterName: requesterName,
      requesterEmail: requesterEmail,
    );
  }

  // Leader accepts a join request
  Future<void> acceptJoinRequest(String requestId) async {
    if (_currentTeam == null) return;
    await _teamService.acceptJoinRequest(_currentTeam!.id, requestId);
  }

  // Leader rejects a join request
  Future<void> rejectJoinRequest(String requestId) async {
    if (_currentTeam == null) return;
    await _teamService.rejectJoinRequest(_currentTeam!.id, requestId);
  }

  // ── Join by code ─────────────────────────────────────────────────

  // Let a user join a team using the shareable join code.
  // Returns an error message on failure, null on success.
  Future<String?> joinByCode(String code) async {
    final String uid = FirebaseAuth.instance.currentUser!.uid;
    final String email = FirebaseAuth.instance.currentUser!.email ?? '';
    final String name = email.split('@').first;

    // Find the project with the given join code
    final QuerySnapshot snap = await FirebaseFirestore.instance
        .collection('projects')
        .where('joinCode', isEqualTo: code)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      return 'No team found with that code';
    }

    final String projectId = snap.docs.first.id;

    // Check if user is already a member
    final memberDoc = await FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .collection('members')
        .doc(uid)
        .get();

    if (memberDoc.exists) {
      // Already a member, just reload teams to pick it up
      await loadTeams();
      return null;
    }

    // Add user as a member
    await _teamService.addMember(projectId, uid, name, email);

    // Reload teams so it appears in the dropdown
    await loadTeams();

    return null;
  }

  // ── Delete team (leader only) ──────────────────────────────────────

  // Only the team leader can delete the entire team.
  // Cancels active member/request streams, removes the team from state,
  // and selects the next available team (if any).
  Future<String?> deleteTeam() async {
    if (_currentTeam == null) return 'No team selected';

    final currentUid = FirebaseAuth.instance.currentUser!.uid;
    if (currentUid != _currentTeam!.leaderId) {
      return 'Only the team leader can delete the team';
    }

    final String projectId = _currentTeam!.id;

    // Cancel active stream listeners to avoid updates on a deleted doc
    _memberSub?.cancel();
    _memberSub = null;
    _requestSub?.cancel();
    _requestSub = null;

    await _teamService.deleteTeam(projectId);

    // Remove from the local team list
    _teams.removeWhere((t) => t.id == projectId);

    // Select next available team, or clear if none remain
    if (_teams.isNotEmpty) {
      _currentTeam = _teams.first;
      _listenToMembers(_currentTeam!.id);
      _listenToJoinRequests(_currentTeam!.id);
    } else {
      _currentTeam = null;
      _members = [];
      _joinRequests = [];
    }

    notifyListeners();
    return null;
  }

  // ── Cleanup ────────────────────────────────────────────────────────

  // Clear state on logout so next login starts fresh
  void reset() {
    _memberSub?.cancel();
    _memberSub = null;
    _requestSub?.cancel();
    _requestSub = null;
    _currentTeam = null;
    _teams = [];
    _members = [];
    _joinRequests = [];
    notifyListeners();
  }
}
