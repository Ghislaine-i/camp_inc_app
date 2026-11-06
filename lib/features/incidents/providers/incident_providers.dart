import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/image_repository.dart';
import '../data/incident_repository.dart';
import '../models/incident.dart';
import '../models/incident_filter.dart';
import '../models/status_event.dart';

/// Provides the Cloudinary image implementation.
final imageRepositoryProvider = Provider<ImageRepository>((ref) {
  return CloudinaryImageRepository();
});

final incidentRepositoryProvider = Provider<IncidentRepository>((ref) {
  return IncidentRepository(
    ref.watch(firestoreProvider),
    ref.watch(imageRepositoryProvider),
  );
});

/// Real-time stream of every incident (newest first).
/// Returns an empty list immediately when the user is not signed in or their
/// email is not yet verified, so the Firestore listener never runs
/// unauthorised and we avoid permission-denied errors on sign-out.
final incidentsStreamProvider = StreamProvider<List<Incident>>((ref) {
  final authValue = ref.watch(authStateProvider);
  final user = authValue.valueOrNull;
  if (user == null || !user.emailVerified) {
    return Stream.value(const <Incident>[]);
  }
  return ref.watch(incidentRepositoryProvider).watchAll();
});

/// Only the signed-in user's reports.
final myIncidentsProvider = Provider<AsyncValue<List<Incident>>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  return ref
      .watch(incidentsStreamProvider)
      .whenData((all) => all.where((i) => i.reporterId == uid).toList());
});

// ---- Search + filter state -------------------------------------------------

class FilterNotifier extends Notifier<IncidentFilter> {
  @override
  IncidentFilter build() => const IncidentFilter();

  void setQuery(String q) => state = state.copyWith(query: q);
  void setCategory(IncidentCategory? c) =>
      state = c == null ? state.copyWith(clearCategory: true) : state.copyWith(category: c);
  void setStatus(IncidentStatus? s) =>
      state = s == null ? state.copyWith(clearStatus: true) : state.copyWith(status: s);
  void clear() => state = const IncidentFilter();
}

final filterProvider =
    NotifierProvider<FilterNotifier, IncidentFilter>(FilterNotifier.new);

/// Derived state: stream + filter -> visible list.
final filteredIncidentsProvider = Provider<AsyncValue<List<Incident>>>((ref) {
  final filter = ref.watch(filterProvider);
  return ref.watch(incidentsStreamProvider).whenData((all) => applyFilter(all, filter));
});

// ---- Detail ----------------------------------------------------------------

final incidentProvider = StreamProvider.family<Incident?, String>((ref, id) {
  return ref.watch(incidentRepositoryProvider).watchOne(id);
});

final statusHistoryProvider =
    StreamProvider.family<List<StatusEvent>, String>((ref, id) {
  return ref.watch(incidentRepositoryProvider).watchHistory(id);
});

// ---- Submit report ---------------------------------------------------------

class UploadProgressNotifier extends Notifier<double> {
  @override
  double build() => 0;
  void set(double v) => state = v;
}

final uploadProgressProvider =
    NotifierProvider<UploadProgressNotifier, double>(UploadProgressNotifier.new);

class SubmitController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> submit({
    required String title,
    required String description,
    required IncidentCategory category,
    required String location,
    File? image,
  }) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) {
      state = AsyncError('You must be signed in.', StackTrace.current);
      return false;
    }
    ref.read(uploadProgressProvider.notifier).set(0);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(incidentRepositoryProvider).create(
          reporter: user,
          title: title,
          description: description,
          category: category,
          location: location,
          image: image,
          onProgress: (p) => ref.read(uploadProgressProvider.notifier).set(p),
        ));
    return !state.hasError;
  }
}

final submitControllerProvider =
    AsyncNotifierProvider<SubmitController, void>(SubmitController.new);

// ---- Staff: update status --------------------------------------------------

class StatusController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> updateStatus({
    required Incident incident,
    required IncidentStatus newStatus,
    required String note,
  }) async {
    final staff = ref.read(currentUserProvider).value;
    // Client-side guard. The real enforcement is in firestore.rules.
    if (staff == null || !staff.isStaff) {
      state = AsyncError('Only staff can update incident status.', StackTrace.current);
      return false;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(incidentRepositoryProvider).updateStatus(
          incident: incident,
          newStatus: newStatus,
          note: note,
          staff: staff,
        ));
    return !state.hasError;
  }
}

final statusControllerProvider =
    AsyncNotifierProvider<StatusController, void>(StatusController.new);
