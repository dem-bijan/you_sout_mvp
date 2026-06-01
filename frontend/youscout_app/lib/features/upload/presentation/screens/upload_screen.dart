import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/upload_provider.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  final _descriptionCtrl = TextEditingController();
  final _hashtagCtrl     = TextEditingController();
  final _picker          = ImagePicker();

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    _hashtagCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final xfile = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 3),
    );
    if (xfile != null && mounted) {
      ref.read(uploadProvider.notifier).setFile(File(xfile.path));
    }
  }

  Future<void> _submit() async {
    await ref.read(uploadProvider.notifier).upload();
    if (!mounted) return;
    final state = ref.read(uploadProvider);
    if (state.status == UploadStatus.success) {
      ref.read(uploadProvider.notifier).reset();
      _descriptionCtrl.clear();
      _hashtagCtrl.clear();
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final upload = ref.watch(uploadProvider);
    final isUploading = upload.status == UploadStatus.uploading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Video'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: isUploading ? null : () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: (upload.canSubmit && !isUploading) ? _submit : null,
            child: Text(
              'Post',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: upload.canSubmit
                    ? AppColors.primary
                    : AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Video picker ────────────────────────────────────
                GestureDetector(
                  onTap: isUploading ? null : _pickVideo,
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: upload.selectedFile != null
                            ? AppColors.primary
                            : AppColors.borderDefault,
                        width: upload.selectedFile != null ? 1.5 : 0.5,
                      ),
                    ),
                    child: upload.selectedFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Container(color: Colors.black87),
                                const Center(
                                  child: Icon(
                                    Icons.videocam_rounded,
                                    color: AppColors.primary,
                                    size: 48,
                                  ),
                                ),
                                Positioned(
                                  bottom: 12,
                                  left: 0,
                                  right: 0,
                                  child: Text(
                                    upload.selectedFile!.path
                                        .split('/')
                                        .last,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGlow,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add_rounded,
                                  color: AppColors.primary,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Select Video',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'MP4, MOV — up to 3 minutes',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Description ─────────────────────────────────────
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionCtrl,
                  maxLines: 3,
                  maxLength: 300,
                  enabled: !isUploading,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Describe your skill…',
                    counterStyle:
                        TextStyle(color: AppColors.textTertiary, fontSize: 11),
                  ),
                  onChanged: (v) =>
                      ref.read(uploadProvider.notifier).setDescription(v),
                ),

                const SizedBox(height: 20),

                // ── Skills ──────────────────────────────────────────
                const Text(
                  'Skills',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                if (upload.availableSkills.isEmpty)
                  const Text(
                    'Loading skills…',
                    style: TextStyle(
                        color: AppColors.textTertiary, fontSize: 13),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: upload.availableSkills.map((skill) {
                      final selected =
                          upload.selectedSkillIds.contains(skill.id);
                      return GestureDetector(
                        onTap: isUploading
                            ? null
                            : () => ref
                                .read(uploadProvider.notifier)
                                .toggleSkill(skill.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.secondary.withOpacity(0.25)
                                : AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? AppColors.secondary
                                  : AppColors.borderSubtle,
                              width: selected ? 1.5 : 0.5,
                            ),
                          ),
                          child: Text(
                            skill.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? AppColors.secondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 20),

                // ── Hashtags ────────────────────────────────────────
                const Text(
                  'Hashtags',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _hashtagCtrl,
                  enabled: !isUploading,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: '#freestyle #dribbling',
                    prefixIcon: Icon(Icons.tag,
                        color: AppColors.textSecondary, size: 18),
                  ),
                  onChanged: (v) =>
                      ref.read(uploadProvider.notifier).setHashtags(v),
                ),

                // ── Error ────────────────────────────────────────────
                if (upload.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.like.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.like.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.like, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            upload.errorMessage!,
                            style: const TextStyle(
                                color: AppColors.like, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 100), // space above bottom sheet
              ],
            ),
          ),

          // ── Upload progress overlay ─────────────────────────────
          if (isUploading)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Container(
                    width: 240,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceOverlay,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_upload_outlined,
                            color: AppColors.primary, size: 40),
                        const SizedBox(height: 16),
                        const Text(
                          'Uploading…',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: upload.progress,
                            backgroundColor: AppColors.borderDefault,
                            color: AppColors.primary,
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(upload.progress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
