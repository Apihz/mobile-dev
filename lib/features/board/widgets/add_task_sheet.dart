import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/task.dart';
import '../../../models/team_member.dart';
import '../../../state/team_state.dart';
import '../services/firestore_service.dart';
import 'option_picker_dialog.dart';

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
  String? _priority; //null until the user picks one
  late String _teamName;
  DateTime? _deadline;
  bool _isLoading = false;

  //team members we can assign this task to, and who is picked
  List<TeamMember> _members = [];
  String? _assigneeId;

  @override
  void initState() {
    super.initState();
    //prefill if editing
    _title = widget.editTask?.title ?? '';
    _description = widget.editTask?.description ?? '';
    _priority = widget.editTask?.priority;
    _deadline = widget.editTask?.deadline;
    //read team info once when sheet opens
    final teamState = context.read<TeamState>();
    _teamName = teamState.currentTeam?.name ?? 'Unknown Team';
    _members = teamState.members;
    //default the assignee to the current user when creating a new task
    _assigneeId = widget.editTask?.assigneeId ??
        FirebaseAuth.instance.currentUser!.uid;
  }

  //find the name of the picked teammate to show on the button
  String _assigneeName() {
    for (final m in _members) {
      if (m.uid == _assigneeId) return m.name;
    }
    return 'Unassigned';
  }

  //pick which teammate the task goes to, using the blurred dialog
  Future<void> _pickAssignee() async {
    final options = _members
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
            'priority': _priority ?? 'medium',
            'deadline': _deadline,
            'assigneeId': _assigneeId,
          },
        );
      } else {
        final task = Task(
          id: '',
          title: _title,
          description: _description,
          status: widget.initialStatus,
          priority: _priority ?? 'medium',
          assigneeId: _assigneeId,
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

  //label shown on the priority chip
  String _priorityLabel() {
    if (_priority == null) return 'Priority';
    return _priority![0].toUpperCase() + _priority!.substring(1);
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
                //scroll sideways so the pills never overflow the screen if name it stoo long
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

                    const SizedBox(width: 8),

                    //assignee picker
                      GestureDetector(
                        onTap: _members.isEmpty ? null : _pickAssignee,
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
