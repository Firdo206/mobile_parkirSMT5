class NotifikasiItem {
  final int id;
  final String title;
  final String body;
  final String status;
  final String plate;
  final bool needsAction;
  final int secondsLeft;
  final DateTime requestedAt;

  NotifikasiItem({
    required this.id,
    required this.title,
    required this.body,
    required this.status,
    required this.plate,
    required this.needsAction,
    required this.secondsLeft,
    required this.requestedAt,
  });

  factory NotifikasiItem.fromJson(Map<String, dynamic> j) => NotifikasiItem(
        id: j['id'] as int,
        title: (j['title'] ?? '').toString(),
        body: (j['body'] ?? '').toString(),
        status: (j['status'] ?? '').toString(),
        plate: (j['plate'] ?? '').toString(),
        needsAction: j['needs_action'] == true,
        secondsLeft: (j['seconds_left'] ?? 0) as int,
        requestedAt: DateTime.parse(j['requested_at'].toString()).toLocal(),
      );
}

class NotifikasiResult {
  final int pendingCount;
  final List<NotifikasiItem> items;
  NotifikasiResult(this.pendingCount, this.items);
}