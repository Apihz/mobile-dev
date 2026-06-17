import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:intl/intl.dart';

import '../../../models/task.dart';
import '../../../models/team_member.dart';

/// Uses Firebase AI Logic (Gemini Developer API, free Spark tier) to turn an
/// assignment/GP brief (PDF or pasted text) into a structured list of tasks.
class AiExtractService {
  static const String _modelId = 'gemini-2.5-flash';

  static final DateFormat _ymd = DateFormat('yyyy-MM-dd');

  GenerativeModel _model() {
    final schema = Schema.object(
      properties: {
        'tasks': Schema.array(
          items: Schema.object(
            properties: {
              'title': Schema.string(),
              'description': Schema.string(),
              'priority':
                  Schema.enumString(enumValues: ['low', 'medium', 'high']),
              'startDate': Schema.string(description: 'YYYY-MM-DD'),
              'deadline': Schema.string(description: 'YYYY-MM-DD'),
              'subtasks': Schema.array(items: Schema.string()),
              'suggestedAssignee': Schema.string(
                  description: 'one of the provided member names, or empty'),
            },
            optionalProperties: ['suggestedAssignee'],
          ),
        ),
      },
    );

    return FirebaseAI.googleAI().generativeModel(
      model: _modelId,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: schema,
      ),
    );
  }

  /// Extracts tasks from [text] and/or a [pdfBytes] PDF. Dates are scheduled
  /// and clamped within [startDate]..[deadline]; suggested assignees are
  /// resolved against [members] (by name) into assignee uids.
  Future<List<Task>> extractTasks({
    String? text,
    Uint8List? pdfBytes,
    required DateTime startDate,
    required DateTime deadline,
    required List<TeamMember> members,
  }) async {
    final memberNames = members.map((m) => m.name).toList();

   final prompt = '''
You are an experienced university student and project coordinator.

Your job is to read an assignment brief, project description, report requirement,
or group project specification and convert it into a realistic set of tasks that
a student team would actually divide among themselves.

IMPORTANT

Think like a real student group.

Do NOT generate generic project-management phases such as:
- Requirement Analysis
- System Design
- Implementation
- Testing
- Documentation

unless those exact deliverables are explicitly required by the brief.

Instead, identify the actual work students would perform to complete the
assignment successfully.

TASK GENERATION RULES

1. Extract all required deliverables from the brief.

Examples:
- Report
- Research paper
- Literature review
- Presentation slides
- Prototype
- Mobile application
- Website
- Database
- Experiment
- Survey
- Case study
- Demo video

2. Convert deliverables into realistic work packages.

BAD TASKS:
- Do research
- Do testing
- Write report
- Implementation

GOOD TASKS:
- Research blockchain applications in healthcare
- Collect references for literature review
- Write Introduction section
- Design ERD and database schema
- Develop authentication module
- Implement tournament scheduling feature
- Conduct user testing with 5 participants
- Analyse experimental results
- Prepare presentation slides
- Rehearse presentation

3. Split large deliverables into logical subtasks.

For reports:
- Introduction
- Literature Review
- Methodology
- Results
- Discussion
- Conclusion

For software projects:
- Database
- Backend APIs
- Authentication
- Core features
- Testing
- Deployment

For research projects:
- Topic research
- Source collection
- Draft writing
- Analysis
- Editing
- Referencing

4. Generate tasks that can realistically be assigned to different team members.

Each task should:
- Have a clear outcome
- Be independently completable
- Represent meaningful work
- Usually take between a few hours and several days

Avoid tiny micro-tasks.

5. Include milestone tasks when appropriate.

Examples:
- Proposal completed
- Research completed
- First draft completed
- Prototype completed
- Slides completed
- Final submission ready

Milestones should be high priority.

SCHEDULING RULES

Schedule tasks strictly between:

START DATE:
${_ymd.format(startDate)}

END DATE:
${_ymd.format(deadline)}

Requirements:
- Respect task dependencies.
- Earlier tasks should enable later tasks.
- Spread work throughout the timeline.
- Avoid placing everything near the deadline.
- Leave at least 1–3 days before the final deadline for revisions and submission preparation.
- Milestones should appear at meaningful checkpoints.

ASSIGNEE RULES

Available team members:

${memberNames.isEmpty ? '(no members)' : memberNames.join(', ')}

Assign work realistically:
- Distribute workload fairly.
- Keep related tasks with the same member when reasonable.
- Assign report sections to different members when appropriate.
- Assign implementation modules to different members when appropriate.
- Return an empty string if no sensible assignee exists.

PRIORITY RULES

HIGH:
- Major deliverables
- Blocking tasks
- Milestones
- Critical-path work

MEDIUM:
- Standard assignment work

LOW:
- Final polish
- Optional improvements
- Nice-to-have enhancements

OUTPUT QUALITY REQUIREMENTS

Before creating tasks:

1. Determine the project type.
2. Identify all deliverables.
3. Identify required report sections.
4. Identify required implementation modules.
5. Identify required presentations or demonstrations.
6. Identify grading-related activities if mentioned.

Then generate tasks.

Every generated task must represent a concrete deliverable or work package that a student team would naturally assign to a person.

Return ONLY valid JSON matching the provided schema.
''';

    final parts = <Part>[TextPart(prompt)];
    if (text != null && text.trim().isNotEmpty) {
      parts.add(TextPart('BRIEF TEXT:\n${text.trim()}'));
    }
    if (pdfBytes != null) {
      parts.add(InlineDataPart('application/pdf', pdfBytes));
    }

    final response = await _model().generateContent([Content.multi(parts)]);
    final raw = response.text;
    if (raw == null || raw.trim().isEmpty) {
      throw Exception('The AI returned an empty response. Please try again.');
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final rawTasks = (decoded['tasks'] as List?) ?? const [];

    return rawTasks
        .whereType<Map<String, dynamic>>()
        .map((t) => _toTask(t, startDate, deadline, members))
        .where((t) => t.title.trim().isNotEmpty)
        .toList();
  }

  Task _toTask(
    Map<String, dynamic> data,
    DateTime rangeStart,
    DateTime rangeEnd,
    List<TeamMember> members,
  ) {
    final priority = ['low', 'medium', 'high'].contains(data['priority'])
        ? data['priority'] as String
        : 'medium';

    final start = _clampDate(_parseDate(data['startDate']), rangeStart, rangeEnd);
    final end = _clampDate(_parseDate(data['deadline']), rangeStart, rangeEnd);

    final subtasks = (data['subtasks'] as List?)
            ?.map((e) => e.toString())
            .where((s) => s.trim().isNotEmpty)
            .toList() ??
        const <String>[];

    final assigneeName = (data['suggestedAssignee'] as String?)?.trim() ?? '';
    String? assigneeId;
    if (assigneeName.isNotEmpty) {
      for (final m in members) {
        if (m.name.toLowerCase() == assigneeName.toLowerCase()) {
          assigneeId = m.uid;
          break;
        }
      }
    }

    return Task(
      id: '',
      title: (data['title'] as String?)?.trim() ?? '',
      description: (data['description'] as String?)?.trim() ?? '',
      status: 'todo',
      priority: priority,
      assigneeId: assigneeId,
      startDate: start,
      deadline: end,
      subtasks: subtasks,
      createdAt: DateTime.now(),
    );
  }

  DateTime? _parseDate(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    return DateTime.tryParse(value.trim());
  }

  DateTime? _clampDate(DateTime? date, DateTime min, DateTime max) {
    if (date == null) return null;
    if (date.isBefore(min)) return min;
    if (date.isAfter(max)) return max;
    return date;
  }
}
