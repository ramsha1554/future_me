

class FutureMessage {
  final String id;
  final String content;
  final DateTime createdAt;
  final DateTime unlockAt;

  FutureMessage({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.unlockAt,
  });

  factory FutureMessage.fromJson(Map<String, dynamic> json) => FutureMessage(
        id: json['id'] as String,
        content: json['content'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        unlockAt: DateTime.parse(json['unlockAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'unlockAt': unlockAt.toIso8601String(),
      };

  bool get isUnlocked => !DateTime.now().isBefore(unlockAt);
}
