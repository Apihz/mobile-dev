import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final void Function()? onTap;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:EdgeInsets.symmetric(horizontal:12,vertical:12),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 23, 24, 26),
          borderRadius: BorderRadius.circular(16),
          // border:Border.all(
          //   color: AppColors.onSurface.withValues(alpha: 0.1),
          // ) 
        ),
        child:
        Column(
          crossAxisAlignment:CrossAxisAlignment.start,
          children:[
            //priority badge
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
            const SizedBox(height: 12),
            Text(
              task.title,
              style: const TextStyle(
                color: AppColors.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
             Text(
              task.description,
              maxLines:2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.onSurface,
                fontSize: 10,
                fontWeight: FontWeight.w300,
                height: 1.3,
              ),
            ),
            
            const SizedBox(height: 20),


            if (task.deadline != null)
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
          ]
          )
        ),
    );
  }
}
