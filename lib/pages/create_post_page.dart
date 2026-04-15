import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';

import '../models/post_model.dart';
import '../providers/discover_provider.dart';

class CreatePostPage extends ConsumerStatefulWidget {
  const CreatePostPage({super.key});

  @override
  ConsumerState<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends ConsumerState<CreatePostPage> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  final List<PostMedia> _selectedImages = [];
  PostMedia? _selectedVideo;
  bool _showLocationInput = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _contentController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  List<PostMedia> get _selectedMedia =>
      _selectedVideo != null ? [_selectedVideo!] : _selectedImages;

  Future<void> _showMediaPickerSheet() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PickerTile(
                  icon: Icons.photo_library_outlined,
                  title: '从相册选择图片',
                  subtitle: '最多 9 张，不可与视频混传',
                  onTap: () => Navigator.of(context).pop('album-image'),
                ),
                const SizedBox(height: 12),
                _PickerTile(
                  icon: Icons.video_library_outlined,
                  title: '从相册选择视频',
                  subtitle: '仅支持 1 个视频，不可与图片混传',
                  onTap: () => Navigator.of(context).pop('album-video'),
                ),
                const SizedBox(height: 12),
                _PickerTile(
                  icon: Icons.photo_camera_outlined,
                  title: '直接拍照上传',
                  subtitle: '拍摄后直接加入帖子',
                  onTap: () => Navigator.of(context).pop('camera-image'),
                ),
                const SizedBox(height: 12),
                _PickerTile(
                  icon: Icons.videocam_outlined,
                  title: '直接拍视频上传',
                  subtitle: '录制单个视频加入帖子',
                  onTap: () => Navigator.of(context).pop('camera-video'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || action == null) {
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 120));

    switch (action) {
      case 'album-image':
        await _pickImagesFromAssets();
        return;
      case 'album-video':
        await _pickVideoFromAssets();
        return;
      case 'camera-image':
        await _capturePhoto();
        return;
      case 'camera-video':
        await _captureVideo();
        return;
    }
  }

  Future<void> _pickImagesFromAssets() async {
    if (_selectedVideo != null) {
      _showMessage('已选择视频，不能再添加图片');
      return;
    }

    final remaining = 9 - _selectedImages.length;
    if (remaining <= 0) {
      _showMessage('最多选择 9 张图片');
      return;
    }

    final assets = await AssetPicker.pickAssets(
      context,
      pickerConfig: AssetPickerConfig(
        maxAssets: remaining,
        requestType: RequestType.image,
        selectedAssets: const [],
      ),
    );

    if (!mounted || assets == null || assets.isEmpty) {
      return;
    }

    final medias = await _convertAssetsToImages(assets);
    if (!mounted || medias.isEmpty) {
      return;
    }

    setState(() {
      _selectedImages.addAll(medias);
    });
  }

  Future<void> _pickVideoFromAssets() async {
    if (_selectedImages.isNotEmpty) {
      _showMessage('已选择图片，不能再添加视频');
      return;
    }

    final assets = await AssetPicker.pickAssets(
      context,
      pickerConfig: const AssetPickerConfig(
        maxAssets: 1,
        requestType: RequestType.video,
      ),
    );

    if (!mounted || assets == null || assets.isEmpty) {
      return;
    }

    final media = await _convertAssetToVideo(assets.first);
    if (!mounted || media == null) {
      return;
    }

    setState(() {
      _selectedVideo = media;
    });
  }

  Future<void> _capturePhoto() async {
    if (_selectedVideo != null) {
      _showMessage('已选择视频，不能再添加图片');
      return;
    }
    if (_selectedImages.length >= 9) {
      _showMessage('最多选择 9 张图片');
      return;
    }

    final entity = await CameraPicker.pickFromCamera(
      context,
      pickerConfig: const CameraPickerConfig(
        enableRecording: false,
      ),
    );

    if (!mounted || entity == null) {
      return;
    }

    final file = await entity.file;
    if (!mounted || file == null) {
      _showMessage('拍照结果读取失败');
      return;
    }

    setState(() {
      _selectedImages.add(PostMedia.image(url: file.path, isLocal: true));
    });
  }

  Future<void> _captureVideo() async {
    if (_selectedImages.isNotEmpty) {
      _showMessage('已选择图片，不能再添加视频');
      return;
    }

    final entity = await CameraPicker.pickFromCamera(
      context,
      pickerConfig: const CameraPickerConfig(
        enableRecording: true,
        onlyEnableRecording: true,
      ),
    );

    if (!mounted || entity == null) {
      return;
    }

    final media = await _convertAssetToVideo(entity);
    if (!mounted || media == null) {
      _showMessage('视频读取失败');
      return;
    }

    setState(() {
      _selectedVideo = media;
    });
  }

  Future<List<PostMedia>> _convertAssetsToImages(List<AssetEntity> assets) async {
    final result = <PostMedia>[];

    for (final asset in assets) {
      final file = await asset.file;
      if (file == null) {
        continue;
      }
      result.add(PostMedia.image(url: file.path, isLocal: true));
    }

    return result;
  }

  Future<PostMedia?> _convertAssetToVideo(AssetEntity asset) async {
    final file = await asset.file;
    if (file == null) {
      return null;
    }

    final minutes = (asset.duration ~/ 60).toString().padLeft(2, '0');
    final seconds = (asset.duration % 60).toString().padLeft(2, '0');

    return PostMedia.video(
      url: file.path,
      thumbnailUrl: '',
      durationLabel: '$minutes:$seconds',
      isLocal: true,
    );
  }

  void _removeImageAt(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _removeVideo() {
    setState(() {
      _selectedVideo = null;
    });
  }

  void _submit() {
    final content = _contentController.text.trim();
    final location = _locationController.text.trim();
    final messenger = ScaffoldMessenger.of(context);

    if (content.isEmpty && _selectedMedia.isEmpty) {
      _showMessage('正文、图片或视频至少填写一项');
      return;
    }
    if (_isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    ref.read(discoverProvider.notifier).addPost(
          content: content,
          media: List<PostMedia>.from(_selectedMedia),
          location: location,
        );

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('发布成功')),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasMedia = _selectedMedia.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text('New poster'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF34C759),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _contentController,
            minLines: 8,
            maxLines: 12,
            decoration: InputDecoration(
              hintText:
                  'You could share a recent experience, learning tips, or some interesting thoughts...',
              filled: true,
              fillColor: const Color(0xFFF5F6F8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(18),
            ),
          ),
          const SizedBox(height: 16),
          if (!hasMedia)
            _AddMediaButton(onTap: _showMediaPickerSheet)
          else if (_selectedVideo != null)
            _SelectedVideoCard(
              media: _selectedVideo!,
              onRemove: _removeVideo,
            )
          else
            _SelectedImageGrid(
              images: _selectedImages,
              onRemove: _removeImageAt,
              onAddMore: _selectedImages.length >= 9 ? null : _showMediaPickerSheet,
            ),
          const SizedBox(height: 14),
          const Text(
            'Add up to 9 photos or 1 video. You can choose from the album or capture directly.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF9CA3AF),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              const _ActionChip(
                icon: Icons.tag_rounded,
                label: 'Topic',
              ),
              _ActionChip(
                icon: Icons.location_on_outlined,
                label: _locationController.text.isEmpty
                    ? 'Add location'
                    : _locationController.text,
                accent: true,
                onTap: () {
                  setState(() {
                    _showLocationInput = true;
                  });
                },
              ),
              const _ActionChip(
                icon: Icons.bar_chart_rounded,
                label: 'Add poll',
                leadingDot: true,
              ),
            ],
          ),
          if (_showLocationInput) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: 'Enter location',
                filled: true,
                fillColor: const Color(0xFFF5F6F8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _locationController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          setState(() {
                            _locationController.clear();
                          });
                        },
                        icon: const Icon(Icons.close_rounded),
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ],
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      tileColor: const Color(0xFFF5F6F8),
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}

