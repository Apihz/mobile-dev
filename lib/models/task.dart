class Task {
    final String id;
    final String title;
    final String subject;
    final String status; // 'todo' | 'doing' | 'review' | 'done'
    final String? assigneeId;
    final DateTime? deadline;

    Task({
      required this.id,
      required this.title,
      required this.subject,
      required this.status,
      this.assigneeId,
      this.deadline,
    });

    factory Task.fromMap(String id, Map<String, dynamic> data) {
      return Task(
        id: id,
        title: data['title'] ?? '',
        subject: data['subject'] ?? '',
        status: data['status'] ?? 'todo',
        assigneeId: data['assigneeId'],
        deadline: data['deadline']?.toDate(),
      );
    }

    Map<String, dynamic> toMap() {
      return {
        'title': title,
        'subject': subject,
        'status': status,
        'assigneeId': assigneeId,
        'deadline': deadline,
      };
    }
  }
