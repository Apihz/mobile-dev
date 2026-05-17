import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// PlannerScreen maps directly to the feature structure defined in the project architecture.
/// It displays a scroll-optimized list of planner task items.
class PlannerScreen extends StatelessWidget {
  const PlannerScreen({super.key});

  // Explicit sample list utilizing the project design tokens [cite: 605, 921]
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planner'),
        centerTitle: true, // Standard Material layout design [cite: 184, 271]
      ),
      // Handout optimization: builds rendering nodes strictly for visible items [cite: 583, 584]
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _samples.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _TicketCard(ticket: _samples[index]),
      ),
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