import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final void Function()? onTap;
  //display options passed down from the board
  final bool showPriority;
  final bool showDescription;
  final bool showDeadline;
  final bool compact;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.showPriority = true,
    this.showDescription = true,
    this.showDeadline = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: compact ? 8 : 12,
        ),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 23, 24, 26),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //priority badge
            if (showPriority) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: TaskColors.priority(task.priority).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: TaskColors.priority(task.priority).withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  task.priority.toUpperCase(),
                  style: TextStyle(
                    color: TaskColors.priority(task.priority),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              SizedBox(height: compact ? 8 : 12),
            ],

            Text(
              task.title,
              style: const TextStyle(
                color: AppColors.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),

            //only show the description if turned on and the task has one
            if (showDescription && task.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                task.description,
                maxLines: compact ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 10,
                  fontWeight: FontWeight.w300,
                  height: 1.3,
                ),
              ),
            ],

            //only show the deadline if turned on and the task has one
            if (showDeadline && task.deadline != null) ...[
              SizedBox(height: compact ? 10 : 20),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.muted),
                  const SizedBox(width: 4),
                  Text(
                    'Due ${task.deadline!.day}/${task.deadline!.month}',
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
