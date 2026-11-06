import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants.dart';
import '../../auth/models/app_user.dart';
import '../models/incident.dart';
import '../models/status_event.dart';
import 'image_repository.dart';

/// All Firestore / image-upload access lives here; UI and providers never touch
/// Firebase or Cloudinary directly.
class IncidentRepository {
  IncidentRepository(this._db, this._images);
  final FirebaseFirestore _db;
  final ImageRepository _images;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('incidents');

  Stream<List<Incident>> watchAll() {
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Incident.fromMap(d.id, d.data())).toList());
  }

  Stream<Incident?> watchOne(String id) {
    return _col.doc(id).snapshots().map((s) {
      final data = s.data();
      return data == null ? null : Incident.fromMap(s.id, data);
    });
  }

  Stream<List<StatusEvent>> watchHistory(String incidentId) {
    return _col
        .doc(incidentId)
        .collection('statusHistory')
        .orderBy('timestamp')
        .snapshots()
        .map((s) => s.docs.map((d) => StatusEvent.fromMap(d.id, d.data())).toList());
  }

  Future<void> create({
    required AppUser reporter,
    required String title,
    required String description,
    required IncidentCategory category,
    required String location,
    File? image,
    void Function(double progress)? onProgress,
  }) async {
    final doc = _col.doc(); // generate the id first so the image path matches it
    String? imageUrl;

    if (image != null) {
      imageUrl = await _images.upload(
        image,
        pathHint: 'incident_images/${reporter.uid}/${doc.id}.jpg',
        onProgress: onProgress,
      );
    }

    await doc.set({
      'title': title.trim(),
      'description': description.trim(),
      'category': category.value,
      'status': IncidentStatus.submitted.value,
      'location': location.trim(),
      'imageUrl': imageUrl,
      'reporterId': reporter.uid,
      'reporterName': reporter.name,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastNote': null,
    });
  }

  /// Updates the status and appends a history event atomically.
  /// Firestore rules only allow this for staff.
  Future<void> updateStatus({
    required Incident incident,
    required IncidentStatus newStatus,
    required String note,
    required AppUser staff,
  }) async {
    final batch = _db.batch();
    final ref = _col.doc(incident.id);
    batch.update(ref, {
      'status': newStatus.value,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastNote': note.trim().isEmpty ? null : note.trim(),
    });
    batch.set(ref.collection('statusHistory').doc(), {
      'oldStatus': incident.status.value,
      'newStatus': newStatus.value,
      'changedBy': staff.uid,
      'changedByName': staff.name,
      'note': note.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }
}
