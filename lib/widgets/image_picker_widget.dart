import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/app_theme.dart';
import 'trip_image.dart';

class ImagePickerWidget extends StatefulWidget {
  final String? initialUrl;
  final String storagePath; // Kept for compatibility, but unused
  final ValueChanged<String> onImageUpload;
  final double height;

  const ImagePickerWidget({
    super.key,
    this.initialUrl,
    required this.storagePath,
    required this.onImageUpload,
    this.height = 180,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  String? _url;
  bool _processing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _url = widget.initialUrl;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800, // Important for Firestore size limits
        maxHeight: 800,
        imageQuality: 70, // Significant compression for Firestore
      );

      if (picked == null) return;

      setState(() {
        _processing = true;
        _error = null;
      });

      // Convert image to Base64 instead of uploading to Storage
      final bytes = await picked.readAsBytes();
      final base64String = base64Encode(bytes);
      final dataUrl = 'data:image/jpeg;base64,$base64String';

      if (mounted) {
        setState(() {
          _url = dataUrl;
          _processing = false;
        });
        widget.onImageUpload(dataUrl);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _processing = false;
          _error = 'Processing failed: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _processing ? null : _pickImage,
          child: Container(
            height: widget.height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.bg2,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _processing
                    ? AppTheme.primary
                    : (_error != null ? AppTheme.danger : AppTheme.border),
                width: 1.5,
              ),
              boxShadow: [
                if (_processing)
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: Stack(
              children: [
                // Display using our new smart widget
                if (_url != null && _url!.isNotEmpty)
                  TripImage(
                    imageUrl: _url!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),

                // Overlay / Placeholder
                Container(
                  color: (_url == null || _url!.isEmpty)
                      ? Colors.transparent
                      : Colors.black38,
                  child: Center(
                    child: _processing
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                (_url == null || _url!.isEmpty)
                                    ? Icons.add_photo_alternate_rounded
                                    : Icons.camera_alt_rounded,
                                size: 32,
                                color: (_url == null || _url!.isEmpty)
                                    ? AppTheme.textMuted
                                    : Colors.white,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                (_url == null || _url!.isEmpty)
                                    ? 'Add from Gallery'
                                    : 'Change Image',
                                style: TextStyle(
                                  color: (_url == null || _url!.isEmpty)
                                      ? AppTheme.textMuted
                                      : Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              if (_url != null && _url!.isNotEmpty)
                                const Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: Text(
                                    '(Stored in Firestore)',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.danger.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppTheme.danger, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style:
                        const TextStyle(color: AppTheme.danger, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
