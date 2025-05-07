class Conversation {
  final String id;
  final List<String> participantIds;
  final List<Map<String, dynamic>> participants;
  final String? lastMessageId;
  final Map<String, dynamic>? lastMessage;
  final DateTime updatedAt;
  final bool isDeleted;

  Conversation({
    required this.id,
    required this.participantIds,
    required this.participants,
    this.lastMessageId,
    this.lastMessage,
    required this.updatedAt,
    this.isDeleted = false,
  });

  // Convert Conversation to JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participantIds': participantIds,
      'participants': participants,
      'lastMessageId': lastMessageId,
      'lastMessage': lastMessage,
      'updatedAt': updatedAt.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }

  // Create Conversation from JSON Map
  factory Conversation.fromJson(Map<String, dynamic> json) {
    // Handle participants which might be an array of objects or just IDs
    List<String> participantIds = [];
    List<Map<String, dynamic>> participants = [];
    
    if (json['participants'] != null && json['participants'] is List) {
      for (var participant in json['participants']) {
        if (participant is Map) {
          participantIds.add(participant['_id']?.toString() ?? '');
          participants.add({
            'id': participant['_id']?.toString() ?? '',
            'name': participant['name']?.toString() ?? '',
            'email': participant['email']?.toString() ?? '',
            'image': participant['image']?.toString(),
            'jobTitle': participant['jobTitle']?.toString() ?? '',
          });
        } else {
          participantIds.add(participant.toString());
        }
      }
    } else if (json['participantIds'] != null && json['participantIds'] is List) {
      participantIds = List<String>.from(json['participantIds']);
    }

    return Conversation(
      id: json['_id']?.toString() ?? '',
      participantIds: participantIds,
      participants: participants,
      lastMessageId: json['lastMessage']?.toString(),
      lastMessage: json['lastMessage'] is Map ? json['lastMessage'] as Map<String, dynamic> : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      isDeleted: json['isDeleted'] == true,
    );
  }
}
