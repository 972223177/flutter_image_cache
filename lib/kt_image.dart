import 'dart:collection';
import 'dart:typed_data';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_cache_demo/auto_resize_image.dart';
import 'package:flutter_image_cache_demo/media_data.dart';

typedef ImageLoadingBuilder = Widget Function(
  BuildContext context,
  ImageChunkEvent? chunkEvent,
);

typedef ImageLoadFailedBuilder = Widget Function(
  BuildContext context,
  Object? error,
  StackTrace? stackTrace,
);

typedef ImageLoadWrapper = Widget Function(Widget loadWidget);

const Duration _KDefaultDuration = const Duration(milliseconds: 300);
const Duration _KNonAnim = const Duration(milliseconds: 0);
const double _KDefaultCompressRatio = .5;

///可以对图片进行内存管理，具体可以看[enableMemoryCache]、[clearMemoryCacheWhenDispose]、[clearMemoryCacheIfFailed]这几个字段；
///如果要对图片进行内存大小优化可以看[upperLimitRatio]、[enableCompress]、[compressionRatio]这几个字段。
///如果要使用ImageProvider，请使用[TkImageProvider]
///当需要使用屏幕宽高时，最好不要使用double.infinite，使用MediaQueryData.fromWindow(WidgetsBinding.instance.window).size,
///尽量使用明确的宽高值，防止constraint出现infinite或者null时无法算出缓存大小（尽管使用LayoutBuilder，某些情况下仍然无法获得有正确值的宽高）。
///当出现infinite或者null时，会使用原图分辨率，可能使得缓存优化失效（也受[compressionRatio]影响）。
class TkImage extends StatefulWidget {
  final double? width;
  final double? height;

  ///是否缓存在内存中[PaintingBinding.instance.imageCache]
  final bool enableMemoryCache;

  ///加载图像失败时，是否清除内存缓存如果为true，图像将在下次重新加载。
  final bool clearMemoryCacheIfFailed;

  ///当图像从树中dispose时，是否清除内存缓存,
  final bool clearMemoryCacheWhenDispose;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  final ImageLoadingBuilder? loadingBuilder;
  final ImageLoadFailedBuilder? loadFailedBuilder;

  ///如果宽高或者约束会比实际图片的大，这时候应该被展示的位置
  final Alignment align;

  final ImageProvider imageProvider;

  ///布局约束
  final BoxConstraints? constraints;

  ///是否使用动画
  final bool useFadeAnim;

  final BoxShape shape;

  final BoxBorder? border;

  /// 是否继续显示旧图像（true），如果为false，图片源发生改变
  /// 会重走loadStateChanged;
  final bool gaplessPlayback;

  ///0<[compressionRatio]<1,基于原图的压缩比例。注意是原图的分辨率，如果有值其他压缩属性无效
  ///注意：该值在无法得到正确的宽高时会生效。
  final double compressionRatio;

  ///是否要进行压缩，true的话，会根据[upperLimitRatio]、[compressionRatio]对图片进行
  ///实际view大小调整，以降低图片在内存中的占用；false的话,这几个属性就无效，加载原图。
  ///实际情况按需使用。
  final bool enableCompress;

  ///该字段一般不需要自定义。
  ///如果view的宽高乘以这个比例为结果为原图压缩后所能接受的下限值，如果这个下限值大于原图的话，就会显示原图。
  ///
  ///满足上述条件后，如果[compressionRatio]有值，但算出的比例仍然小于上限值，则会对[compressionRatio]进行递增重算宽高
  ///直至压缩后的图size大于该上限。
  ///默认为设备的像素比例(devicePixelRatio)
  final double? upperLimitRatio;

  ///是否要将设置于图片的部分属性包裹于loadBuilder([loadingBuilder],[loadFailedBuilder])的widget中，例如Radius，true的话会在上述builder外部包裹ClipRRect
  ///这将会改变loadBuilder返回的Widget显示,默认false
  final bool enableWrapBuilder;

