import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/task.dart';
import '../widgets/add_task_sheet.dart';
import '../services/firestore_service.dart';


class TaskDetailScreen extends StatelessWidget {
  final Task task;
  final String projectId;
  
  const TaskDetailScreen({
    super.key,
    required this.task,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: PopupMenuButton<String>(
              color:AppColors.surfaceElevated,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppColors.border),
              ),
              icon: const Icon(Icons.more_horiz, size: 18),
              onSelected: (value) {
                if (value == 'edit') {
                  showModalBottomSheet(context: context, 
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => AddTaskSheet(projectId: projectId,initialStatus: task.status, editTask: task,));
                } else if (value == 'delete') {
                  showDialog(
                    context:context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppColors.surfaceElevated,
                      title:const Text('Delete task?',
                        style: TextStyle(color: AppColors.onSurface),
                      ),
                      content: const Text('This cannot be undone.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                      actions: [
                        TextButton(onPressed:() => 
                          Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        TextButton(onPressed:() async {
                          Navigator.pop(ctx);
                          await FirestoreService().deleteTask(projectId, task.id);
                          if(context.mounted) Navigator.pop(context);
                        }, 
                        child: const Text('Delete', style: TextStyle(color: Colors.red),))
                      ]
                      ));
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete', 
                style: TextStyle(color: Colors.red),)),
              ],
            ),
          ),
        ],
    ),
    body:SingleChildScrollView(padding:const EdgeInsets.all(20), 
    child: Column(
      crossAxisAlignment:CrossAxisAlignment.start,
      children: [
        Text(task.title,
          style: const TextStyle(
            color: AppColors.onSurface,
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 24),
        Row(children: [
          //status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: TaskColors.status(task.status).withValues(alpha:0.20),
              border: Border.all(color: TaskColors.status(task.status)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.circle, color: TaskColors.status(task.status), size: 14,),
                const SizedBox(width: 4),
                Text(task.status.toUpperCase(),
                style: TextStyle(
                  fontSize:12,
                  color: TaskColors.status(task.status),
                  fontWeight: FontWeight.w700,
                  
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
          SizedBox(width:12),
          //priority badge 
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: TaskColors.priority(task.priority).withValues(alpha:0.20),
              border: Border.all(color: TaskColors.priority(task.priority)),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              children: [
                Icon(Icons.flag_outlined, color: TaskColors.priority(task.priority), size: 14,),
                const SizedBox(width: 4),
                Text(task.priority.toUpperCase(),style: TextStyle(
                  fontSize:12,
                  color: TaskColors.priority(task.priority),
                  fontWeight: FontWeight.w700,)),
                const SizedBox(width: 4),
              ],
            ),
          ),
          SizedBox(width:12),
          //deadlije badge
          if(task.deadline != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryMuted.withValues(alpha:0.15),
                border: Border.all(color: AppColors.primaryMuted),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_month, color: AppColors.primary, size: 14,),
                  const SizedBox(width: 4),
                  Text('${task.deadline!.day}/${task.deadline!.month}/${task.deadline!.year}',
                  style:TextStyle(color: AppColors.primary,fontSize: 12,fontWeight: FontWeight.w700),),
                  const SizedBox(width: 4),
                ],
              ),
            ),   
        ],
        ),
        const SizedBox(height: 24),
        Text(task.description,
        style:TextStyle(
          color: AppColors.onSurface,
          fontSize: 16,
        ),
      ),   
    ],),
    ),
    );
  }
  
}


