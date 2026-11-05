import 'package:campus_incident_app/core/constants.dart';
import 'package:campus_incident_app/core/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('StatusBadge shows the status label', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: StatusBadge(status: IncidentStatus.inProgress)),
    ));
    expect(find.text('In progress'), findsOneWidget);
  });
}