  ///当[enableWrapBuilder]为true时，但该func是空的话，默认会以[_buildDefaultPlaceholder]包裹
  final ImageLoadWrapper? wrapperBuilder;

  final bool clearCacheWhenScopeDisposed;

  TkImage.network(
    String url, {
    Key? key,
    int retries = 3,
    bool cache = true,
    this.width,
    this.height,
    this.loadingBuilder,
    this.loadFailedBuilder,
    this.useFadeAnim = true,
    this.shape = BoxShape.rectangle,
    this.border,
    this.wrapperBuilder,
    this.upperLimitRatio,
    this.gaplessPlayback = false,
    this.enableCompress = true,
    this.enableWrapBuilder = false,
    this.align = Alignment.center,
    this.clearCacheWhenScopeDisposed = true,
    this.compressionRatio = _KDefaultCompressRatio,
    this.enableMemoryCache = true,
    this.clearMemoryCacheIfFailed = true,
    this.clearMemoryCacheWhenDispose = true,
    this.fit = BoxFit.contain,
    this.borderRadius,
    BoxConstraints? constraints,
  })  : imageProvider =
            TkImageProvider.network(url, cache: cache, retries: retries),
        constraints = (width != null || height != null)
            ? constraints?.tighten(width: width, height: height) ??
                BoxConstraints.tightFor(width: width, height: height)
            : constraints,
        super(key: key);

  TkImage.memory(
    Uint8List bytes, {
    Key? key,
    this.width,
    this.height,
    this.loadingBuilder,
    this.loadFailedBuilder,
    this.align = Alignment.center,
    this.shape = BoxShape.rectangle,
    this.border,
    this.wrapperBuilder,
    this.upperLimitRatio,
    this.gaplessPlayback = false,
    this.enableWrapBuilder = false,
    this.enableCompress = true,
    this.compressionRatio = _KDefaultCompressRatio,
    this.clearCacheWhenScopeDisposed = true,
    this.useFadeAnim = true,
    this.enableMemoryCache = true,
    this.clearMemoryCacheIfFailed = true,
    this.clearMemoryCacheWhenDispose = true,
    this.fit = BoxFit.contain,
    this.borderRadius,
    BoxConstraints? constraints,
  })  : imageProvider = TkImageProvider.memory(bytes),
        constraints = (width != null || height != null)
            ? constraints?.tighten(width: width, height: height) ??
                BoxConstraints.tightFor(width: width, height: height)
            : constraints,
        super(key: key);

  ///注意这里默认不对asset资源进行缓存，也不会对asset资源压缩显示
  TkImage.asset(
    String assetName, {
    Key? key,
    this.width,
    this.height,
    this.loadingBuilder,
    this.loadFailedBuilder,
    this.align = Alignment.center,
    this.shape = BoxShape.rectangle,
    this.border,
    this.wrapperBuilder,
    this.upperLimitRatio,
    this.gaplessPlayback = false,
    this.enableWrapBuilder = false,
    this.enableCompress = true,
    this.compressionRatio = _KDefaultCompressRatio,
    this.clearCacheWhenScopeDisposed = true,
    this.useFadeAnim = true,
    this.enableMemoryCache = false,
    this.clearMemoryCacheIfFailed = true,
    this.clearMemoryCacheWhenDispose = false,
    this.fit = BoxFit.contain,
    this.borderRadius,
    BoxConstraints? constraints,
  })  : imageProvider = TkImageProvider.asset(assetName),
        constraints = (width != null || height != null)
            ? constraints?.tighten(width: width, height: height) ??
                BoxConstraints.tightFor(width: width, height: height)
            : constraints,
        super(key: key);

