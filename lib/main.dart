import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_image_cache_demo/kt_image.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

StreamController<String> streamController =
    StreamController<String>.broadcast();

class _MyHomePageState extends State<MyHomePage> {
  late Timer _timer;

  @override
  void initState() {
    _timer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      final String size = memoryCacheSize;
      streamController.sink.add(size);
    });
    debugPrint("screenWith:${mediaData.size.width}");
    debugPrint("calculateSize:${mediaData.size.width * 200 * 4}");
    super.initState();
  }

  @override
  void dispose() {
    _timer.cancel();
    streamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("DemoPage1"),
        actions: [
          _buildCacheSizeView(),
        ],
      ),
      body: TkImage.network(
        image1,
        fit: BoxFit.fitWidth,
        width: mediaData.size.width,
        enableMemoryCache: true,
        height: 200,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Page2(),
          ),
        ),
        tooltip: 'Increment',
        child: Icon(Icons.forward),
      ),
    );
  }
}

class Page2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("DemoPage2"),
        actions: [
          _buildCacheSizeView(),
        ],
      ),
      body: TkImage.network(
        image2,
        fit: BoxFit.fitWidth,
        // width: mediaData.size.width,
        // height: 200,
        computeSize: true,
        borderRadius: BorderRadius.circular(20),
        enableMemoryCache: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pop(context),
        tooltip: 'Increment',
        child: Icon(Icons.close),
      ),
    );
  }
}

Widget _buildCacheSizeView() => Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 15),
        child: StreamBuilder<String>(
          builder: (_, snapshot) => Text(snapshot.data ?? ""),
          stream: streamController.stream,
          initialData: "0K",
        ),
      ),
    );
int sizeCache = 0;
String get memoryCacheSize {
  final int cacheSize =
      PaintingBinding.instance?.imageCache?.currentSizeBytes ?? 0;
  if (sizeCache != cacheSize) {
    sizeCache = cacheSize;
    debugPrint("imageCacheSize:$cacheSize");
  }
  return "${(cacheSize / 1024).toStringAsFixed(2)}K";
}

MediaQueryData get mediaData =>
    MediaQueryData.fromWindow(WidgetsBinding.instance!.window);

const String image1 =
    "https://gimg2.baidu.com/image_search/src=http%3A%2F%2Fclubimg.club.vmall.com%2Fdata%2Fattachment%2Fforum%2F202007%2F17%2F232123momgketgdekbqtvl.jpg&refer=http%3A%2F%2Fclubimg.club.vmall.com&app=2002&size=f9999,10000&q=a80&n=0&g=0n&fmt=jpeg?sec=1618902603&t=12198caae3511f0f49519e07da9e154b";
const String image2 =
    "https://gimg2.baidu.com/image_search/src=http%3A%2F%2Fi0.hdslb.com%2Fbfs%2Farticle%2Fe4b63f001c60bf9ef560cc201522d8364f19628d.jpg&refer=http%3A%2F%2Fi0.hdslb.com&app=2002&size=f9999,10000&q=a80&n=0&g=0n&fmt=jpeg?sec=1618902722&t=1a222f7d0913286e442d84b9da05acd5";
