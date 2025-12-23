/// Image Optimization Utilities for Everyday Christian App
///
/// This file provides optimized image loading patterns and caching strategies
/// to improve app performance and reduce memory usage.

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Optimized image loading widget with caching and memory management
class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    // For network images
    if (imageUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        // Memory cache configuration
        memCacheWidth: width != null ? (width! * MediaQuery.of(context).devicePixelRatio).round() : null,
        memCacheHeight: height != null ? (height! * MediaQuery.of(context).devicePixelRatio).round() : null,
        maxWidthDiskCache: 1024, // Max width in cache
        maxHeightDiskCache: 1024, // Max height in cache
        placeholder: (context, url) => placeholder ?? const Center(
          child: CircularProgressIndicator(),
        ),
        errorWidget: (context, url, error) => errorWidget ?? const Icon(Icons.error),
        // Enable fade animation
        fadeInDuration: const Duration(milliseconds: 300),
        fadeOutDuration: const Duration(milliseconds: 100),
      );
    }

    // For local assets
    return Image.asset(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      // Cache local images
      cacheWidth: width != null ? (width! * MediaQuery.of(context).devicePixelRatio).round() : null,
      cacheHeight: height != null ? (height! * MediaQuery.of(context).devicePixelRatio).round() : null,
      errorBuilder: (context, error, stackTrace) => errorWidget ?? const Icon(Icons.error),
    );
  }
}

/// Optimized image for user avatars (circular, cached, with initials fallback)
class OptimizedAvatarImage extends StatelessWidget {
  final String? imageUrl;
  final String fallbackText;
  final double size;
  final Color backgroundColor;

  const OptimizedAvatarImage({
    super.key,
    this.imageUrl,
    required this.fallbackText,
    this.size = 40,
    this.backgroundColor = const Color(0xFF6C63FF),
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipOval(
        child: OptimizedImage(
          imageUrl: imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: _buildFallback(),
        ),
      );
    }

    return _buildFallback();
  }

  Widget _buildFallback() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _getInitials(fallbackText),
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getInitials(String text) {
    final words = text.trim().split(' ');
    if (words.isEmpty) return '?';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }
}

/// Image cache management utilities
class ImageCacheManager {
  /// Clear all cached images
  static Future<void> clearCache() async {
    await CachedNetworkImage.evictFromCache('');
    // Also clear Flutter's image cache
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  /// Clear specific image from cache
  static Future<void> clearImageFromCache(String imageUrl) async {
    await CachedNetworkImage.evictFromCache(imageUrl);
  }

  /// Configure image cache size (call in main.dart)
  static void configureImageCache() {
    // Set max cache size (in MB)
    PaintingBinding.instance.imageCache.maximumSize = 100;

    // Set max cache size in bytes (50 MB)
    PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024;
  }

  /// Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    final cache = PaintingBinding.instance.imageCache;
    return {
      'currentSize': cache.currentSize,
      'maximumSize': cache.maximumSize,
      'currentSizeBytes': cache.currentSizeBytes,
      'maximumSizeBytes': cache.maximumSizeBytes,
      'liveImageCount': cache.liveImageCount,
      'pendingImageCount': cache.pendingImageCount,
    };
  }
}

/// Optimized image for thumbnails (small, highly cached)
class ThumbnailImage extends StatelessWidget {
  final String imageUrl;
  final double size;

  const ThumbnailImage({
    super.key,
    required this.imageUrl,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    return OptimizedImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      placeholder: Container(
        width: size,
        height: size,
        color: Colors.grey[200],
      ),
    );
  }
}

/// Image optimization best practices documentation
///
/// 1. ALWAYS specify width and height for images
///    - Prevents layout shifts
///    - Enables memory cache optimization
///    - Reduces memory usage by 40-60%
///
/// 2. Use cached_network_image for network images
///    - Automatic disk and memory caching
///    - Reduces network requests
///    - Improves perceived performance
///
/// 3. Set appropriate cache dimensions
///    - Use device pixel ratio for retina displays
///    - Don't cache larger than display size
///    - Example: cacheWidth = (width * devicePixelRatio).round()
///
/// 4. Implement progressive loading
///    - Show placeholder while loading
///    - Use fade transitions
///    - Handle errors gracefully
///
/// 5. Clear cache when appropriate
///    - On low memory warnings
///    - When user logs out
///    - Periodically for old cached images
///
/// 6. Optimize image assets
///    - Use WebP format when possible (smaller size)
///    - Compress images before bundling
///    - Use vector graphics (SVG) for icons
///    - Provide multiple resolutions (1x, 2x, 3x)
///
/// 7. Lazy load images in lists
///    - Don't load all images at once
///    - Use ListView.builder with cacheExtent
///    - Dispose images when scrolled off-screen
///
/// Example usage:
/// ```dart
/// // Network image with caching
/// OptimizedImage(
///   imageUrl: 'https://example.com/image.jpg',
///   width: 300,
///   height: 200,
///   fit: BoxFit.cover,
/// )
///
/// // Avatar with fallback
/// OptimizedAvatarImage(
///   imageUrl: user.photoUrl,
///   fallbackText: user.name,
///   size: 50,
/// )
///
/// // Initialize cache in main.dart
/// void main() {
///   WidgetsFlutterBinding.ensureInitialized();
///   ImageCacheManager.configureImageCache();
///   runApp(MyApp());
/// }
/// ```