  TkImage.file(
    File file, {
    Key? key,
    this.width,
    this.height,
    this.loadingBuilder,
    this.loadFailedBuilder,
    this.align = Alignment.center,
    this.shape = BoxShape.rectangle,
    this.border,
    this.wrapperBuilder,
    this.upperLimitRatio,
    this.gaplessPlayback = false,
    this.enableWrapBuilder = false,
    this.enableCompress = true,
    this.compressionRatio = _KDefaultCompressRatio,
    this.clearCacheWhenScopeDisposed = true,
    this.useFadeAnim = true,
    this.enableMemoryCache = false,
    this.clearMemoryCacheIfFailed = true,
    this.clearMemoryCacheWhenDispose = false,
    this.fit = BoxFit.contain,
    this.borderRadius,
    BoxConstraints? constraints,
  })  : imageProvider = TkImageProvider.file(file),
        constraints = (width != null || height != null)
            ? constraints?.tighten(width: width, height: height) ??
                BoxConstraints.tightFor(width: width, height: height)
            : constraints,
        super(key: key);

  @override
  _TkImageState createState() => _TkImageState();
}

class _TkImageState extends State<TkImage> with SingleTickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    controller = AnimationController(
      vsync: this,
      duration: widget.useFadeAnim ? _KDefaultDuration : _KNonAnim,
    );
    super.initState();
  }

  @override
  void dispose() {
    debugPrint("$this dispose:${widget.clearCacheWhenScopeDisposed}");
    // if (widget.clearCacheWhenScopeDisposed) {
    //   context.unregisterToTkImageScope(imageProvider);
    // }
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool unsafeConstraints =
        _checkDigitalSafety(widget.constraints?.maxWidth) ||
            _checkDigitalSafety(widget.constraints?.maxHeight);
    if (unsafeConstraints) {
      return LayoutBuilder(
        builder: (context, constraint) {
          // debugPrint("TkImageLayoutBuilder $_type :$constraint");
          return _buildImageByType(controller, context, constraint);
        },
      );
    } else {
      assert(widget.constraints != null ||
          widget.width != null ||
          widget.height != null);
      return _buildImageByType(controller, context, widget.constraints!);
    }
  }

  ///根据类型构建图片
  Widget _buildImageByType(AnimationController controller, BuildContext context,
      BoxConstraints boxConstraints) {
    ImageProvider imageProvider = widget.imageProvider;
    //防止Infinity或者NaN的情况
    final bool safetyWidth = !_checkDigitalSafety(boxConstraints.maxWidth);
    final bool safetyHeight = !_checkDigitalSafety(boxConstraints.maxHeight);
    // debugPrint(
    //     "$this $_type width:${constraints?.maxWidth},height:${constraints?.maxHeight}");
    if (widget.enableCompress) {
      imageProvider = AutoResizeImage.resizeIfNeeded(
        provider: imageProvider,
        cacheWidth: safetyWidth ? boxConstraints.maxWidth.round() : null,
        cacheHeight: safetyHeight ? boxConstraints.maxHeight.round() : null,
        compressionRatio: widget.compressionRatio,
        tag: imageProvider,
        upperLimitRatio: widget.upperLimitRatio ?? devicePixelRatio,
      );
    }
    if (widget.clearCacheWhenScopeDisposed) {
      context.registerToTkImageScope(imageProvider);
    }
    return ExtendedImage(
      image: imageProvider,
      width: widget.width,
      height: widget.height,
      border: widget.border,
      constraints: boxConstraints,
      gaplessPlayback: widget.gaplessPlayback,
      shape: widget.shape,
      alignment: widget.align,
      fit: widget.fit,
      enableMemoryCache: widget.enableMemoryCache,
      clearMemoryCacheWhenDispose: widget.clearMemoryCacheWhenDispose,
      clearMemoryCacheIfFailed: widget.clearMemoryCacheIfFailed,
      borderRadius: widget.borderRadius,
      loadStateChanged: _loadStateChanged,
    );
  }

  Widget _loadStateChanged(ExtendedImageState state) {
    final ImageLoadWrapper wrapper =
        widget.wrapperBuilder ?? _buildDefaultPlaceholder;
    switch (state.extendedImageLoadState) {
      case LoadState.loading:
        controller.reset();
        final Widget loadingWidget =
            widget.loadingBuilder?.call(context, state.loadingProgress) ??
                _buildDefaultPlaceholder(null);
        return widget.enableWrapBuilder
            ? wrapper(loadingWidget)
            : loadingWidget;

      case LoadState.completed:
        controller.forward();
        // debugPrint(
        //     "TkImage $_type Size(width:${state.extendedImageInfo.image.width},"
        //     "height:${state.extendedImageInfo.image.height}),width:${constraints?.maxWidth},"
        //     "height:${constraints?.maxHeight},upperLimitRatio:$upperLimitRatio");
        final Widget rawImage = ExtendedRawImage(
          image: state.extendedImageInfo?.image,
          fit: widget.fit,
        );
        return FadeTransition(
          opacity: controller,
          child: widget.borderRadius == null
              ? rawImage
              : ClipRRect(
                  borderRadius: widget.borderRadius,
                  child: rawImage,
                ),
        );
      case LoadState.failed:
        controller.reset();
        debugPrint("$this loadError exception:${state.lastException}");
        final Widget failedWidget = widget.loadFailedBuilder
                ?.call(context, state.lastException, state.lastStack) ??
            _buildDefaultPlaceholder(null);
        return widget.enableWrapBuilder ? wrapper(failedWidget) : failedWidget;
      default:
        controller.reset();
        final Widget loadingWidget =
            widget.loadingBuilder?.call(context, state.loadingProgress) ??
                _buildDefaultPlaceholder(null);
        return widget.enableWrapBuilder
            ? wrapper(loadingWidget)
            : loadingWidget;
    }
  }

  bool _checkDigitalSafety(double? digital) =>
      digital == double.infinity || digital == double.nan || digital == null;

  Widget _buildDefaultPlaceholder(Widget? child) {
    final Widget holder = Container(
      constraints: widget.constraints,
      decoration: BoxDecoration(
        border: widget.border,
        shape: widget.shape,
      ),
      child: child,
    );
    //这里要看占位也是图片的情况
    return widget.borderRadius != null
        ? ClipRRect(
            borderRadius: widget.borderRadius,
            child: holder,
          )
        : holder;
  }
}

