import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/task.dart';
import '../../../state/team_state.dart';
import '../services/firestore_service.dart';

class AddTaskSheet extends StatefulWidget {
  final String projectId;
  final String initialStatus;
  final Task? editTask; // null = create, non-null = edit

  const AddTaskSheet({
    super.key,
    required this.projectId,
    required this.initialStatus,
    this.editTask,
  });

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();

  late String _title;
  late String _description;
  late String _priority;
  late String _teamName;
  DateTime? _deadline;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    //prefill if editing
    _title = widget.editTask?.title ?? '';
    _description = widget.editTask?.description ?? '';
    _priority = widget.editTask?.priority ?? 'medium';
    _deadline = widget.editTask?.deadline;
    //read team name once when sheet opens, not during build
    _teamName = context.read<TeamState>().currentTeam?.name ?? 'Unknown Team';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      if (widget.editTask != null) {
        await _firestoreService.updateTask(
          widget.projectId,
          widget.editTask!.id,
          {
            'title': _title,
            'description': _description,
            'priority': _priority,
            'deadline': _deadline,
          },
        );
      } else {
        final uid = FirebaseAuth.instance.currentUser!.uid;
        final task = Task(
          id: '',
          title: _title,
          description: _description,
          status: widget.initialStatus,
          priority: _priority,
          assigneeId: uid,
          deadline: _deadline,
          createdAt: DateTime.now(),
        );
        await _firestoreService.addTask(widget.projectId, task);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Something went wrong: $e')),
        );
      }
    }
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _deadline = picked);
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

                  //tick button to submits the form
                  GestureDetector(
                    onTap: _isLoading ? null : _submit,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: _isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.background,
                              ),
                            )
                          : const Icon(Icons.check,
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
                child: Row(
                  children: [
                    //priority buttons
                    _PriorityButton(
                      label: 'Low',
                      color: const Color(0xFF4DC98A),
                      selected: _priority == 'low',
                      onTap: () => setState(() => _priority = 'low'),
                    ),
                    const SizedBox(width: 8),
                    _PriorityButton(
                      label: 'Medium',
                      color: const Color(0xFFE8A44A),
                      selected: _priority == 'medium',
                      onTap: () => setState(() => _priority = 'medium'),
                    ),
                    const SizedBox(width: 8),
                    _PriorityButton(
                      label: 'High',
                      color: const Color(0xFFFF8585),
                      selected: _priority == 'high',
                      onTap: () => setState(() => _priority = 'high'),
                    ),

                    const Spacer(),

                    //deadline picker
                    GestureDetector(
                      onTap: _pickDeadline,
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
                  ],
                ),
              ),

            ],
          ),
        ),
    );
  }
}

//small priority toggle button
class _PriorityButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _PriorityButton({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : AppColors.muted,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
