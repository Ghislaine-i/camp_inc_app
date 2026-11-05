import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants.dart';

class Incident {
  const Incident({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.location,
    required this.reporterId,
    required this.reporterName,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrl,
    this.lastNote,
  });

  final String id;
  final String title;
  final String description;
  final IncidentCategory category;
  final IncidentStatus status;
  final String location;
  final String reporterId;
  final String reporterName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? imageUrl;
  final String? lastNote;

  factory Incident.fromMap(String id, Map<String, dynamic> m) => Incident(
        id: id,
        title: m['title'] as String? ?? '',
        description: m['description'] as String? ?? '',
        category: IncidentCategory.fromValue(m['category'] as String?),
        status: IncidentStatus.fromValue(m['status'] as String?),
        location: m['location'] as String? ?? '',
        reporterId: m['reporterId'] as String? ?? '',
        reporterName: m['reporterName'] as String? ?? 'Unknown',
        createdAt: _ts(m['createdAt']),
        updatedAt: _ts(m['updatedAt']),
        imageUrl: m['imageUrl'] as String?,
        lastNote: m['lastNote'] as String?,
      );

  // serverTimestamp() is null locally until the server confirms the write.
  static DateTime _ts(dynamic v) => v is Timestamp ? v.toDate() : DateTime.now();
}
