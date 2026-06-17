import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/task.dart';
import 'task_card.dart';

class KanbanColumn extends StatefulWidget {
  final String status;
  final String title;
  final List<Task> tasks;
  final void Function(Task task, String newStatus) onTaskDropped;
  final VoidCallback onAddTask;
  final void Function(Task task) onTaskTap;
  //display options passed down from the board
  final bool showPriority;
  final bool showDescription;
  final bool showDeadline;
  final bool compact;
  //maps a member uid to their name, used to show who a task is assigned to
  final Map<String, String> memberNames;

  const KanbanColumn({
    super.key,
    required this.status,
    required this.title,
    required this.tasks,
    required this.onTaskDropped,
    required this.onAddTask,
    required this.onTaskTap,
    required this.showPriority,
    required this.showDescription,
    required this.showDeadline,
    required this.compact,
    required this.memberNames,
  });

  @override
  State<KanbanColumn> createState() => _KanbanColumnState();
}

class _KanbanColumnState extends State<KanbanColumn> {
  //track when a card is hovering over this column
  bool _isDragOver = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) {
        //only accept cards from a different column
        final willAccept = details.data.status != widget.status;
        setState(() => _isDragOver = willAccept);
        return willAccept;
      },
      onLeave: (_) => setState(() => _isDragOver = false),
      onAcceptWithDetails: (details) {
        setState(() => _isDragOver = false);
        widget.onTaskDropped(details.data, widget.status);
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 300,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            //highlight the column when a card is dragged over it
            color: _isDragOver
                ? TaskColors.status(widget.status).withValues(alpha: 0.08)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isDragOver ? TaskColors.status(widget.status) : AppColors.border,
              width: _isDragOver ? 1.5 : 0,
            ),
          ),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildTaskList()),
            ],
          ),
        );
      },
    );
  }
  

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
      child: Row(
        children: [
          //colored dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: TaskColors.status(widget.status),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),

          //column title
          Text(
            widget.title,
            style: const TextStyle(
              color: AppColors.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),

          //task count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${widget.tasks.length}',
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ),

          const Spacer(),

          //add task button
          GestureDetector(
            onTap: widget.onAddTask,
            child: const Icon(Icons.add, color: AppColors.muted, size: 18),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  //build a task card with the column's display options
  Widget _buildCard(Task task, {VoidCallback? onTap}) {
    //look up the assignee's name from their uid
    final String? assigneeName =
        task.assigneeId == null ? null : widget.memberNames[task.assigneeId];
    return TaskCard(
      task: task,
      onTap: onTap,
      showPriority: widget.showPriority,
      showDescription: widget.showDescription,
      showDeadline: widget.showDeadline,
      compact: widget.compact,
      assigneeName: assigneeName,
    );
  }

  Widget _buildTaskList() {
    if (widget.tasks.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: TaskColors.status(widget.status).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inbox_outlined,
              color: TaskColors.status(widget.status).withValues(alpha: 0.5),
              size: 20,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _isDragOver ? 'Drop here' : 'No tasks yet',
            style: TextStyle(
              color: _isDragOver ? TaskColors.status(widget.status) : AppColors.muted,
              fontSize: 13,
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(10),
      itemCount: widget.tasks.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final task = widget.tasks[index];
        return LongPressDraggable<Task>(
          data: task,
          //ghost card that follows the finger
          feedback: Material(
            color: Colors.transparent,
            child: Opacity(
              opacity: 0.9,
              child: SizedBox(width: 280, child: _buildCard(task)),
            ),
          ),
          //original card fades while being dragged
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: _buildCard(task),
          ),
          child: _buildCard(task, onTap: () => widget.onTaskTap(task)),
        );
      },
    );
  }
}
