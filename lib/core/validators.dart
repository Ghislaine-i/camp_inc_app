class Validators {
  static final RegExp _emailRe = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

  /// Only these ALU domains may register.
  static const List<String> allowedDomains = [
    'alustudent.com',
    'alueducation.com',
  ];

  static bool isAluEmail(String email) {
    final parts = email.trim().toLowerCase().split('@');
    return parts.length == 2 && allowedDomains.contains(parts.last);
  }

  static String? required(String? v, String label) =>
      (v == null || v.trim().isEmpty) ? '$label is required' : null;

  static String? email(String? v) {
    final r = required(v, 'Email');
    if (r != null) return r;
    return _emailRe.hasMatch(v!.trim()) ? null : 'Enter a valid email address';
  }

  /// Email must be valid AND belong to an ALU domain.
  static String? aluEmail(String? v) {
    final base = email(v);
    if (base != null) return base;
    return isAluEmail(v!)
        ? null
        : 'Use your ALU email (@alustudent.com or @alueducation.com)';
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? confirmPassword(String? v, String original) {
    if (v == null || v.isEmpty) return 'Please confirm your password';
    return v == original ? null : 'Passwords do not match';
  }

  static String? name(String? v) {
    final r = required(v, 'Name');
    if (r != null) return r;
    return v!.trim().length < 2 ? 'Name is too short' : null;
  }

  static String? title(String? v) {
    final r = required(v, 'Title');
    if (r != null) return r;
    final len = v!.trim().length;
    if (len < 5) return 'Title must be at least 5 characters';
    if (len > 80) return 'Title must be 80 characters or fewer';
    return null;
  }

  static String? description(String? v) {
    final r = required(v, 'Description');
    if (r != null) return r;
    final len = v!.trim().length;
    if (len < 10) return 'Please describe the issue (at least 10 characters)';
    if (len > 1000) return 'Description must be 1000 characters or fewer';
    return null;
  }

  static String? location(String? v) => required(v, 'Location');
}
