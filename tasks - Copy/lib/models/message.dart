class Message {
  final String id;
  final String content;
  final bool isRead;
  final String senderId;
  final String senderName;
  final String? senderImage;
  final String receiverId;
  final String receiverName;
  final String? receiverImage;
  final DateTime createdAt;
  final bool isDeleted;
  final String? deletedBy;
  final Map<String, dynamic>? attachment;

  Message({
    required this.id,
    required this.content,
    required this.isRead,
    required this.senderId,
    required this.senderName,
    this.senderImage,
    required this.receiverId,
    required this.receiverName,
    this.receiverImage,
    required this.createdAt,
    this.isDeleted = false,
    this.deletedBy,
    this.attachment,
  });

  // Convert Message to JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'isRead': isRead,
      'senderId': senderId,
      'senderName': senderName,
      'senderImage': senderImage,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'receiverImage': receiverImage,
      'createdAt': createdAt.toIso8601String(),
      'isDeleted': isDeleted,
      'deletedBy': deletedBy,
      'attachment': attachment,
    };
  }

  // Create Message from JSON Map
  factory Message.fromJson(Map<String, dynamic> json) {
    // Handle sender data which might be an object or just an ID
    String senderId = '';
    String senderName = '';
    String? senderImage;
    
    if (json['sender'] != null) {
      if (json['sender'] is Map) {
        senderId = json['sender']['_id']?.toString() ?? '';
        senderName = json['sender']['name']?.toString() ?? '';
        senderImage = json['sender']['image']?.toString();
      } else {
        senderId = json['sender']?.toString() ?? '';
      }
    } else {
      senderId = json['senderId']?.toString() ?? '';
      senderName = json['senderName']?.toString() ?? '';
      senderImage = json['senderImage']?.toString();
    }

    // Handle receiver data which might be an object or just an ID
    String receiverId = '';
    String receiverName = '';
    String? receiverImage;
    
    if (json['receiver'] != null) {
      if (json['receiver'] is Map) {
        receiverId = json['receiver']['_id']?.toString() ?? '';
        receiverName = json['receiver']['name']?.toString() ?? '';
        receiverImage = json['receiver']['image']?.toString();
      } else {
        receiverId = json['receiver']?.toString() ?? '';
      }
    } else {
      receiverId = json['receiverId']?.toString() ?? '';
      receiverName = json['receiverName']?.toString() ?? '';
      receiverImage = json['receiverImage']?.toString();
    }

    return Message(
      id: json['_id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      isRead: json['isRead'] == true,
      senderId: senderId,
      senderName: senderName,
      senderImage: senderImage,
      receiverId: receiverId,
      receiverName: receiverName,
      receiverImage: receiverImage,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isDeleted: json['isDeleted'] == true,
      deletedBy: json['deletedBy']?.toString(),
      attachment: json['attachment'] as Map<String, dynamic>?,
    );
  }
}
