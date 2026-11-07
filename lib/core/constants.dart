import 'package:flutter/material.dart';
import 'theme.dart';

enum UserRole {
  student,
  staff;

  static UserRole fromValue(String? v) =>
      v == 'staff' ? UserRole.staff : UserRole.student;
}

enum IncidentCategory {
  water('water', 'Water shortage', Icons.water_drop_rounded),
  electricity('electricity', 'Electricity outage', Icons.bolt_rounded),
  facilities('facilities', 'Broken facilities', Icons.build_rounded),
  furniture('furniture', 'Damaged furniture', Icons.chair_rounded),
  sanitation('sanitation', 'Sanitation', Icons.cleaning_services_rounded),
  safety('safety', 'Safety concern', Icons.shield_rounded),
  other('other', 'Other', Icons.report_problem_rounded);

  const IncidentCategory(this.value, this.label, this.icon);
  final String value;
  final String label;
  final IconData icon;

  static IncidentCategory fromValue(String? v) => IncidentCategory.values
      .firstWhere((e) => e.value == v, orElse: () => IncidentCategory.other);
}

enum IncidentStatus {
  submitted('submitted', 'Submitted', AppColors.submitted),
  underReview('under_review', 'Under review', AppColors.underReview),
  inProgress('in_progress', 'In progress', AppColors.inProgress),
  resolved('resolved', 'Resolved', AppColors.resolved);

  const IncidentStatus(this.value, this.label, this.color);
  final String value;
  final String label;
  final Color color;

  static IncidentStatus fromValue(String? v) => IncidentStatus.values
      .firstWhere((e) => e.value == v, orElse: () => IncidentStatus.submitted);
}
