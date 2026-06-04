import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youscout_app/features/upload/data/upload_repository.dart';
import 'package:youscout_app/features/feed/data/models/video_model.dart';

// ── State ─────────────────────────────────────────────────────────────────────

enum UploadStatus { idle, uploading, success, error }

class UploadState {
  final File? selectedFile;
  final String description;
  final List<SkillModel> availableSkills;
  final Set<String> selectedSkillIds;
  final List<String> hashtags;
  final UploadStatus status;
  final double progress; // 0.0 – 1.0
  final String? errorMessage;

  const UploadState({
    this.selectedFile,
    this.description = '',
    this.availableSkills = const [],
    this.selectedSkillIds = const {},
    this.hashtags = const [],
    this.status = UploadStatus.idle,
    this.progress = 0.0,
    this.errorMessage,
  });

  bool get canSubmit =>
      selectedFile != null &&
      description.trim().isNotEmpty &&
      status != UploadStatus.uploading;

  UploadState copyWith({
    File? selectedFile,
    String? description,
    List<SkillModel>? availableSkills,
    Set<String>? selectedSkillIds,
    List<String>? hashtags,
    UploadStatus? status,
    double? progress,
    String? errorMessage,
  }) =>
      UploadState(
        selectedFile: selectedFile ?? this.selectedFile,
        description: description ?? this.description,
        availableSkills: availableSkills ?? this.availableSkills,
        selectedSkillIds: selectedSkillIds ?? this.selectedSkillIds,
        hashtags: hashtags ?? this.hashtags,
        status: status ?? this.status,
        progress: progress ?? this.progress,
        errorMessage: errorMessage,
      );

  UploadState reset() => const UploadState();
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class UploadNotifier extends Notifier<UploadState> {
  @override
  UploadState build() {
    // Fetch available skills as soon as this notifier is created
    Future.microtask(_loadSkills);
    return const UploadState();
  }

  UploadRepository get _repo => ref.read(uploadRepositoryProvider);

  Future<void> _loadSkills() async {
    try {
      final skills = await _repo.fetchSkills();
      state = state.copyWith(availableSkills: skills);
    } catch (_) {
      // Non-fatal — skills just won't show
    }
  }

  void setFile(File file) => state = state.copyWith(selectedFile: file);

  void setDescription(String text) =>
      state = state.copyWith(description: text);

  void toggleSkill(String skillId) {
    final updated = Set<String>.from(state.selectedSkillIds);
    if (updated.contains(skillId)) {
      updated.remove(skillId);
    } else {
      updated.add(skillId);
    }
    state = state.copyWith(selectedSkillIds: updated);
  }

  void setHashtags(String raw) {
    // Accept comma-separated or space-separated, strip leading #
    final tags = raw
        .split(RegExp(r'[,\s]+'))
        .map((t) => t.trim().replaceFirst('#', ''))
        .where((t) => t.isNotEmpty)
        .toList();
    state = state.copyWith(hashtags: tags);
  }

  Future<void> upload() async {
    if (!state.canSubmit) return;

    state = state.copyWith(status: UploadStatus.uploading, progress: 0.0);

    try {
      await _repo.uploadVideo(
        file: state.selectedFile!,
        description: state.description,
        skillIds: state.selectedSkillIds.toList(),
        hashtags: state.hashtags,
        onProgress: (p) => state = state.copyWith(progress: p),
      );
      state = state.copyWith(status: UploadStatus.success, progress: 1.0);
    } catch (e) {
      state = state.copyWith(
        status: UploadStatus.error,
        errorMessage: 'Upload failed. Please try again.',
      );
    }
  }

  void reset() => state = const UploadState();
}

// ── Provider ──────────────────────────────────────────────────────────────────

final uploadProvider = NotifierProvider<UploadNotifier, UploadState>(
  UploadNotifier.new,
);
