import 'dart:typed_data';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_image_cache_demo/auto_resize_image.dart';

typedef ImageLoadingBuilder = Widget Function(
  BuildContext context,
  ImageChunkEvent? chunkEvent,
);

typedef ImageLoadFailedBuilder = Widget Function(
  BuildContext context,
  StackTrace? stackTrace,
);

class TkImage extends HookWidget {
  final double? width;
  final double? height;

  ///是否缓存在内存中(PaintingBinding.instance.imageCache)
  final bool enableMemoryCache;

  ///加载图像失败时，是否清除内存缓存如果为true，图像将在下次重新加载。
  final bool clearMemoryCacheIfFailed;

  ///当图像从树中dispose时，是否清除内存缓存,
  final bool clearMemoryCacheWhenDispose;
  final BoxFit? fit;
  final BorderRadius? borderRadius;

  ///内存最大缓存字节大小 一般情况(ARGB_8888)计算方式为width*height*4,但实际的值会
  ///比这个小，maxBytes >> 2 也就是maxBytes/4的大小，对应的实际宽高也会按比例缩小
  ///详见[AutoResizeImage._resize]
  final int? maxBytes;
  final ImageLoadingBuilder? loadingBuilder;
  final ImageLoadFailedBuilder? loadFailedBuilder;
  final ImageProvider _provider;

  TkImage.network(
    String url, {
    Key? key,
    int retries = 3,
    bool cache = true,
    this.width,
    this.height,
    this.loadingBuilder,
    this.loadFailedBuilder,
    this.enableMemoryCache = true,
    this.clearMemoryCacheIfFailed = true,
    this.clearMemoryCacheWhenDispose = true,
    this.fit,
    this.borderRadius,
    this.maxBytes,
  })  : assert((maxBytes != null && maxBytes > 0) ||
            width != null && height != null),
        _provider = AutoResizeImage.resizeIfNeeded(
          provider: ExtendedNetworkImageProvider(
            url,
            cache: cache,
            retries: retries,
          ),
          maxBytes: maxBytes ?? (width! * height! * 40).round(),
          cacheWidth: width?.round(),
          cacheHeight: height?.round(),
        ),
        super(key: key);

  TkImage.memory(
    Uint8List bytes, {
    Key? key,
    this.width,
    this.height,
    this.loadingBuilder,
    this.loadFailedBuilder,
    this.enableMemoryCache = true,
    this.clearMemoryCacheIfFailed = true,
    this.clearMemoryCacheWhenDispose = true,
    this.fit,
    this.borderRadius,
    this.maxBytes,
  })  : assert((maxBytes != null && maxBytes > 0) ||
            width != null && height != null),
        _provider = AutoResizeImage.resizeIfNeeded(
          provider: ExtendedMemoryImageProvider(bytes),
          maxBytes: maxBytes ?? (width! * height! * 4).round(),
          cacheWidth: width?.round(),
          cacheHeight: height?.round(),
        ),
        super(key: key);

  TkImage.asset(
    String assetName, {
    Key? key,
    this.width,
    this.height,
    this.loadingBuilder,
    this.loadFailedBuilder,
    this.enableMemoryCache = true,
    this.clearMemoryCacheIfFailed = true,
    this.clearMemoryCacheWhenDispose = true,
    this.fit,
    this.borderRadius,
    this.maxBytes,
  })  : assert((maxBytes != null && maxBytes > 0) ||
            width != null && height != null),
        _provider = AutoResizeImage.resizeIfNeeded(
          provider: ExtendedAssetImageProvider(assetName),
          maxBytes: maxBytes ?? (width! * height! * 4).round(),
          cacheWidth: width?.round(),
          cacheHeight: height?.round(),
        ),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final AnimationController controller = useAnimationController(
      duration: Duration(milliseconds: 300),
    );
    return ExtendedImage(
      image: _provider,
      width: width,
      height: height,
      fit: fit,
      enableMemoryCache: enableMemoryCache,
      clearMemoryCacheWhenDispose: clearMemoryCacheWhenDispose,
      clearMemoryCacheIfFailed: clearMemoryCacheIfFailed,
      borderRadius: borderRadius,
      loadStateChanged: (state) {
        switch (state.extendedImageLoadState) {
          case LoadState.loading:
            controller.reset();
            return loadingBuilder?.call(context, state.loadingProgress) ??
                _buildDefaultPlaceholder();

          case LoadState.completed:
            controller.forward();
            final Widget rawImage = ExtendedRawImage(
              image: state.extendedImageInfo?.image,
              fit: fit,
              width: width,
              height: height,
            );
            return FadeTransition(
              opacity: controller,
              child: borderRadius == null
                  ? rawImage
                  : ClipRRect(
                      borderRadius: borderRadius,
                      child: rawImage,
                    ),
            );
          case LoadState.failed:
            controller.reset();
            return loadFailedBuilder?.call(context, state.lastStack) ??
                _buildDefaultPlaceholder();
        }
      },
    );
  }

  Widget _buildDefaultPlaceholder() => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
        ),
      );
}
