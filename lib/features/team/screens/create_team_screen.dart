import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../state/team_state.dart';

class CreateTeamScreen extends StatefulWidget {
  const CreateTeamScreen({super.key});

  @override
  State<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends State<CreateTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  String _teamName = '';
  bool _isLoading = false;
  String _errorMessage = '';

  // Invite members state
  final _inviteController = TextEditingController();
  final List<String> _invitedEmails = [];

  @override
  void dispose() {
    _inviteController.dispose();
    super.dispose();
  }

  // Add an email to the local invite list
  void _addInvite() {
    final email = _inviteController.text.trim();
    if (email.isEmpty) return;
    if (!email.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email');
      return;
    }
    if (_invitedEmails.contains(email)) {
      setState(() => _errorMessage = 'This email is already added');
      return;
    }
    setState(() {
      _invitedEmails.add(email);
      _inviteController.clear();
      _errorMessage = '';
    });
  }

  // Remove an email from the local invite list
  void _removeInvite(String email) {
    setState(() => _invitedEmails.remove(email));
  }

  Future<void> _createTeam() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Pass invited emails so they are stored as pending invites
      await context
          .read<TeamState>()
          .createTeam(_teamName, invitedEmails: _invitedEmails);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create a Team'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Give your team a name',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Team name',
                  border: OutlineInputBorder(),
                  hintText: 'e.g. CSCI 4311 Group A',
                ),
                autofocus: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a team name';
                  }
                  return null;
                },
                onSaved: (value) {
                  _teamName = value!.trim();
                },
              ),

              const SizedBox(height: 24),

              // ── Invite members section ──────────────────────────
              const Text(
                'Invite members (optional)',
                style: TextStyle(fontSize: 16, color: AppColors.onSurface),
              ),
              const SizedBox(height: 4),
              const Text(
                'Enter emails of people you want to invite. '
                'They will be able to join through the join code.',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inviteController,
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                        border: OutlineInputBorder(),
                        hintText: 'colleague@example.com',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      onSubmitted: (_) => _addInvite(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addInvite,
                    child: const Text('Add'),
                  ),
                ],
              ),

              // Show invited email chips
              if (_invitedEmails.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _invitedEmails.map((email) {
                    return Chip(
                      label: Text(email),
                      onDeleted: () => _removeInvite(email),
                    );
                  }).toList(),
                ),
              ],

              // Error message
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ],

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _createTeam,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Team'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
