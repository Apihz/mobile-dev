import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/task.dart';
import '../../../models/team_member.dart';
import '../../../state/team_state.dart';
import '../../board/services/firestore_service.dart';
import '../../board/widgets/option_picker_dialog.dart';

/// Review/edit the AI-proposed tasks before saving them to the board.
class AiPreviewScreen extends StatefulWidget {
  final String projectId;
  final List<Task> tasks;

  const AiPreviewScreen({
    super.key,
    required this.projectId,
    required this.tasks,
  });

  @override
  State<AiPreviewScreen> createState() => _AiPreviewScreenState();
}

class _AiPreviewScreenState extends State<AiPreviewScreen> {
  late List<Task> _tasks;
  final _firestore = FirestoreService();
  static final _ymd = DateFormat('d MMM');
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tasks = List<Task>.from(widget.tasks);
  }

  String _assigneeName(String? uid, List<TeamMember> members) {
    if (uid == null) return 'Unassigned';
    for (final m in members) {
      if (m.uid == uid) return m.name;
    }
    return 'Unassigned';
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await _firestore.addTasksBatch(widget.projectId, _tasks);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added ${_tasks.length} tasks to the board')),
      );
      Navigator.pop(context); // pop preview
      Navigator.pop(context); // pop import screen → back to board
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not save: $e')));
      }
    }
  }

  Future<void> _editTask(int index) async {
    final members = context.read<TeamState>().members;
    final updated = await showModalBottomSheet<Task>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditTaskSheet(task: _tasks[index], members: members),
    );
    if (updated != null) setState(() => _tasks[index] = updated);
  }

  @override
  Widget build(BuildContext context) {
    final members = context.watch<TeamState>().members;

    return Scaffold(
      appBar: AppBar(title: Text('Review tasks (${_tasks.length})')),
      body: _tasks.isEmpty
          ? const Center(
              child: Text('No tasks left',
                  style: TextStyle(color: AppColors.muted)),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _tasks.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final t = _tasks[i];
                return Dismissible(
                  key: ValueKey('${t.title}-$i'),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => setState(() => _tasks.removeAt(i)),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3E1F22),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete_outline,
                        color: Color(0xFFFF8585)),
                  ),
                  child: _PreviewCard(
                    task: t,
                    assigneeName: _assigneeName(t.assigneeId, members),
                    dateLabel: t.startDate != null && t.deadline != null
                        ? '${_ymd.format(t.startDate!)} → ${_ymd.format(t.deadline!)}'
                        : null,
                    onTap: () => _editTask(i),
                  ),
                );
              },
            ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
        child: FilledButton.icon(
          onPressed: (_isSaving || _tasks.isEmpty) ? null : _save,
          icon: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          label: Text(_isSaving
              ? 'Saving...'
              : 'Add all to board (${_tasks.length})'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final Task task;
  final String assigneeName;
  final String? dateLabel;
  final VoidCallback onTap;

  const _PreviewCard({
    required this.task,
    required this.assigneeName,
    required this.dateLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _PriorityChip(priority: task.priority),
                const Spacer(),
                const Icon(Icons.edit_outlined,
                    size: 16, color: AppColors.muted),
              ],
            ),
            const SizedBox(height: 10),
            Text(task.title,
                style: const TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(task.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13)),
            ],
            if (task.subtasks.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('${task.subtasks.length} subtasks',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (dateLabel != null)
                  _MetaChip(icon: Icons.calendar_today_outlined, label: dateLabel!),
                _MetaChip(icon: Icons.person_outline, label: assigneeName),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  final String priority;
  const _PriorityChip({required this.priority});

  @override
  Widget build(BuildContext context) {
    final color = TaskColors.priority(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(priority.toUpperCase(),
          style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5)),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.muted),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(color: AppColors.muted, fontSize: 12)),
      ],
    );
  }
}

/// Bottom sheet to edit a single proposed task.
/// Mirrors the look of the board's [AddTaskSheet] so editing an AI task
/// feels identical to editing a real one.
class _EditTaskSheet extends StatefulWidget {
  final Task task;
  final List<TeamMember> members;

  const _EditTaskSheet({required this.task, required this.members});

  @override
  State<_EditTaskSheet> createState() => _EditTaskSheetState();
}

class _EditTaskSheetState extends State<_EditTaskSheet> {
  final _formKey = GlobalKey<FormState>();

  late String _title;
  late String _description;
  String? _priority;
  late String? _assigneeId;
  DateTime? _startDate;
  DateTime? _deadline;
  late List<String> _subtasks;

  late String _teamName;

  @override
  void initState() {
    super.initState();
    _title = widget.task.title;
    _description = widget.task.description;
    _priority = widget.task.priority;
    _assigneeId = widget.task.assigneeId;
    _startDate = widget.task.startDate;
    _deadline = widget.task.deadline;
    _subtasks = List<String>.from(widget.task.subtasks);
    _teamName = context.read<TeamState>().currentTeam?.name ?? 'Unknown Team';
  }

  //find the name of the picked teammate to show on the pill
  String _assigneeName() {
    for (final m in widget.members) {
      if (m.uid == _assigneeId) return m.name;
    }
    return 'Unassigned';
  }

  //label shown on the priority pill
  String _priorityLabel() {
    if (_priority == null) return 'Priority';
    return _priority![0].toUpperCase() + _priority!.substring(1);
  }

  //pick which teammate the task goes to, using the blurred dialog
  Future<void> _pickAssignee() async {
    final options = widget.members
        .map((m) => PickerOption(
              value: m.uid,
              label: m.name,
              icon: Icons.person_outline,
            ))
        .toList();

    final picked = await OptionPickerDialog.show(
      context,
      title: 'Assign to',
      options: options,
      selectedValue: _assigneeId,
    );

    if (picked != null) setState(() => _assigneeId = picked);
  }