class _AddMediaButton extends StatelessWidget {
  const _AddMediaButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 132,
        height: 132,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6F8),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.photo_camera_outlined,
              size: 42,
              color: Color(0xFF374151),
            ),
            Positioned(
              right: 32,
              bottom: 28,
              child: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFF34C759),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedImageGrid extends StatelessWidget {
  const _SelectedImageGrid({
    required this.images,
    required this.onRemove,
    this.onAddMore,
  });

  final List<PostMedia> images;
  final ValueChanged<int> onRemove;
  final VoidCallback? onAddMore;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ...List.generate(images.length, (index) {
          return _MediaThumb(
            path: images[index].url,
            isVideo: false,
            onRemove: () => onRemove(index),
          );
        }),
        if (onAddMore != null)
          GestureDetector(
            onTap: onAddMore,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6F8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.add_rounded, color: Color(0xFF34C759)),
            ),
          ),
      ],
    );
  }
}

class _SelectedVideoCard extends StatelessWidget {
  const _SelectedVideoCard({
    required this.media,
    required this.onRemove,
  });

  final PostMedia media;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return _MediaThumb(
      path: media.url,
      isVideo: true,
      onRemove: onRemove,
      width: 180,
      height: 132,
      durationLabel: media.durationLabel,
    );
  }
}

class _MediaThumb extends StatelessWidget {
  const _MediaThumb({
    required this.path,
    required this.isVideo,
    required this.onRemove,
    this.width = 100,
    this.height = 100,
    this.durationLabel,
  });

  final String path;
  final bool isVideo;
  final VoidCallback onRemove;
  final double width;
  final double height;
  final String? durationLabel;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: isVideo ? const Color(0xFF111827) : const Color(0xFFF5F6F8),
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: isVideo
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(color: const Color(0xFF111827)),
                    const Icon(
                      Icons.videocam_rounded,
                      size: 34,
                      color: Colors.white70,
                    ),
                    if (durationLabel != null)
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            durationLabel!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                )
              : Image.file(
                  File(path),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Container(
                      color: const Color(0xFFF5F6F8),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        color: Color(0xFF9CA3AF),
                      ),
                    );
                  },
                ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    this.leadingDot = false,
    this.accent = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool leadingDot;
  final bool accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6F8),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingDot) ...[
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF34C759),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(icon, size: 18, color: const Color(0xFF111827)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: accent ? const Color(0xFF34C759) : const Color(0xFF111827),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
