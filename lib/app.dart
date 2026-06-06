import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/screens/welcome_screen.dart';
import 'shared/widgets/app_scaffold.dart';
import 'state/team_state.dart';

class KanbanBoardApp extends StatelessWidget {
  const KanbanBoardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TeamState(),
      child: MaterialApp(
        title: 'KanbanBoard',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        //listen to auth state, show app if logged in, welcome screen if not
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasData) {
              return const AppScaffold();
            }
            //reset team state when user logs out
            context.read<TeamState>().reset();
            return const WelcomeScreen();
          },
        ),
      ),
    );
  }
}
