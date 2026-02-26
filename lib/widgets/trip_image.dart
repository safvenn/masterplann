import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/app_theme.dart';

class TripImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final Widget? fallback;

  const TripImage({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildError();
    }

    // Check if it's a Base64 string
    if (imageUrl!.startsWith('data:image') || !imageUrl!.startsWith('http')) {
      try {
        String base64Str = imageUrl!;
        if (base64Str.contains(',')) {
          base64Str = base64Str.split(',').last;
        }
        final Uint8List bytes = base64Decode(base64Str);
        return _wrap(Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => _buildError(),
        ));
      } catch (e) {
        return _buildError();
      }
    }

    // Otherwise treat as Network Image
    return _wrap(CachedNetworkImage(
      imageUrl: imageUrl!,
      width: width,
      height: height,
      fit: fit,
      placeholder: (_, __) => Shimmer.fromColors(
        baseColor: AppTheme.bg2,
        highlightColor: AppTheme.card,
        child: Container(
          width: width ?? double.infinity,
          height: height ?? double.infinity,
          color: AppTheme.bg2,
        ),
      ),
      errorWidget: (_, __, ___) => _buildError(),
    ));
  }

  Widget _wrap(Widget child) {
    if (borderRadius > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: child,
      );
    }
    return child;
  }

  Widget _buildError() {
    if (fallback != null) return fallback!;
    return Container(
      width: width,
      height: height,
      color: AppTheme.bg2,
      child: const Center(
        child: Icon(Icons.broken_image_rounded,
            color: AppTheme.textMuted, size: 24),
      ),
    );
  }
}
