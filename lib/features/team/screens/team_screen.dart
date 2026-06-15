import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expansion_card/expansion_card.dart';

import '../../../core/constants/app_colors.dart';
import '../../../features/auth/services/auth_service.dart';
import '../../team/screens/create_team_screen.dart';
import '../services/firestore_service.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Team Lists,')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            margin: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              children: [
                Text(
                  'Member 1',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Description of Team A goes here.'),
                ),
                ListTile(title: Text('Name: John Doe')),
                ListTile(title: Text('Role: Project Manager')),
                ListTile(title: Text('Email: johndoe@example.com')),
                ListTile(title: Text('Phone: (123) 456-7890')),
                SizedBox(height: 16),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreateTeamScreen()),
              );
            },
            child: Text('Add New Teammate'),
          ),
        ],
      ),
    );
  }
}
