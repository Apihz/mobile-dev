import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:intl/intl.dart';

import '../../../models/task.dart';
import '../../../models/team_member.dart';

/// Uses Firebase AI Logic (Gemini Developer API, free Spark tier) to turn an
/// assignment/GP brief (PDF or pasted text) into a structured list of tasks.
class AiExtractService {
  // Confirm/upgrade the exact model id in the Firebase AI Logic console.
  // (Gemini 2.0 Flash was retired Jun 1 2026 — use a current Flash model.)
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
You are an academic project planner who helps university students turn an
assignment or group-project brief into a realistic, student-friendly task plan.
The brief is provided below and/or in the attached PDF.

Plan the way a real student team works: limited time, mixed skill levels, and
work split across people by report sections, research topics, implementation
modules, testing duties, presentation slides, and documentation. Aim for a
timeline a lecturer would expect to see in a student project, not a corporate
software sprint.

WHAT TO EXTRACT
- Only output tasks that are present in or clearly implied by the brief. Do not
  invent scope that is not there.
- Infer the common academic subtasks a brief like this normally requires, even
  when not spelled out, as long as they are strongly implied.
- Break each major deliverable into a few concrete "subtasks" (aim for 2 to 5).
- Avoid trivial micro-tasks, and avoid artificial project-management busywork
  that students would not actually do (no ticket boards, no daily stand-ups, no
  sprint ceremonies).

PICK THE RIGHT WORKFLOW FOR THE BRIEF
- If this is a programming or system project, cover the natural phases where
  relevant: requirement analysis, design, implementation broken down by module,
  testing and debugging, documentation, and demo or presentation prep.
- If this is a research or report assignment, cover the natural phases where
  relevant: understanding the topic, literature review and information
  gathering, outlining, drafting by section, editing, citation and reference
  checking, proofreading, and presentation prep.
- Most group projects also benefit from: a kickoff discussion to divide the
  work, at least one progress check or internal group review, a lecturer or
  supervisor consultation if the brief implies one, a revision round after
  feedback, and final submission preparation. Include these only when they fit.

MILESTONES
- Represent key checkpoints as their own tasks so they land on the timeline, for
  example proposal complete, progress checkpoint, full draft or build complete,
  presentation ready, and final submission. Give milestone tasks high priority.

DEPENDENCIES AND SCHEDULING
- Order tasks by dependency: plan and understand first, then research or
  analysis, then implementation or drafting, then testing or editing, then
  presentation, then final submission. Dependent tasks should start only after
  their prerequisites.
- Set each "startDate" and "deadline" as YYYY-MM-DD strictly within
  ${_ymd.format(startDate)} to ${_ymd.format(deadline)}. Spread tasks across the
  whole range and leave a short buffer before the final deadline for revision
  and submission prep.

WORKLOAD AND ASSIGNEES
- Balance the work fairly across the team. Set "suggestedAssignee" to one of
  these member names, distributing tasks roughly evenly and keeping related work
  with the same person where it makes sense: ${memberNames.isEmpty ? '(no members)' : memberNames.join(', ')}.
  Leave it empty when there is no sensible owner or when there are no members.

PRIORITY
- Use high for milestones, blocking tasks, and anything on the critical path.
  Use medium for normal deliverable work. Use low for polish, optional, or
  nice-to-have items.

Return JSON that matches the provided schema.
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
