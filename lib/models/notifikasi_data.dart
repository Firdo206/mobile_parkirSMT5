class NotifikasiItem {
  final int id;
  final String title;
  final String body;
  final String status;
  final String plate;
  final bool needsAction;
  final int secondsLeft;
  final DateTime requestedAt;

  /// 'entry' | 'exit' | null
  final String? direction;

  /// Aksi yang boleh dilakukan pemilik, ditentukan server:
  /// 'approve', 'reject', 'buzzer'.
  final List<String> actions;

  NotifikasiItem({
    required this.id,
    required this.title,
    required this.body,
    required this.status,
    required this.plate,
    required this.needsAction,
    required this.secondsLeft,
    required this.requestedAt,
    this.direction,
    this.actions = const [],
  });

  bool get bisaIzinkan => actions.contains('approve');
  bool get bisaTolak => actions.contains('reject');
  bool get bisaBuzzer => actions.contains('buzzer');

  factory NotifikasiItem.fromJson(Map<String, dynamic> j) {
    final needsAction = j['needs_action'] == true;
    final daftar = j['actions'];

    // Server lama belum mengirim 'actions': permintaan yang menunggu
    // tetap bisa diizinkan atau ditolak.
    final actions = daftar is List
        ? daftar.map((e) => e.toString()).toList()
        : (needsAction ? <String>['approve', 'reject'] : <String>[]);

    return NotifikasiItem(
      id: j['id'] as int,
      title: (j['title'] ?? '').toString(),
      body: (j['body'] ?? '').toString(),
      status: (j['status'] ?? '').toString(),
      plate: (j['plate'] ?? '').toString(),
      needsAction: needsAction,
      secondsLeft: (j['seconds_left'] ?? 0) as int,
      requestedAt: DateTime.parse(j['requested_at'].toString()).toLocal(),
      direction: j['direction']?.toString(),
      actions: actions,
    );
  }
}

class NotifikasiResult {
  final int pendingCount;
  final List<NotifikasiItem> items;
  NotifikasiResult(this.pendingCount, this.items);
}