import 'package:flutter/material.dart';

import '../../../shared/widgets/team_switcher_dropdown.dart';

class PlannerScreen extends StatelessWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planner'),
        actions: [
          const TeamSwitcherDropdown(),
          const SizedBox(width: 8),
        ],
      ),
      body: const Center(child: Text('Planner coming soon')),
    );
  }
}
