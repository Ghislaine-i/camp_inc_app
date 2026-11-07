import '../../../core/constants.dart';
import 'incident.dart';

class IncidentFilter {
  const IncidentFilter({this.query = '', this.category, this.status});

  final String query;
  final IncidentCategory? category;
  final IncidentStatus? status;

  bool get isActive =>
      query.trim().isNotEmpty || category != null || status != null;

  IncidentFilter copyWith({
    String? query,
    IncidentCategory? category,
    IncidentStatus? status,
    bool clearCategory = false,
    bool clearStatus = false,
  }) {
    return IncidentFilter(
      query: query ?? this.query,
      category: clearCategory ? null : (category ?? this.category),
      status: clearStatus ? null : (status ?? this.status),
    );
  }
}

/// Pure function so it can be unit-tested without Firebase.
List<Incident> applyFilter(List<Incident> items, IncidentFilter f) {
  final q = f.query.trim().toLowerCase();
  return items.where((i) {
    if (f.category != null && i.category != f.category) return false;
    if (f.status != null && i.status != f.status) return false;
    if (q.isEmpty) return true;
    return i.title.toLowerCase().contains(q) ||
        i.description.toLowerCase().contains(q) ||
        i.location.toLowerCase().contains(q);
  }).toList();
}
