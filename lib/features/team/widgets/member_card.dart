import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/team_member.dart';

// Displays a single team member's info card with their role badge
// and a compact task progress bar (done / doing / overdue).
class MemberCard extends StatelessWidget {
  final TeamMember member;
  final bool isLeader;
  final Map<String, int> taskStats; // { 'done', 'doing', 'todo', 'overdue' }
  final VoidCallback? onTap;

  const MemberCard({
    super.key,
    required this.member,
    required this.isLeader,
    required this.taskStats,
    this.onTap,
  });

  // Generate a 2-character initial string from the member's name
  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  // Build the colored task status bar
  Widget _buildTaskBar() {
    final total = taskStats.values.fold<int>(0, (sum, v) => sum + v);
    if (total == 0) {
      return const Text(
        'No tasks assigned',
        style: TextStyle(fontSize: 11, color: AppColors.muted),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _segment(taskStats['done'] ?? 0, total, const Color(0xFF4DC98A)),
            _segment(taskStats['doing'] ?? 0, total, const Color(0xFF6E9FFF)),
            _segment(taskStats['overdue'] ?? 0, total, const Color(0xFFFF8585)),
            _segment(taskStats['todo'] ?? 0, total, AppColors.border),
          ],
        ),
        const SizedBox(height: 4),
        // Legend
        Wrap(
          spacing: 12,
          runSpacing: 2,
          children: [
            _legendDot(const Color(0xFF4DC98A), 'Done ${taskStats['done'] ?? 0}'),
            _legendDot(const Color(0xFF6E9FFF), 'Doing ${taskStats['doing'] ?? 0}'),
            _legendDot(const Color(0xFFFF8585), 'Overdue ${taskStats['overdue'] ?? 0}'),
          ],
        ),
      ],
    );
  }

  // A single colored segment of the task bar
  Widget _segment(int count, int total, Color color) {
    final fraction = total > 0 ? count / total : 0.0;
    if (fraction <= 0) return const SizedBox.shrink();
    return Expanded(
      flex: (fraction * 100).round().clamp(1, 100),
      child: Container(
        height: 6,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(3),
            bottomLeft: const Radius.circular(3),
          ),
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surfaceElevated,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar circle with initials
              CircleAvatar(
                radius: 22,
                backgroundColor:
                    isLeader ? const Color(0xFFE8A44A) : AppColors.border,
                child: Text(
                  _initials(member.name),
                  style: TextStyle(
                    color: isLeader ? Colors.black : AppColors.muted,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Name, email, role badge + task bar
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            member.name,
                            style: const TextStyle(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        // Role badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isLeader
                                ? const Color(0xFF3F2A18)
                                : AppColors.border.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isLeader ? 'Leader' : 'Member',
                            style: TextStyle(
                              fontSize: 11,
                              color: isLeader
                                  ? const Color(0xFFFFAA6B)
                                  : AppColors.muted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      member.email,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.muted),
                    ),
                    const SizedBox(height: 10),
                    _buildTaskBar(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
