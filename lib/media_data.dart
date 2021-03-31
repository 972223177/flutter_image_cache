import 'package:flutter/cupertino.dart';

MediaQueryData get mediaData =>
    MediaQueryData.fromWindow(WidgetsBinding.instance!.window);

double get screenWidth => mediaData.size.width;
double get screenHeight => mediaData.size.height;
double get devicePixelRatio => mediaData.devicePixelRatio;

EdgeInsets get padding => mediaData.padding;
