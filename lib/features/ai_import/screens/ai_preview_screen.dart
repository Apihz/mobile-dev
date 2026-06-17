import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/task.dart';
import '../../../models/team_member.dart';
import '../../../state/team_state.dart';
import '../../board/services/firestore_service.dart';

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
class _EditTaskSheet extends StatefulWidget {
  final Task task;
  final List<TeamMember> members;

  const _EditTaskSheet({required this.task, required this.members});

  @override
  State<_EditTaskSheet> createState() => _EditTaskSheetState();
}

class _EditTaskSheetState extends State<_EditTaskSheet> {
  late TextEditingController _title;
  late TextEditingController _description;
  late String _priority;
  late String? _assigneeId;
  late DateTime? _startDate;
  late DateTime? _deadline;
  late List<String> _subtasks;
  static final _ymd = DateFormat('d MMM yyyy');

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.task.title);
    _description = TextEditingController(text: widget.task.description);
    _priority = widget.task.priority;
    _assigneeId = widget.task.assigneeId;
    _startDate = widget.task.startDate;
    _deadline = widget.task.deadline;
    _subtasks = List<String>.from(widget.task.subtasks);
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final base = isStart ? _startDate : _deadline;
    final picked = await showDatePicker(
      context: context,
      initialDate: base ?? DateTime.now(),
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
    Navigator.pop(
      context,
      widget.task.copyWith(
        title: _title.text.trim(),
        description: _description.text.trim(),
        priority: _priority,
        assigneeId: _assigneeId,
        startDate: _startDate,
        deadline: _deadline,
        subtasks: _subtasks.where((s) => s.trim().isNotEmpty).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, 16 + MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: AppColors.muted),
              ),
              const Spacer(),
              const Text('Edit task',
                  style: TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              IconButton(
                onPressed: _save,
                icon: const Icon(Icons.check, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: [
                _field('Title', _title),
                const SizedBox(height: 12),
                _field('Description', _description, maxLines: 3),
                const SizedBox(height: 16),
                const Text('Priority',
                    style: TextStyle(color: AppColors.muted, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: ['low', 'medium', 'high'].map((p) {
                    final selected = _priority == p;
                    final color = TaskColors.priority(p);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(p),
                        selected: selected,
                        selectedColor: color.withValues(alpha: 0.2),
                        onSelected: (_) => setState(() => _priority = p),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _dateButton(
                          'Start',
                          _startDate == null ? '—' : _ymd.format(_startDate!),
                          () => _pickDate(isStart: true)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _dateButton(
                          'Deadline',
                          _deadline == null ? '—' : _ymd.format(_deadline!),
                          () => _pickDate(isStart: false)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Assignee',
                    style: TextStyle(color: AppColors.muted, fontSize: 13)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  initialValue: _assigneeId,
                  dropdownColor: AppColors.surfaceElevated,
                  decoration: _inputDecoration(),
                  items: [
                    const DropdownMenuItem<String?>(
                        value: null, child: Text('Unassigned')),
                    ...widget.members.map((m) => DropdownMenuItem<String?>(
                          value: m.uid,
                          child: Text(m.name),
                        )),
                  ],
                  onChanged: (v) => setState(() => _assigneeId = v),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Subtasks',
                        style: TextStyle(color: AppColors.muted, fontSize: 13)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => setState(() => _subtasks.add('')),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                ..._subtasks.asMap().entries.map((e) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: e.value,
                            style: const TextStyle(color: AppColors.onSurface),
                            decoration: _inputDecoration(hint: 'Subtask'),
                            onChanged: (v) => _subtasks[e.key] = v,
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              setState(() => _subtasks.removeAt(e.key)),
                          icon: const Icon(Icons.close,
                              size: 18, color: AppColors.muted),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: AppColors.onSurface),
          decoration: _inputDecoration(),
        ),
      ],
    );
  }

  Widget _dateButton(String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: AppColors.muted, fontSize: 11)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    color: AppColors.onSurface, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.muted),
      isDense: true,
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
    );
  }
}
