import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

///基础的http工具配置类
class Http {
  ///连接超时
  static const int CONNECT_TIMEOUT = 15000;

  ///响应超时
  static const int RECEIVE_TIMEOUT = 15000;

  static Http? _instance;

  factory Http() => _getInstance();

  static Http _getInstance() {
    if (_instance == null) {
      _instance = Http._internal();
    }
    return _instance!;
  }

  static Http get instance => _getInstance();

  Dio? dio;
  BaseOptions? _options;
  CancelToken _cancelToken = CancelToken();

  Http._internal() {
    if (dio == null) {
      _options = BaseOptions(
        connectTimeout: CONNECT_TIMEOUT,
        receiveTimeout: RECEIVE_TIMEOUT,

        ///接收类型为json，会自动解析成Map。如果需要手动解析改成plain就行
        responseType: ResponseType.json,
      );
      dio = Dio(_options)
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (option,handler) {
              ///如果请求参数里有null值直接移除
              if (option.data is Map) {
                Map<String, dynamic> newData = option.data;
                newData.removeWhere((key, value) => value == null);
                option.data = newData;
              }
              Map<String, dynamic> queryParam = option.queryParameters;
              queryParam.removeWhere((key, value) => value == null);
              option.queryParameters = queryParam;

            },
          ),
        );
    }
    if (!kReleaseMode) {
      //debug下允许抓包
      (dio!.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
          (client) {
        client.findProxy = (uri) {
          //192.168.0.129:8888
          return "PROXY ${'192.168.0.107:8888'}";
        };
        //禁用证书校验
        client.badCertificateCallback = (cert, host, port) => true;
      };
    }
  }

  ///初始化公共属性
  void init(
      {String? baseUrl,
        int? connectTimeout,
        int? receiveTimeout,
        List<Interceptor>? interceptors}) {
    dio!.options = dio!.options.copyWith( baseUrl: baseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,);
    if (interceptors != null && interceptors.isNotEmpty) {
      dio!.interceptors.addAll(interceptors);
    }
  }

  /// 取消请求
  /// 同一个cancel token可以用于多个请求，当一个cancel token取消时，所有使用该token的请求都会被取消
  void cancelRequests({CancelToken? token}) {
    token ?? _cancelToken.cancel('canceled');
  }

  void setHeaders(Map<String, dynamic> header) {
    _options!.headers.addAll(header);
  }

  ///get请求
  Future<dynamic> get(String path,
      {Map<String, dynamic>? params,
        Options? options,
        CancelToken? cancelToken}) async {
    Response response = await dio!.get(path,
        queryParameters: params,
        options: options,
        cancelToken: cancelToken ?? _cancelToken);
    return response.data;
  }

  ///post请求
  Future<dynamic> post(
      String path, {
        Map<String, dynamic>? params,
        data,
        Options? options,
        ProgressCallback? onSendProgress,
        ProgressCallback? onReceiveProgress,
        CancelToken? cancelToken,
      }) async {
    Response response = await dio!.post(path,
        data: data,
        queryParameters: params,
        options: options,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
        cancelToken: cancelToken ?? _cancelToken);
    return response.data;
  }

  ///put操作
  Future<dynamic> put(String path,
      {data,
        Map<String, dynamic>? params,
        Options? options,
        CancelToken? cancelToken}) async {
    Response response = await dio!.put(path,
        data: data,
        queryParameters: params,
        options: options,
        cancelToken: cancelToken ?? _cancelToken);
    return response.data;
  }

  ///patch操作
  Future<dynamic> patch(String path,
      {data,
        Map<String, dynamic>? params,
        Options? options,
        CancelToken? cancelToken}) async {
    Response response = await dio!.patch(path,
        data: data,
        queryParameters: params,
        options: options,
        cancelToken: cancelToken ?? _cancelToken);
    return response.data;
  }

  ///delete操作
  Future<dynamic> delete(String path,
      {data,
        Map<String, dynamic>? params,
        Options? options,
        CancelToken? cancelToken}) async {
    Response response = await dio!.delete(path,
        data: data,
        queryParameters: params,
        options: options,
        cancelToken: cancelToken ?? _cancelToken);
    return response.data;
  }

  ///提交表单
  Future<dynamic> postForm(String path,
      {Map<String, dynamic>? params,
        Options? options,
        CancelToken? cancelToken}) async {
    Response responses = await dio!.post(path,
        data: params==null?null:FormData.fromMap(params),
        options: options,
        cancelToken: cancelToken ?? _cancelToken);
    return responses.data;
  }

  ///下载文件
  Future downloadFile(
      String urlPath, String savePath, ValueChanged<String>? progress) async {
    Response<dynamic> response;
    response = await Dio().download(urlPath, savePath,
        options: Options(responseType: ResponseType.stream),
        onReceiveProgress: (count, total) {
          progress?.call((count / total * 100).toStringAsFixed(0) + "%");
        });
    return response.data;
  }
}
///http工具类
void initHttp(
    {String? baseUrl,
      int? connectTimeout,
      int? receiveTimeout,
      List<Interceptor>? interceptors}) {
  Http().init(
      baseUrl: baseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      interceptors: interceptors);
}

void setHeaders(Map<String, dynamic> map) {
  Http().setHeaders(map);
}

void cancelRequests({CancelToken? token}) {
  Http().cancelRequests(token: token);
}

Future get(
    String path, {
      Map<String, dynamic>? params,
      Options? options,
      CancelToken? cancelToken,
    }) async {
  return await Http().get(
    path,
    params: params,
    options: options,
    cancelToken: cancelToken,
  );
}

Future post(
    String path, {
      data,
      Map<String, dynamic>? params,
      Options? options,
      ProgressCallback? onSendProgress,
      ProgressCallback? onReceiveProgress,
      CancelToken? cancelToken,
    }) async {
  return await Http().post(
    path,
    data: data,
    params: params,
    options: options,
    onSendProgress: onSendProgress,
    onReceiveProgress: onReceiveProgress,
    cancelToken: cancelToken,
  );
}

Future put(
    String path, {
      data,
      Map<String, dynamic>? params,
      Options? options,
      CancelToken? cancelToken,
    }) async {
  return await Http().put(
    path,
    data: data,
    params: params,
    options: options,
    cancelToken: cancelToken,
  );
}

Future patch(
    String path, {
      data,
      Map<String, dynamic>? params,
      Options? options,
      CancelToken? cancelToken,
    }) async {
  return await Http().patch(
    path,
    data: data,
    params: params,
    options: options,
    cancelToken: cancelToken,
  );
}

Future delete(
    String path, {
      data,
      Map<String, dynamic>? params,
      Options? options,
      CancelToken? cancelToken,
    }) async {
  return await Http().delete(
    path,
    data: data,
    params: params,
    options: options,
    cancelToken: cancelToken,
  );
}

Future postForm(
    String path, {
      Map<String, dynamic>? params,
      Options? options,
      CancelToken? cancelToken,
    }) async {
  return await Http().postForm(
    path,
    params: params,
    options: options,
    cancelToken: cancelToken,
  );
}

Future downloadFile(
    String urlPath, String savePath, ValueChanged<String> progress) async {
  return await Http().downloadFile(urlPath, savePath, progress);
}