class TkImageProvider {
  TkImageProvider._();

  static ImageProvider network(
    String url, {
    double scale = 1.0,
    Map<String, String>? headers,
    bool cache = false,
    int retries = 3,
    Duration? timeLimit,
    Duration timeRetry = const Duration(milliseconds: 100),
    CancellationToken? cancelToken,
    String? cacheKey,
    bool printError = true,
  }) =>
      ExtendedNetworkImageProvider(
        url,
        scale: scale,
        headers: headers,
        cacheKey: cacheKey,
        cache: cache,
        retries: retries,
        timeLimit: timeLimit,
        timeRetry: timeRetry,
        cancelToken: cancelToken,
        printError: printError,
      );

  static ImageProvider asset(
    String assetName, {
    AssetBundle? bundle,
    String? package,
  }) =>
      ExtendedAssetImageProvider(
        assetName,
        bundle: bundle,
        package: package,
      );

  static ImageProvider memory(
    Uint8List bytes, {
    double scale = 1.0,
  }) =>
      ExtendedMemoryImageProvider(
        bytes,
        scale: scale,
      );

  static ImageProvider file(
    File file, {
    double scale = 1.0,
  }) =>
      ExtendedFileImageProvider(
        file,
        scale: scale,
      );

  ///获取network类型的ImageProvider，并注册到[TkImageScope]中
  static ImageProvider networkWithInScope(
    BuildContext context,
    String url, {
    double scale = 1.0,
    Map<String, String>? headers,
    bool cache = false,
    int retries = 3,
    Duration? timeLimit,
    Duration timeRetry = const Duration(milliseconds: 100),
    CancellationToken? cancelToken,
    String? cacheKey,
    bool printError = true,
  }) {
    final ImageProvider netProvider = network(url,
        scale: scale,
        headers: headers,
        cache: cache,
        retries: retries,
        timeRetry: timeRetry,
        timeLimit: timeLimit,
        cancelToken: cancelToken,
        cacheKey: cacheKey,
        printError: printError);
    context.registerToTkImageScope(netProvider);
    return netProvider;
  }