  //pick the priority using the blurred dialog
  Future<void> _pickPriority() async {
    final picked = await OptionPickerDialog.show(
      context,
      title: 'Priority',
      selectedValue: _priority,
      options: [
        PickerOption(value: 'low', label: 'Low', color: TaskColors.priority('low')),
        PickerOption(value: 'medium', label: 'Medium', color: TaskColors.priority('medium')),
        PickerOption(value: 'high', label: 'High', color: TaskColors.priority('high')),
      ],
    );

    if (picked != null) setState(() => _priority = picked);
  }

  Future<void> _pickDate({required bool isStart}) async {
    final base = isStart ? _startDate : _deadline;
    final picked = await showDatePicker(
      context: context,
      initialDate: base ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _deadline = picked;
      }
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    Navigator.pop(
      context,
      widget.task.copyWith(
        title: _title,
        description: _description,
        priority: _priority ?? 'medium',
        assigneeId: _assigneeId,
        startDate: _startDate,
        deadline: _deadline,
        subtasks: _subtasks.where((s) => s.trim().isNotEmpty).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                //X button — closes the sheet
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 55,
                    height: 55,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.close,
                        size: 22, color: AppColors.muted),
                  ),
                ),

                const Spacer(),

                //team badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.groups_outlined, size: 20, color: AppColors.muted),
                      const SizedBox(width: 8),
                      Text(
                        _teamName,
                        style: const TextStyle(
                          color: AppColors.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                //tick button to save the changes
                GestureDetector(
                  onTap: _save,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check,
                        size: 22, color: AppColors.background),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            //scrollable note area
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      initialValue: _title,
                      decoration: const InputDecoration(
                        hintText: 'Title',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: AppColors.muted),
                      ),
                      style: const TextStyle(
                        color: AppColors.onSurface,
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                      ),
                      autofocus: true,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                      onSaved: (value) => _title = value!.trim(),
                    ),

                    TextFormField(
                      initialValue: _description,
                      decoration: const InputDecoration(
                        hintText: 'Add description...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: AppColors.muted),
                      ),
                      style: const TextStyle(
                        color: AppColors.onSurface,
                        fontSize: 16,
                        height: 1.5,
                      ),
                      maxLines: null,
                      onSaved: (value) => _description = value?.trim() ?? '',
                    ),

                    //subtasks — kept from the AI flow, styled to match the sheet
                    if (_subtasks.isNotEmpty) const SizedBox(height: 16),
                    ..._subtasks.asMap().entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.check_box_outline_blank,
                                size: 18, color: AppColors.muted),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                initialValue: e.value,
                                style: const TextStyle(
                                    color: AppColors.onSurface, fontSize: 15),
                                decoration: const InputDecoration(
                                  hintText: 'Subtask',
                                  isDense: true,
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(color: AppColors.muted),
                                ),
                                onChanged: (v) => _subtasks[e.key] = v,
                              ),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _subtasks.removeAt(e.key)),
                              child: const Icon(Icons.close,
                                  size: 16, color: AppColors.muted),
                            ),
                          ],
                        ),
                      );
                    }),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => setState(() => _subtasks.add('')),
                        icon: const Icon(Icons.add, size: 16, color: AppColors.muted),
                        label: const Text('Add subtask',
                            style: TextStyle(color: AppColors.muted)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            //pinned bar that floats above keyboard
            Container(
              padding: EdgeInsets.only(
                top: 12,
                bottom: 18 + keyboardHeight,
              ),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              //scroll sideways so the pills never overflow the screen
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    //priority picker
                    GestureDetector(
                      onTap: _pickPriority,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.flag_outlined,
                              size: 14,
                              color: _priority == null
                                  ? AppColors.muted
                                  : TaskColors.priority(_priority!),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _priorityLabel(),
                              style: TextStyle(
                                color: _priority == null
                                    ? AppColors.muted
                                    : TaskColors.priority(_priority!),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    //start date picker
                    GestureDetector(
                      onTap: () => _pickDate(isStart: true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.play_arrow_outlined,
                                size: 14, color: AppColors.muted),
                            const SizedBox(width: 6),
                            Text(
                              _startDate != null
                                  ? '${_startDate!.day}/${_startDate!.month}'
                                  : 'Start',
                              style: TextStyle(
                                color: _startDate != null
                                    ? AppColors.onSurface
                                    : AppColors.muted,
                                fontSize: 13,
                              ),
                            ),
                            if (_startDate != null) ...[
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => setState(() => _startDate = null),
                                child: const Icon(Icons.close,
                                    size: 14, color: AppColors.muted),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    //deadline picker
                    GestureDetector(
                      onTap: () => _pickDate(isStart: false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                size: 14, color: AppColors.muted),
                            const SizedBox(width: 6),
                            Text(
                              _deadline != null
                                  ? '${_deadline!.day}/${_deadline!.month}'
                                  : 'Deadline',
                              style: TextStyle(
                                color: _deadline != null
                                    ? AppColors.onSurface
                                    : AppColors.muted,
                                fontSize: 13,
                              ),
                            ),
                            if (_deadline != null) ...[
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => setState(() => _deadline = null),
                                child: const Icon(Icons.close,
                                    size: 14, color: AppColors.muted),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    //assignee picker
                    GestureDetector(
                      onTap: widget.members.isEmpty ? null : _pickAssignee,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          //hug the content so the pill only takes the space it needs
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person_outline,
                                size: 14, color: AppColors.muted),
                            const SizedBox(width: 6),
                            Text(
                              _assigneeName(),
                              style: const TextStyle(
                                color: AppColors.onSurface,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down,
                                size: 16, color: AppColors.muted),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
