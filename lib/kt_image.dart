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

abstract class _ImageType {
  const _ImageType();

  @override
  String toString() {
    return this.runtimeType.toString();
  }
}

class _NetWork extends _ImageType {
  final bool cache;
  final int retries;
  final String url;

  _NetWork(this.cache, this.retries, this.url);
}

class _Asset extends _ImageType {
  final String assetName;

  const _Asset(this.assetName);
}

class _Memory extends _ImageType {
  final Uint8List bytes;

  const _Memory(this.bytes);
}

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

  ///是否要计算宽高 如果有给宽高值，该字段无效
  final bool computeSize;

  ///如果宽高或者约束会比实际图片的大，这时候应该被展示的位置 倍率
  final Alignment align;

  ///基于绘制后图片的缩放倍率，默认是2倍
  final int defaultMagnification;

  final _ImageType _type;

  TkImage.network(
    String url, {
    Key? key,
    int retries = 3,
    bool cache = true,
    this.width,
    this.height,
    this.loadingBuilder,
    this.loadFailedBuilder,
    this.align = Alignment.center,
    this.defaultMagnification = 4,
    this.computeSize = true,
    this.enableMemoryCache = false,
    this.clearMemoryCacheIfFailed = true,
    this.clearMemoryCacheWhenDispose = true,
    this.fit,
    this.borderRadius,
    this.maxBytes,
  })  : _type = _NetWork(cache, retries, url),
        super(key: key);

  TkImage.memory(
    Uint8List bytes, {
    Key? key,
    this.width,
    this.height,
    this.loadingBuilder,
    this.loadFailedBuilder,
    this.align = Alignment.center,
    this.defaultMagnification = 4,
    this.computeSize = true,
    this.enableMemoryCache = false,
    this.clearMemoryCacheIfFailed = true,
    this.clearMemoryCacheWhenDispose = true,
    this.fit,
    this.borderRadius,
    this.maxBytes,
  })  : _type = _Memory(bytes),
        super(key: key);

  TkImage.asset(
    String assetName, {
    Key? key,
    this.width,
    this.height,
    this.loadingBuilder,
    this.loadFailedBuilder,
    this.align = Alignment.center,
    this.defaultMagnification = 4,
    this.computeSize = true,
    this.enableMemoryCache = false,
    this.clearMemoryCacheIfFailed = true,
    this.clearMemoryCacheWhenDispose = true,
    this.fit,
    this.borderRadius,
    this.maxBytes,
  })  : _type = _Asset(assetName),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final AnimationController controller = useAnimationController(
      duration: Duration(milliseconds: 300),
    );
    bool useSize;
    if (width != null && height != null) {
      useSize = true;
    } else {
      useSize = !computeSize;
    }
    debugPrint(
        "$this $_type size:(width:$width,height:$height),computeSize:$computeSize}");
    if (!useSize) {
      return LayoutBuilder(
        builder: (context, constraint) =>
            _buildImageByType(controller, context, constraint),
      );
    } else {
      assert(width != null && height != null);
      return _buildImageByType(controller, context,
          BoxConstraints(maxWidth: width!, maxHeight: height!));
    }
  }

  ///根据类型构建ImageProvider
  Widget _buildImageByType(AnimationController controller, BuildContext context,
      BoxConstraints boxConstraints) {
    debugPrint("$this $_type boxConstraints:$boxConstraints");
    final int realMaxBytes = maxBytes ??
        (boxConstraints.maxWidth *
                boxConstraints.maxHeight *
                4 *
                defaultMagnification)
            .round();
    ImageProvider imageProvider;
    if (_type is _NetWork) {
      final _NetWork config = _type as _NetWork;
      imageProvider = AutoResizeImage.resizeIfNeeded(
        provider: ExtendedNetworkImageProvider(
          config.url,
          cache: config.cache,
          retries: config.retries,
        ),
        maxBytes: realMaxBytes,
        cacheWidth: width?.round(),
        cacheHeight: height?.round(),
      );
    } else if (_type is _Asset) {
      final _Asset config = _type as _Asset;
      imageProvider = AutoResizeImage.resizeIfNeeded(
        provider: ExtendedAssetImageProvider(config.assetName),
        maxBytes: realMaxBytes,
        cacheWidth: width?.round(),
        cacheHeight: height?.round(),
      );
    } else {
      final _Memory config = _type as _Memory;
      imageProvider = AutoResizeImage.resizeIfNeeded(
        provider: ExtendedMemoryImageProvider(config.bytes),
        maxBytes: realMaxBytes,
        cacheWidth: width?.round(),
        cacheHeight: height?.round(),
      );
    }
    return _buildExtendedImage(
        controller, context, boxConstraints, imageProvider);
  }

  ///构建ExtendedImage
  Widget _buildExtendedImage(
      AnimationController controller,
      BuildContext context,
      BoxConstraints boxConstraints,
      ImageProvider imageProvider) {
    final double realWidth = boxConstraints.maxWidth;
    final double realHeight = boxConstraints.maxHeight;
    return ExtendedImage(
      image: imageProvider,
      width: realWidth,
      height: realHeight,
      alignment: align,
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
                _buildDefaultPlaceholder(realWidth, realHeight);

          case LoadState.completed:
            controller.forward();
            final Widget rawImage = ExtendedRawImage(
              image: state.extendedImageInfo?.image,
              fit: fit,
              width: realWidth,
              height: realHeight,
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
                _buildDefaultPlaceholder(realWidth, realHeight);
        }
      },
    );
  }

  Widget _buildDefaultPlaceholder(double width, double height) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
        ),
      );
}