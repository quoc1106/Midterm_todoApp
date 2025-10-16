import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'project_providers.dart';
import 'performance_initialization_providers.dart';

/// Provider để theo dõi và tự động reset project selection khi project bị xóa
final validatedProjectSelectionProvider =
    StateNotifierProvider<ValidatedProjectSelectionNotifier, String?>((ref) {
      return ValidatedProjectSelectionNotifier(ref);
    });

/// Provider để theo dõi và tự động reset section selection khi section bị xóa
final validatedSectionSelectionProvider =
    StateNotifierProvider<ValidatedSectionSelectionNotifier, String?>((ref) {
      return ValidatedSectionSelectionNotifier(ref);
    });

class ValidatedProjectSelectionNotifier extends StateNotifier<String?> {
  final Ref _ref;

  ValidatedProjectSelectionNotifier(this._ref) : super(null) {
    // Lắng nghe thay đổi của project list để validate selection
    _ref.listen(projectsProvider, (previous, next) {
      _validateAndReset();
    });
  }

  void setSelection(String? projectId) {
    state = projectId;
    // Reset section khi thay đổi project
    _ref
        .read(validatedSectionSelectionProvider.notifier)
        .resetIfProjectChanged(projectId);
  }

  void _validateAndReset() {
    if (state != null) {
      final projectBox = _ref.read(projectBoxProvider);
      final project = projectBox.get(state!);

      if (project == null) {
        state = null;
        // Cũng reset section
        _ref.read(validatedSectionSelectionProvider.notifier).forceReset();
      }
    }
  }

  void forceReset() {
    state = null;
  }
}

class ValidatedSectionSelectionNotifier extends StateNotifier<String?> {
  final Ref _ref;
  String? _lastProjectId;

  ValidatedSectionSelectionNotifier(this._ref) : super(null);

  void setSelection(String? sectionId, String? projectId) {
    state = sectionId;
    _lastProjectId = projectId;
  }

  void resetIfProjectChanged(String? newProjectId) {
    if (_lastProjectId != newProjectId) {
      state = null;
      _lastProjectId = newProjectId;
    }
  }

  void _validateAndReset() {
    if (state != null && _lastProjectId != null) {
      final sectionBox = _ref.read(sectionBoxProvider);
      final section = sectionBox.get(state!);

      if (section == null || section.projectId != _lastProjectId) {
        state = null;
      }
    }
  }

  void forceReset() {
    state = null;
    _lastProjectId = null;
  }

  void validateCurrentSelection() {
    _validateAndReset();
  }
}

/// Provider để lấy thông tin project đã validated
final validatedProjectInfoProvider = Provider<Map<String, String?>?>((ref) {
  final projectId = ref.watch(validatedProjectSelectionProvider);

  if (projectId == null) return null;

  final projectBox = ref.watch(projectBoxProvider);
  final project = projectBox.get(projectId);

  if (project == null) {
    // Trigger auto-reset nếu project không tồn tại
    Future.microtask(() {
      ref.read(validatedProjectSelectionProvider.notifier).forceReset();
    });
    return null;
  }

  return {'id': project.id, 'name': project.name};
});

/// Provider để lấy thông tin section đã validated
final validatedSectionInfoProvider = Provider<Map<String, String?>?>((ref) {
  final sectionId = ref.watch(validatedSectionSelectionProvider);
  final projectId = ref.watch(validatedProjectSelectionProvider);

  if (sectionId == null) return null;

  final sectionBox = ref.watch(sectionBoxProvider);
  final section = sectionBox.get(sectionId);

  if (section == null || section.projectId != projectId) {
    // Trigger auto-reset nếu section không tồn tại hoặc không thuộc project hiện tại
    Future.microtask(() {
      ref.read(validatedSectionSelectionProvider.notifier).forceReset();
    });
    return null;
  }

  return {
    'id': section.id,
    'name': section.name,
    'projectId': section.projectId,
  };
});
