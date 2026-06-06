import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../features/team/screens/create_team_screen.dart';
import '../../models/team.dart';
import '../../state/team_state.dart';

//shows the current team name and lets the user pick a different one
class TeamSwitcherDropdown extends StatelessWidget {
  const TeamSwitcherDropdown({super.key});

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