  ///获取asset类型的ImageProvider，并注册到[TkImageScope]中
  static ImageProvider assetWithInScope(
    BuildContext context,
    String assetName, {
    AssetBundle? bundle,
    String? package,
  }) {
    final ImageProvider assetProvider =
        asset(assetName, bundle: bundle, package: package);
    context.registerToTkImageScope(assetProvider);
    return assetProvider;
  }

  ///获取 memory类型的ImageProvider，并注册到[TkImageScope]中
  static ImageProvider memoryWithInScope(
    BuildContext context,
    Uint8List bytes, {
    double scale = 1.0,
  }) {
    final ImageProvider memoryProvider = memory(bytes, scale: scale);
    context.registerToTkImageScope(memoryProvider);
    return memoryProvider;
  }

  ///获取 file类型的ImageProvider，并注册到[TkImageScope]中
  static ImageProvider fileWithInScope(
    BuildContext context,
    File imageFile, {
    double scale = 1.0,
  }) {
    final ImageProvider fileProvider = file(imageFile, scale: scale);
    context.registerToTkImageScope(fileProvider);
    return fileProvider;
  }
}

extension TkScopeExt on BuildContext {
  ///会寻找最近的TkImageScope，并将imageProvider注册到其中
  void registerToTkImageScope(ImageProvider imageProvider) {
    final _TkImageScopeState? state =
        this.findAncestorStateOfType<_TkImageScopeState>();
    if (state != null) {
      state.addProvider(imageProvider);
    }
  }

  void unregisterToTkImageScope(ImageProvider imageProvider) {
    final _TkImageScopeState? state =
        this.findAncestorStateOfType<_TkImageScopeState>();
    if (state != null) {
      state.removeProvider(imageProvider);
    }
  }
}

///指定范围进行图片内存回收
///与TkImage一起使用，详细看[TkImage.clearCacheWhenScopeDisposed]，
///当该字段为true时，会随着scope的dispose将对应的图片从内存中清除。
///也可以通过手动将对应的ImageProvider注册到该scope中[addToTkImageScope]。
class TkImageScope extends StatefulWidget {
  final Widget child;

  const TkImageScope({Key? key, required this.child}) : super(key: key);

  @override
  _TkImageScopeState createState() => _TkImageScopeState();
}

class _TkImageScopeState extends State<TkImageScope> {
  final _TkImageProviderSet _providerSet = _TkImageProviderSet();

  void addProvider(ImageProvider imageProvider) {
    _providerSet.add(imageProvider);
    debugPrint(_providerSet.toString());
  }

  void removeProvider(ImageProvider imageProvider) {
    _providerSet.remove(imageProvider);
    debugPrint(_providerSet.toString());
  }

  @override
  void dispose() {
    debugPrint(
        "$this,dispose ${(imageCache!.currentSizeBytes / 1024 / 1024).round()}M");
    _providerSet.clearCache();
    debugPrint(
        "$this,dispose ${(imageCache!.currentSizeBytes / 1024 / 1024).round()}M");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _TkImageProviderSet {
  final HashMap<Object, ImageProvider> _providerMap =
      HashMap<Object, ImageProvider>();

  void add(ImageProvider imageProvider) async {
    final Object key = await imageProvider.obtainKey(ImageConfiguration.empty);
    if (_providerMap[key] == null) {
      _providerMap[key] = imageProvider;
    }
  }

  Future<ImageProvider?> remove(ImageProvider imageProvider) async {
    final Object key = await imageProvider.obtainKey(ImageConfiguration.empty);
    return _providerMap.remove(key);
  }

  void clearCache() {
    _providerMap.values.forEach((provider) {
      provider.obtainKey(ImageConfiguration.empty).then((obtainKey) {
        final ImageCacheStatus status = imageCache!.statusForKey(obtainKey);
        if (status.keepAlive) {
          provider.evict();
        }
      });
    });
    _providerMap.clear();
  }

  ImageProvider? operator [](Object key) {
    return _providerMap[key];
  }

  @override
  String toString() {
    return "TkImageProviderSet:${_providerMap.length}";
  }
}
