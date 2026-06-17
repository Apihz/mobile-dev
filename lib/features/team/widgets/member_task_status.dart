import 'package:flutter/material.dart';

// Renders a horizontal segmented bar showing task status distribution.
// Accepts a map of { 'done', 'doing', 'todo', 'overdue' } counts.
class MemberTaskStatus extends StatelessWidget {
  final Map<String, int> stats;

  const MemberTaskStatus({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final total = stats.values.fold<int>(0, (sum, v) => sum + v);
    if (total == 0) return const SizedBox.shrink();

    return Row(
      children: [
        _barSegment(stats['done'] ?? 0, total, const Color(0xFF4DC98A)),
        _barSegment(stats['doing'] ?? 0, total, const Color(0xFF6E9FFF)),
        _barSegment(stats['overdue'] ?? 0, total, const Color(0xFFFF8585)),
        _barSegment(stats['todo'] ?? 0, total, const Color.fromARGB(40, 255, 255, 255)),
      ],
    );
  }

  Widget _barSegment(int count, int total, Color color) {
    final fraction = total > 0 ? count / total : 0.0;
    if (fraction <= 0) return const SizedBox.shrink();
    return Expanded(
      flex: (fraction * 100).round().clamp(1, 100),
      child: Container(
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(5),
            bottomLeft: const Radius.circular(5),
          ),
        ),
      ),
    );
  }
}
