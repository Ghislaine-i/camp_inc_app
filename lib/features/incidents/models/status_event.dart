import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants.dart';

class StatusEvent {
  const StatusEvent({
    required this.id,
    required this.oldStatus,
    required this.newStatus,
    required this.changedByName,
    required this.note,
    required this.timestamp,
  });

  final String id;
  final IncidentStatus oldStatus;
  final IncidentStatus newStatus;
  final String changedByName;
  final String note;
  final DateTime timestamp;

  factory StatusEvent.fromMap(String id, Map<String, dynamic> m) => StatusEvent(
        id: id,
        oldStatus: IncidentStatus.fromValue(m['oldStatus'] as String?),
        newStatus: IncidentStatus.fromValue(m['newStatus'] as String?),
        changedByName: m['changedByName'] as String? ?? 'Staff',
        note: m['note'] as String? ?? '',
        timestamp: m['timestamp'] is Timestamp
            ? (m['timestamp'] as Timestamp).toDate()
            : DateTime.now(),
      );
}
