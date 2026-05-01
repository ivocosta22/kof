/// One notification record kept in the in-app notifications screen. The
/// payload mirrors a Firebase Cloud Messaging message (title + body + a
/// `data` map of strings) plus a local-only `receivedAt` and a `read` flag
/// so we can show an unread indicator on the bell.
class NotificationItem {
  final String id;
  final String title;
  final String body;
  final Map<String, String> data;
  final DateTime receivedAt;
  bool read;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.data,
    required this.receivedAt,
    this.read = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'data': data,
        'receivedAt': receivedAt.toIso8601String(),
        'read': read,
      };

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final data = <String, String>{};
    if (rawData is Map) {
      rawData.forEach((k, v) => data[k.toString()] = v?.toString() ?? '');
    }
    return NotificationItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      data: data,
      receivedAt: DateTime.tryParse(json['receivedAt'] as String? ?? '') ??
          DateTime.now(),
      read: json['read'] == true,
    );
  }

  // Convenience accessors for the broadcast-style payloads we currently send.
  String? get shopId => data['shopId'];
  String? get broadcastId => data['broadcastId'];
  String? get type => data['type'];
}
