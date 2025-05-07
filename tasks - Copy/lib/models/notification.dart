class Notification {
  final String id;
  final String message;
  final bool isRead;
  final String type;
  final String? relatedTaskId;
  final String? relatedMessageId;
  final String? createdById;
  final String? createdByName;
  final String? createdByEmail;
  final String? createdByImage;
  final DateTime createdAt;

  Notification({
    required this.id,
    required this.message,
    required this.isRead,
    required this.type,
    this.relatedTaskId,
    this.relatedMessageId,
    this.createdById,
    this.createdByName,
    this.createdByEmail,
    this.createdByImage,
    required this.createdAt,
  });

  // Convert Notification to JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'isRead': isRead,
      'type': type,
      'relatedTaskId': relatedTaskId,
      'relatedMessageId': relatedMessageId,
      'createdById': createdById,
      'createdByName': createdByName,
      'createdByEmail': createdByEmail,
      'createdByImage': createdByImage,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create Notification from JSON Map
  factory Notification.fromJson(Map<String, dynamic> json) {
    // Handle the relatedTask which might be an object or just an ID
    String? relatedTaskId;
    if (json['relatedTask'] != null) {
      if (json['relatedTask'] is Map) {
        relatedTaskId = json['relatedTask']['_id']?.toString();
      } else {
        relatedTaskId = json['relatedTask']?.toString();
      }
    }

    // Handle the relatedMessage which might be an object or just an ID
    String? relatedMessageId;
    if (json['relatedMessage'] != null) {
      if (json['relatedMessage'] is Map) {
        relatedMessageId = json['relatedMessage']['_id']?.toString();
      } else {
        relatedMessageId = json['relatedMessage']?.toString();
      }
    }

    // Handle the createdBy which might be an object or just an ID
    String? createdById;
    String? createdByName;
    String? createdByEmail;
    String? createdByImage;

    if (json['createdBy'] != null) {
      if (json['createdBy'] is Map) {
        createdById = json['createdBy']['_id']?.toString();
        createdByName = json['createdBy']['name']?.toString();
        createdByEmail = json['createdBy']['email']?.toString();
        createdByImage = json['createdBy']['image']?.toString();
      } else {
        createdById = json['createdBy']?.toString();
      }
    }

    return Notification(
      id: json['_id']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      isRead: json['isRead'] == true,
      type: json['type']?.toString() ?? 'general',
      relatedTaskId: relatedTaskId,
      relatedMessageId: relatedMessageId,
      createdById: createdById,
      createdByName: createdByName,
      createdByEmail: createdByEmail,
      createdByImage: createdByImage,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Notification copyWith({
    String? id,
    String? message,
    bool? isRead,
    String? type,
    String? relatedTaskId,
    String? relatedMessageId,
    String? createdById,
    String? createdByName,
    String? createdByEmail,
    String? createdByImage,
    DateTime? createdAt,
  }) {
    return Notification(
      id: id ?? this.id,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      relatedTaskId: relatedTaskId ?? this.relatedTaskId,
      relatedMessageId: relatedMessageId ?? this.relatedMessageId,
      createdById: createdById ?? this.createdById,
      createdByName: createdByName ?? this.createdByName,
      createdByEmail: createdByEmail ?? this.createdByEmail,
      createdByImage: createdByImage ?? this.createdByImage,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
