import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../features/team/screens/create_team_screen.dart';
import '../../models/team.dart';
import '../../state/team_state.dart';

//shows the current team name and lets the user pick a different one
class TeamSwitcherDropdown extends StatelessWidget {
  const TeamSwitcherDropdown({super.key});

  // Show a dialog where the user enters a join code to join a team
  void _showJoinTeamDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        String? error;
        bool isLoading = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Join a Team'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Enter the join code shared by the team leader.',
                    style: TextStyle(fontSize: 13, color: AppColors.muted),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'Join code',
                      border: OutlineInputBorder(),
                      hintText: 'e.g. 123456',
                    ),
                    maxLength: 6,
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(error!,
                          style: const TextStyle(
                              color: Colors.red, fontSize: 13)),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed:
                      isLoading ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final code = controller.text.trim();
                          if (code.length < 6) {
                            setDialogState(() =>
                                error = 'Please enter a valid 6-digit code');
                            return;
                          }
                          setDialogState(() {
                            isLoading = true;
                            error = null;
                          });
                          final result = await context
                              .read<TeamState>()
                              .joinByCode(code);
                          if (!dialogContext.mounted) return;
                          if (result != null) {
                            setDialogState(() {
                              error = result;
                              isLoading = false;
                            });
                          } else {
                            Navigator.pop(dialogContext);
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Join'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openTeamSheet(BuildContext context, TeamState teamState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              //drag handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 46,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Your teams',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
              //list of teams
              ...teamState.teams.map((Team team) {
                bool isCurrent = team == teamState.currentTeam;
                return ListTile(
                  title: Text(
                    team.name,
                    style: TextStyle(
                      color: isCurrent ? AppColors.onSurface : AppColors.primaryMuted,
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  trailing: isCurrent
                      ? const Icon(Icons.check, color: AppColors.onSurface, size: 18)
                      : null,
                  onTap: () {
                    context.read<TeamState>().selectTeam(team);
                    Navigator.pop(sheetContext);
                  },
                );
              }),
              Divider(color: AppColors.border, height: 1),
              //create new team option
              ListTile(
                leading: const Icon(Icons.add, color: AppColors.muted, size: 20),
                title: const Text(
                  'Create new team',
                  style: TextStyle(color: AppColors.muted),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateTeamScreen()),
                  );
                },
              ),
              //join existing team option
              ListTile(
                leading: const Icon(Icons.login, color: AppColors.muted, size: 20),
                title: const Text(
                  'Join existing team',
                  style: TextStyle(color: AppColors.muted),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showJoinTeamDialog(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    TeamState teamState = context.watch<TeamState>();

    if (teamState.isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (teamState.teams.isEmpty) {
      return const Text('No teams yet');
    }

    return GestureDetector(
      onTap: () => _openTeamSheet(context, teamState),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            teamState.currentTeam?.name ?? '',
            style: const TextStyle(
              color: AppColors.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(width: 2),
          Transform.translate(
            offset: const Offset(0, -1),
            child: const Icon(Icons.keyboard_arrow_down, color: AppColors.muted, size: 20),
          ),
        ],
        ),
      ),
    );
  }
}
