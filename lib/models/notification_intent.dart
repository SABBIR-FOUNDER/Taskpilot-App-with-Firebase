import 'dart:convert';

class NotificationIntent {
  const NotificationIntent({this.taskId, this.userId});
  final String? taskId;
  final String? userId;
  static String? _validId(Object? value) {
    if (value is! String ||
        value.isEmpty ||
        value.length > 1500 ||
        value.contains('/')) {
      return null;
    }
    return value;
  }

  factory NotificationIntent.fromData(Map<String, dynamic> data) =>
      NotificationIntent(
        taskId: _validId(data['taskId']),
        userId: _validId(data['userId']),
      );
  factory NotificationIntent.fromPayload(String? payload) {
    if (payload == null || payload.isEmpty) return const NotificationIntent();
    try {
      final data = jsonDecode(payload);
      if (data is Map<String, dynamic>) {
        return NotificationIntent.fromData(data);
      }
    } on FormatException {
      /* A malformed payload opens the list safely. */
    }
    return const NotificationIntent();
  }
  String toPayload() => jsonEncode({'taskId': taskId, 'userId': userId});
  bool belongsTo(String uid) => userId == null || userId == uid;
}
