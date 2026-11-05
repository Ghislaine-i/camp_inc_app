import 'package:campus_incident_app/core/constants.dart';
import 'package:campus_incident_app/features/incidents/models/incident.dart';
import 'package:campus_incident_app/features/incidents/models/incident_filter.dart';
import 'package:campus_incident_app/features/incidents/providers/incident_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Incident make(String id, String title, IncidentCategory c, IncidentStatus s,
        {String location = 'Block A'}) =>
    Incident(
      id: id,
      title: title,
      description: 'desc of $title',
      category: c,
      status: s,
      location: location,
      reporterId: 'u1',
      reporterName: 'Ann',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

void main() {
  final items = [
    make('1', 'Water outage', IncidentCategory.water, IncidentStatus.submitted),
    make('2', 'Broken chair', IncidentCategory.furniture, IncidentStatus.resolved,
        location: 'Library'),
    make('3', 'Power cut', IncidentCategory.electricity, IncidentStatus.inProgress),
  ];

  test('no filter returns everything', () {
    expect(applyFilter(items, const IncidentFilter()).length, 3);
  });

  test('search matches title, case-insensitive', () {
    final r = applyFilter(items, const IncidentFilter(query: 'WATER'));
    expect(r.map((e) => e.id), ['1']);
  });

  test('search matches location', () {
    final r = applyFilter(items, const IncidentFilter(query: 'library'));
    expect(r.map((e) => e.id), ['2']);
  });

  test('category + status combine with AND', () {
    final r = applyFilter(
        items,
        const IncidentFilter(
            category: IncidentCategory.water, status: IncidentStatus.resolved));
    expect(r, isEmpty);
  });

  test('Incident.fromMap parses Firestore data', () {
    final i = Incident.fromMap('x', {
      'title': 'Leak',
      'description': 'Water leak',
      'category': 'water',
      'status': 'under_review',
      'location': 'B1',
      'reporterId': 'u',
      'reporterName': 'Bo',
      'createdAt': Timestamp.fromDate(DateTime(2026, 2, 3)),
      'updatedAt': Timestamp.fromDate(DateTime(2026, 2, 4)),
    });
    expect(i.status, IncidentStatus.underReview);
    expect(i.category, IncidentCategory.water);
    expect(i.createdAt, DateTime(2026, 2, 3));
    expect(i.imageUrl, isNull);
  });

  test('FilterNotifier updates and clears state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final n = container.read(filterProvider.notifier);

    n.setQuery('tap');
    n.setCategory(IncidentCategory.water);
    expect(container.read(filterProvider).query, 'tap');
    expect(container.read(filterProvider).category, IncidentCategory.water);
    expect(container.read(filterProvider).isActive, isTrue);

    n.setCategory(null);
    expect(container.read(filterProvider).category, isNull);

    n.clear();
    expect(container.read(filterProvider).isActive, isFalse);
  });
}
