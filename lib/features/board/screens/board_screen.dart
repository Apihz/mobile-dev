import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../features/auth/services/auth_service.dart';
import '../../../models/task.dart';
import '../../../shared/widgets/team_switcher_dropdown.dart';
import '../../../state/team_state.dart';
import '../../team/screens/create_team_screen.dart';
import '../services/firestore_service.dart';
import '../widgets/add_task_sheet.dart';
import '../widgets/kanban_column.dart';
import 'task_detail_screen.dart';

class BoardScreen extends StatelessWidget {
  const BoardScreen({super.key});

  String _getGreeting(String name) {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning, $name!';
    if (hour < 17) return 'Good Afternoon, $name!';
    if (hour < 20) return 'Good Evening, $name!';
    return 'Good Night, $name!';
  }

  Widget _buildColumn(
    BuildContext context,
    String projectId,
    FirestoreService service,
    String status,
    String title,
    List<Task> allTasks,
  ) {
    final columnTasks = allTasks.where((t) => t.status == status).toList();
    return SizedBox(
      height: MediaQuery.of(context).size.height - 200,
      child: KanbanColumn(
        status: status,
        title: title,
        tasks: columnTasks,
        onTaskDropped: (task, newStatus) {
          service.updateTaskStatus(projectId, task.id, newStatus);
        },
        onAddTask: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => AddTaskSheet(
              projectId: projectId,
              initialStatus: status,
            ),
          );
        },
        onTaskTap: (task) {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => TaskDetailScreen(task: task, projectId: projectId)
          ));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? user = AuthService().currentUser;
    final String displayName = user?.email?.split('@').first ?? 'there';
    final TeamState teamState = context.watch<TeamState>();

    Widget body;

    if (teamState.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (teamState.teams.isEmpty) {
      body = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.groups_outlined, size: 64, color: AppColors.muted),
            const SizedBox(height: 16),
            const Text(
              'No teams yet',
              style: TextStyle(
                color: AppColors.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a team to start tracking tasks',
              style: TextStyle(color: AppColors.muted, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateTeamScreen()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Create Team'),
            ),
          ],
        ),
      );
    } else {
      final String projectId = teamState.currentTeam!.id;
      final FirestoreService service = FirestoreService();

      body = StreamBuilder<List<Task>>(
        stream: service.watchTasks(projectId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Something went wrong',
                style: TextStyle(color: AppColors.muted),
              ),
            );
          }

          final List<Task> allTasks = snapshot.data ?? [];

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildColumn(context, projectId, service, 'todo',   'To Do',  allTasks),
                _buildColumn(context, projectId, service, 'doing',  'Doing',  allTasks),
                _buildColumn(context, projectId, service, 'done',   'Done',   allTasks),
              ],
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 90,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getGreeting(displayName),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Manage your tasks and projects',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          const TeamSwitcherDropdown(),
          const SizedBox(width: 20),
        ],
      ),
      body: body,
      //only show FAB when a team is selected
      floatingActionButton: teamState.currentTeam != null
          ? FloatingActionButton(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => AddTaskSheet(
                    projectId: teamState.currentTeam!.id,
                    initialStatus: 'todo',
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
