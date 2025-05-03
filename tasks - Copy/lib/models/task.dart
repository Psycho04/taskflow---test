class Task {
  final String id;
  final String title;
  final String description;
  final String priority;
  final DateTime date;
  final String stage;
  final List<Map<String, dynamic>> assignees;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.date,
    required this.stage,
    required this.assignees,
  });

  // Convert Task to JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority,
      'date': date.toIso8601String(),
      'stage': stage,
      'assignees': assignees.map((a) => {
        'id': a['id'] ?? '',
        'fullName': a['fullName'] ?? '',
        'email': a['email'] ?? '',
      }).toList(),
    };
  }

  // Create Task from JSON Map
  factory Task.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> processAssignees(dynamic assigneesData) {
      if (assigneesData == null) return [];
      
      if (assigneesData is List) {
        return assigneesData.map((assignee) {
          if (assignee is Map) {
            return {
              'id': assignee['_id']?.toString() ?? assignee['id']?.toString() ?? '',
              'fullName': assignee['fullName']?.toString() ?? assignee['name']?.toString() ?? '',
              'email': assignee['email']?.toString() ?? '',
            };
          } else if (assignee is String) {
            return {
              'id': assignee,
              'fullName': '',
              'email': '',
            };
          }
          return {
            'id': '',
            'fullName': '',
            'email': '',
          };
        }).toList();
      }
      
      return [];
    }

    return Task(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      priority: json['priority']?.toString().toLowerCase() ?? 'low',
      date: DateTime.tryParse(json['dueDate']?.toString() ?? json['date']?.toString() ?? '') ?? DateTime.now(),
      stage: json['status']?.toString() ?? json['stage']?.toString() ?? 'to do',
      assignees: processAssignees(json['assignedTo'] ?? json['assignees']),
    );
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? priority,
    DateTime? date,
    String? stage,
    List<Map<String, dynamic>>? assignees,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      date: date ?? this.date,
      stage: stage ?? this.stage,
      assignees: assignees ?? List.from(this.assignees),
    );
  }
}