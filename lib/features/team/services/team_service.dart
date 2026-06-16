import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/team_member.dart';
import '../../../models/task.dart';

// Handles all Firestore operations for team members, join requests,
// and per-member task progress tracking.
class TeamService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Members subcollection ──────────────────────────────────────────

  // Stream all members of a team from projects/{projectId}/members
  Stream<List<TeamMember>> watchMembers(String projectId) {
    return _db
        .collection('projects')
        .doc(projectId)
        .collection('members')
        .orderBy('joinedAt')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => TeamMember.fromMap(d.id, d.data()))
            .toList());
  }

  // Add a user to the team's members subcollection and memberIds array
  Future<void> addMember(
      String projectId, String uid, String name, String email,
      {String role = 'member'}) async {
    final memberDoc = _db
        .collection('projects')
        .doc(projectId)
        .collection('members')
        .doc(uid);

    await memberDoc.set({
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'joinedAt': FieldValue.serverTimestamp(),
    });

    // Also add uid to the project-level memberIds array
    await _db.collection('projects').doc(projectId).update({
      'memberIds': FieldValue.arrayUnion([uid]),
      'members.$uid': name,
    });
  }

  // Remove a member from both the subcollection and the memberIds array
  Future<void> removeMember(String projectId, String uid) async {
    await _db
        .collection('projects')
        .doc(projectId)
        .collection('members')
        .doc(uid)
        .delete();

    await _db.collection('projects').doc(projectId).update({
      'memberIds': FieldValue.arrayRemove([uid]),
      'members.$uid': FieldValue.delete(),
    });
  }

  // ── Join requests subcollection ────────────────────────────────────

  // Stream pending join requests for the leader to review
  Stream<List<Map<String, dynamic>>> watchJoinRequests(String projectId) {
    return _db
        .collection('projects')
        .doc(projectId)
        .collection('joinRequests')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {'id': d.id, ...d.data()})
            .toList());
  }

  // A non-leader member sends a request to join (or to add someone else)
  Future<void> sendJoinRequest(
    String projectId, {
    required String requesterUid,
    required String requesterName,
    required String requesterEmail,
  }) async {
    await _db
        .collection('projects')
        .doc(projectId)
        .collection('joinRequests')
        .add({
      'requesterUid': requesterUid,
      'requesterName': requesterName,
      'requesterEmail': requesterEmail,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Leader accepts a join request: add user to members, remove the request
  Future<void> acceptJoinRequest(String projectId, String requestId) async {
    final requestDoc = await _db
        .collection('projects')
        .doc(projectId)
        .collection('joinRequests')
        .doc(requestId)
        .get();

    if (!requestDoc.exists) return;

    final data = requestDoc.data();
    if (data == null) return;

    await addMember(
      projectId,
      data['requesterUid'] ?? '',
      data['requesterName'] ?? '',
      data['requesterEmail'] ?? '',
    );

    // Delete the request (or mark it accepted)
    await _db
        .collection('projects')
        .doc(projectId)
        .collection('joinRequests')
        .doc(requestId)
        .delete();
  }

  // Leader rejects a join request: just delete it
  Future<void> rejectJoinRequest(String projectId, String requestId) async {
    await _db
        .collection('projects')
        .doc(projectId)
        .collection('joinRequests')
        .doc(requestId)
        .delete();
  }

  // ── Delete entire team ────────────────────────────────────────────

  // Cascade delete all subcollections, then the project doc itself.
  // Firestore does NOT auto-delete subcollections when the parent is removed.
  Future<void> deleteTeam(String projectId) async {
    // Delete all members
    final membersSnap = await _db
        .collection('projects')
        .doc(projectId)
        .collection('members')
        .get();
    for (final doc in membersSnap.docs) {
      await doc.reference.delete();
    }

    // Delete all join requests
    final requestsSnap = await _db
        .collection('projects')
        .doc(projectId)
        .collection('joinRequests')
        .get();
    for (final doc in requestsSnap.docs) {
      await doc.reference.delete();
    }

    // Delete all tasks
    final tasksSnap = await _db
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .get();
    for (final doc in tasksSnap.docs) {
      await doc.reference.delete();
    }

    // Finally delete the project document
    await _db.collection('projects').doc(projectId).delete();
  }

  // ── Member task progress ───────────────────────────────────────────

  // Stream all tasks for a project
  Stream<List<Task>> watchTasks(String projectId) {
    return _db
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .orderBy('createdAt')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Task.fromMap(d.id, d.data())).toList());
  }

  // Given a list of tasks and a member uid, compute task stats.
  // Returns { 'done': int, 'doing': int, 'todo': int, 'overdue': int }
  static Map<String, int> computeTaskStats(List<Task> tasks, String uid) {
    final now = DateTime.now();
    final memberTasks = tasks.where((t) => t.assigneeId == uid).toList();

    int done = memberTasks.where((t) => t.status == 'done').length;
    int doing = memberTasks.where((t) => t.status == 'doing').length;
    int todo = memberTasks.where((t) => t.status == 'todo').length;
    // Overdue: not done and past deadline
    int overdue = memberTasks
        .where((t) =>
            t.status != 'done' &&
            t.deadline != null &&
            t.deadline!.isBefore(now))
        .length;

    return {'done': done, 'doing': doing, 'todo': todo, 'overdue': overdue};
  }
}
