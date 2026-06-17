import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

// Absolute Package Imports matching your pubspec layout name
import 'package:flutter_app_1/models/task.dart';
import 'package:flutter_app_1/state/team_state.dart';
import 'package:flutter_app_1/features/board/services/firestore_service.dart';
import 'package:flutter_app_1/features/board/screens/task_detail_screen.dart';
import 'package:flutter_app_1/features/board/widgets/add_task_sheet.dart';
// Integrated your shared interactive workspace components
import 'package:flutter_app_1/shared/widgets/team_switcher_dropdown.dart'; 

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Exact color values mapped directly from your group's design specifications
  static const Color specBackground = Color(0xFF131315); // background
  static const Color specSurface = Color(0xFF131315);    // surface
  static const Color specCardBg = Color(0xFF0E0E10);      // surface-container-lowest
  static const Color specPrimaryText = Color(0xFFC0C1FF);  // primary
  static const Color specButtonColor = Color(0xFF5B5FEF);  // primary-container
  static const Color specBadgeGreen = Color(0xFF4EDEA3);   // secondary
  static const Color specMutedText = Color(0xFFC6C5D7);    // on-surface-variant
  static const Color specBorder = Color(0xFF353437);       // surface-container-highest
  static const Color specError = Color(0xFFFFB4AB);        // error

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final teamState = context.watch<TeamState>();
    final currentUser = FirebaseAuth.instance.currentUser;

    if (teamState.isLoading) {
      return const Scaffold(
        backgroundColor: specBackground,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(specPrimaryText),
          ),
        ),
      );
    }

    if (teamState.currentTeam == null) {
      return Scaffold(
        backgroundColor: specBackground,
        appBar: AppBar(
          backgroundColor: specBackground,
          elevation: 0,
          toolbarHeight: 70,
          title: Text(
            'Daily Planner',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24, 
              fontWeight: FontWeight.w700, 
              color: Colors.white
            ),
          ),
          actions: const [
            TeamSwitcherDropdown(),
            SizedBox(width: 16),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_today_outlined, size: 64, color: specMutedText),
              const SizedBox(height: 16),
              Text(
                'No team context selected',
                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Select a team workspace to view assignment schedules.',
                style: GoogleFonts.plusJakartaSans(color: specMutedText, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    final String projectId = teamState.currentTeam!.id;
    final FirestoreService service = FirestoreService();

    return Scaffold(
      backgroundColor: specBackground,
      appBar: AppBar(
        backgroundColor: specBackground,
        elevation: 0,
        toolbarHeight: 70,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Daily Planner',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22, 
                fontWeight: FontWeight.w700, 
                color: Colors.white, 
                letterSpacing: -0.5
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Track upcoming deadlines',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12, 
                color: specMutedText, 
                fontWeight: FontWeight.w400
              ),
            ),
          ],
        ),
        actions: const [
          // Embedded your functional workspace management switch drop panel
          TeamSwitcherDropdown(),
          SizedBox(width: 16),
        ],
      ),
      body: StreamBuilder<List<Task>>(
        stream: service.watchTasks(projectId), //
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(specPrimaryText),
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load timeline schedule.',
                style: GoogleFonts.plusJakartaSans(color: specMutedText),
              ),
            );
          }

          final List<Task> allTasks = snapshot.data ?? [];
          final List<Task> myTasks = allTasks.where((task) {
            bool isMine = task.assigneeId == currentUser?.uid || task.assigneeId == null;
            return task.deadline != null && task.status != 'done' && isMine;
          }).toList();

          final DateTime today = DateTime.now();
          final DateTime todayDateOnly = DateTime(today.year, today.month, today.day);
          
          List<Task> overdueTasks = [];
          List<Task> todayTasks = [];
          List<Task> upcomingTasks = [];

          for (var task in myTasks) {
            final taskDate = DateTime(task.deadline!.year, task.deadline!.month, task.deadline!.day);
            final int daysLeft = taskDate.difference(todayDateOnly).inDays;

            if (daysLeft < 0) {
              overdueTasks.add(task);
            } else if (daysLeft == 0) {
              todayTasks.add(task);
            } else {
              upcomingTasks.add(task);
            }
          }

          overdueTasks.sort((a, b) => a.deadline!.compareTo(b.deadline!));
          todayTasks.sort((a, b) => a.deadline!.compareTo(b.deadline!));
          upcomingTasks.sort((a, b) => a.deadline!.compareTo(b.deadline!));

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- CALENDAR CARD DISPLAY ---
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: specSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: specBorder, width: 1),
                  ),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    calendarFormat: CalendarFormat.month,
                    rowHeight: 44,
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: false,
                      leftChevronIcon: const Icon(Icons.chevron_left, color: specMutedText, size: 20),
                      rightChevronIcon: const Icon(Icons.chevron_right, color: specMutedText, size: 20),
                      titleTextStyle: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: GoogleFonts.plusJakartaSans(color: specMutedText, fontSize: 12, fontWeight: FontWeight.w700),
                      weekendStyle: GoogleFonts.plusJakartaSans(color: specMutedText, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    calendarStyle: CalendarStyle(
                      defaultTextStyle: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13),
                      weekendTextStyle: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13),
                      outsideDaysVisible: false,
                      todayDecoration: BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      todayTextStyle: GoogleFonts.plusJakartaSans(color: specError, fontWeight: FontWeight.bold, fontSize: 13),
                      selectedDecoration: BoxDecoration(
                        color: specButtonColor,
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: specButtonColor.withOpacity(0.4),
                            blurRadius: 12,
                          )
                        ]
                      ),
                      selectedTextStyle: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      markerSize: 4,
                      markersAnchor: 4.0,
                      markerDecoration: const BoxDecoration(
                        color: specBadgeGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    eventLoader: (day) {
                      return myTasks.where((task) => isSameDay(task.deadline, day)).toList();
                    },
                  ),
                ),

                // --- TASKS GROUPS CONTAINER ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: myTasks.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(top: 40, bottom: 40),
                          child: _buildEmptyState(),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (overdueTasks.isNotEmpty) ...[
                              _buildSectionHeader("OVERDUE", Icons.warning_amber_rounded, specError),
                              ...overdueTasks.map((task) => _buildPlannerCard(context, task, projectId, isOverdue: true)),
                              const SizedBox(height: 20),
                            ],
                            if (todayTasks.isNotEmpty) ...[
                              _buildSectionHeader("TODAY", Icons.calendar_today, specPrimaryText),
                              ...todayTasks.map((task) => _buildPlannerCard(context, task, projectId)),
                              const SizedBox(height: 20),
                            ],
                            if (upcomingTasks.isNotEmpty) ...[
                              _buildSectionHeader("UPCOMING", Icons.upcoming, specMutedText),
                              ...upcomingTasks.map((task) => _buildPlannerCard(context, task, projectId, isUpcoming: true)),
                              const SizedBox(height: 30),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
      // Transformed the action layout to match BoardScreen using full Floating Action Buttons
      floatingActionButton: teamState.currentTeam != null
          ? FloatingActionButton(
              backgroundColor: specButtonColor,
              foregroundColor: Colors.white,
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => AddTaskSheet(
                    projectId: projectId,
                    initialStatus: 'todo', //
                  ),
                );
              },
              child: const Icon(Icons.add, size: 24),
            )
          : null,
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: color, letterSpacing: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.assignment_turned_in_outlined, size: 48, color: specPrimaryText),
          const SizedBox(height: 16),
          Text(
            'All caught up!',
            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'No pending deadlines or tasks found.',
            style: GoogleFonts.plusJakartaSans(color: specMutedText, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildPlannerCard(BuildContext context, Task task, String projectId, {bool isOverdue = false, bool isUpcoming = false}) {
    final String formattedDate = isOverdue 
        ? 'Yesterday, 11:59 PM' 
        : DateFormat('EEE, d MMM').format(task.deadline!);

    Color borderAccent = specBorder;
    Color cardBg = specCardBg;

    if (isOverdue) {
      borderAccent = specError.withOpacity(0.4);
    } else if (!isUpcoming) {
      cardBg = specButtonColor.withOpacity(0.04);
      borderAccent = specButtonColor.withOpacity(0.3);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderAccent, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (isOverdue)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 4,
              child: Container(color: specError),
            ),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TaskDetailScreen(task: task, projectId: projectId), //
                ),
              );
            },
            child: Padding(
              padding: EdgeInsets.fromLTRB(isOverdue ? 18 : 14, 16, 14, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2, right: 12),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: specBorder, width: 2),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                task.title,
                                style: GoogleFonts.plusJakartaSans(
                                  color: isUpcoming ? Colors.white.withOpacity(0.6) : Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isOverdue 
                                    ? specBorder.withOpacity(0.2)
                                    : specBadgeGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isOverdue 
                                      ? specBorder
                                      : specBadgeGreen.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                task.priority.toUpperCase(),
                                style: GoogleFonts.plusJakartaSans(
                                  color: isOverdue ? specMutedText : specBadgeGreen,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              isOverdue ? Icons.event : Icons.schedule, 
                              size: 14, 
                              color: isOverdue ? specError : specMutedText
                            ),
                            const SizedBox(width: 5),
                            Text(
                              formattedDate,
                              style: GoogleFonts.plusJakartaSans(
                                color: isOverdue ? specError : specMutedText, 
                                fontSize: 13,
                                fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}