import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// A circular avatar that caches network images for offline use.
/// Falls back to a placeholder while loading and an error icon on failure.
class CachedAvatar extends StatelessWidget {
  final String imageUrl;
  final double size;
  final BoxFit fit;

  const CachedAvatar({
    super.key,
    required this.imageUrl,
    this.size = 50,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: size,
        height: size,
        fit: fit,
        placeholder: (context, url) => Container(
          width: size,
          height: size,
          color: Colors.grey.shade200,
          child: Center(
            child: SizedBox(
              width: size * 0.3,
              height: size * 0.3,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.grey.shade400,
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: size,
          height: size,
          color: Colors.grey.shade200,
          child: Icon(
            LucideIcons.user,
            size: size * 0.5,
            color: Colors.grey.shade500,
          ),
        ),
      ),
    );
  }
}
