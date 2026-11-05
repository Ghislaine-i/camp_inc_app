import 'package:flutter/material.dart';

enum UserRole {
  student,
  staff;

  static UserRole fromValue(String? v) =>
      v == 'staff' ? UserRole.staff : UserRole.student;
}

enum IncidentCategory {
  water('water', 'Water shortage', Icons.water_drop),
  electricity('electricity', 'Electricity outage', Icons.bolt),
  facilities('facilities', 'Broken facilities', Icons.build),
  furniture('furniture', 'Damaged furniture', Icons.chair),
  sanitation('sanitation', 'Sanitation', Icons.cleaning_services),
  safety('safety', 'Safety concern', Icons.shield),
  other('other', 'Other', Icons.report_problem);

  const IncidentCategory(this.value, this.label, this.icon);
  final String value;
  final String label;
  final IconData icon;

  static IncidentCategory fromValue(String? v) => IncidentCategory.values
      .firstWhere((e) => e.value == v, orElse: () => IncidentCategory.other);
}

enum IncidentStatus {
  submitted('submitted', 'Submitted', Colors.blueGrey),
  underReview('under_review', 'Under review', Colors.orange),
  inProgress('in_progress', 'In progress', Colors.blue),
  resolved('resolved', 'Resolved', Colors.green);

  const IncidentStatus(this.value, this.label, this.color);
  final String value;
  final String label;
  final Color color;

  static IncidentStatus fromValue(String? v) => IncidentStatus.values
      .firstWhere((e) => e.value == v, orElse: () => IncidentStatus.submitted);
}
