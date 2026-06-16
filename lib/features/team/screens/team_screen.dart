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
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Your Team List',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Member 1',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Description of Team A goes here.'),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Container(
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: AppColors.muted,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                margin: EdgeInsets.only(left: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Name: John Doe'),
                    SizedBox(height: 8),
                    Text('Role: Project Manager'),
                    SizedBox(height: 8),
                    Text('Email: johndoe@example.com'),
                    SizedBox(height: 8),
                    Text('Phone: (123) 456-7890'),
                  ],
                ),
              ),
            ),
          ],
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
    );
  }
}
