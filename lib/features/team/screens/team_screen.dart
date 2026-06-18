import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../features/auth/services/auth_service.dart';
import '../../../models/task.dart';
import '../../../models/team.dart';
import '../../../models/team_member.dart';
import '../../../state/team_state.dart';
import '../services/team_service.dart';
import '../widgets/add_member_sheet.dart';
import '../widgets/member_card.dart';
import '../../../shared/widgets/team_switcher_dropdown.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  final TeamService _teamService = TeamService();

  @override
  Widget build(BuildContext context) {
    final TeamState teamState = context.watch<TeamState>();
    final Team? team = teamState.currentTeam;

    // ── No team selected yet ────────────────────────────────────
    if (teamState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (team == null || teamState.teams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.groups_outlined, size: 64, color: AppColors.muted),
            const SizedBox(height: 16),
            const Text(
              'No team selected',
              style: TextStyle(
                color: AppColors.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select or create a team from the dropdown above',
              style: TextStyle(color: AppColors.muted, fontSize: 14),
            ),
          ],
        ),
      );
    }

    // ── Determine user's role in this team ──────────────────────
    final String currentUid = AuthService().currentUser!.uid;
    final bool isLeader = currentUid == team.leaderId;

    return Scaffold(
      appBar: AppBar(
        title: Text(team.name),
        centerTitle: false,
        actions: const [TeamSwitcherDropdown(), SizedBox(width: 16)],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Team info header card ─────────────────────────────
          _buildTeamInfoCard(team, teamState.members.length),

          const SizedBox(height: 8),

          // ── Members section heading ───────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text(
                  'Members',
                  style: TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${teamState.members.length})',
                  style: const TextStyle(color: AppColors.muted, fontSize: 14),
                ),
              ],
            ),
          ),

          // ── Member list with task stats ───────────────────────
          Expanded(
            child: StreamBuilder<List<Task>>(
              // Watch all tasks in this project so we can compute per-member stats
              stream: _teamService.watchTasks(team.id),
              builder: (context, taskSnap) {
                final tasks = taskSnap.data ?? [];

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: teamState.members.length,
                  itemBuilder: (context, index) {
                    final TeamMember member = teamState.members[index];
                    final stats = TeamService.computeTaskStats(
                      tasks,
                      member.uid,
                    );

                    return MemberCard(
                      member: member,
                      isLeader: member.role == 'leader',
                      taskStats: stats,
                    );
                  },
                );
              },
            ),
          ),

          // ── Action buttons (leader vs non-leader) ─────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: isLeader ? _buildLeaderButtons() : _buildMemberButtons(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Team info card ───────────────────────────────────────────────

  Widget _buildTeamInfoCard(Team team, int memberCount) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Member count
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$memberCount',
                style: const TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Members',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(width: 24),

          // Join code (shareable)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Join Code',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      team.joinCode,
                      style: const TextStyle(
                        color: AppColors.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Leader buttons ───────────────────────────────────────────────

  Widget _buildLeaderButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const AddMemberSheet(),
              );
            },
            icon: const Icon(Icons.person_add, size: 18),
            label: const Text('Add New Teammate'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _confirmDeleteTeam,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent),
            ),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Delete Team'),
          ),
        ),
      ],
    );
  }

  void _confirmDeleteTeam() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Team'),
        content: const Text(
          'This will permanently delete the team, all members, '
          'and all tasks. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final error = await context.read<TeamState>().deleteTeam();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error ?? 'Team deleted'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ── Non-leader buttons ───────────────────────────────────────────

  Widget _buildMemberButtons() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          final user = AuthService().currentUser;
          if (user == null) return;

          context.read<TeamState>().sendJoinRequest(
            user.uid,
            user.email?.split('@').first ?? 'Member',
            user.email ?? '',
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Team leader has been notified'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        icon: const Icon(Icons.notification_add, size: 18),
        label: const Text('Notify Team Leader'),
      ),
    );
  }
}
