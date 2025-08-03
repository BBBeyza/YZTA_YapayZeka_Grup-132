class Report {
  final String id;
  final String title;
  final String content;
  final DateTime date;
  final String type;
  final String userId;

  Report({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.type,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date.toIso8601String(),
      'type': type,
      'userId': userId,
    };
  }

  factory Report.fromMap(Map<String, dynamic> map) {
    return Report(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      date: DateTime.parse(map['date']),
      type: map['type'],
      userId: map['userId'],
    );
  }
}
