import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/team_switcher_dropdown.dart';
import '../../../state/team_state.dart';
import '../../team/screens/create_team_screen.dart';

class BoardScreen extends StatelessWidget {
  const BoardScreen({super.key});

  static const List<_SampleTicket> _samples = [
    _SampleTicket(
      title: 'Literature review draft',
      subject: 'CSCI 4311',
      due: 'Due Fri',
      color: TicketColors.purple,
    ),
    _SampleTicket(
      title: 'Wireframes for Board screen',
      subject: 'Design',
      due: 'Due Sun',
      color: TicketColors.blue,
    ),
    _SampleTicket(
      title: 'Set up Supabase schema',
      subject: 'Backend',
      due: 'Due Mon',
      color: TicketColors.green,
    ),
    _SampleTicket(
      title: 'Demo rehearsal slides',
      subject: 'Presentation',
      due: 'Next week',
      color: TicketColors.orange,
    ),
    _SampleTicket(
      title: 'Push notification spike',
      subject: 'Research',
      due: 'No deadline',
      color: TicketColors.pink,
    ),
  ];

  void _goToCreateTeam(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateTeamScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    TeamState teamState = context.watch<TeamState>();

    Widget body;

    if (teamState.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (teamState.teams.isEmpty) {
      //no teams yet, show a prompt to create one
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
              onPressed: () => _goToCreateTeam(context),
              icon: const Icon(Icons.add),
              label: const Text('Create Team'),
            ),
          ],
        ),
      );
    } else {
      //team selected — show the board
      body = ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _samples.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _TicketCard(ticket: _samples[i]),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Board'),
        actions: [
          const TeamSwitcherDropdown(),
          const SizedBox(width: 20),
        ],
      ),
      body: body,
    );
  }
}

class _SampleTicket {
  final String title;
  final String subject;
  final String due;
  final TicketColor color;

  const _SampleTicket({
    required this.title,
    required this.subject,
    required this.due,
    required this.color,
  });
}

class _TicketCard extends StatelessWidget {
  final _SampleTicket ticket;

  const _TicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SubjectChip(color: ticket.color, label: ticket.subject),
              const Spacer(),
              Text(
                ticket.due,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            ticket.title,
            style: const TextStyle(
              color: AppColors.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectChip extends StatelessWidget {
  final TicketColor color;
  final String label;

  const _SubjectChip({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color.foreground,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}
