import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:aliossflutter/response.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

class AliOSSFlutter {
    final MethodChannel _channel = MethodChannel('aliossflutter')
    ..setMethodCallHandler(_handler);
  static final _uuid = new Uuid();
  String id;

  AliOSSFlutter() {
    id = _uuid.v4();
    alis[id] = this;
  }

  static final alis = new Map<String, AliOSSFlutter>();
  StreamController<bool> _responseInitController =
  new StreamController.broadcast();
  Stream<bool> get responseFromInit =>
      _responseInitController.stream;

  StreamController<ProgressResponse> _responseProgressController =
      new StreamController.broadcast();
  Stream<ProgressResponse> get responseFromProgress =>
      _responseProgressController.stream;

  StreamController<DownloadResponse> _responseDownloadController =
      new StreamController.broadcast();
  Stream<DownloadResponse> get responseFromDownload =>
      _responseDownloadController.stream;

  StreamController<UploadResponse> _responseUploadController =
  new StreamController.broadcast();
  Stream<UploadResponse> get responseFromUpload =>
      _responseUploadController.stream;

  StreamController<SignResponse> _responseSignController =
      new StreamController.broadcast();
  Stream<SignResponse> get responseFromSign => _responseSignController.stream;

    StreamController<DeleteResponse> _responseDeleteController =
      new StreamController.broadcast();
  Stream<DeleteResponse> get responseFromDelete => _responseDeleteController.stream;

    StreamController<HeadObjectResponse> _responseHeadObjectController =
    new StreamController.broadcast();
    Stream<HeadObjectResponse> get responseFromHeadObject => _responseHeadObjectController.stream;

  Future<dynamic> _invokeMethod(String method,
      [Map<String, dynamic> arguments = const {}]) {
    Map<String, dynamic> withId = Map.of(arguments);
    withId['id'] = id;
    return _channel
        .invokeMethod(method, withId);
  }

//监听回调方法
  static Future<dynamic> _handler(MethodCall methodCall) {
    String id = (methodCall.arguments as Map)['id'];
    AliOSSFlutter oss = alis[id];
    switch (methodCall.method) {
      case "onInit":
        bool flag=false;
        if("success"==methodCall.arguments["result"]){
          flag=true;
        }
        oss._responseInitController.add(flag);
        break;
      case "onProgress":
        ProgressResponse res = new ProgressResponse(
          key: methodCall.arguments["key"].toString(),
            currentSize:
                double.parse(methodCall.arguments["currentSize"].toString()),
            totalSize:
                double.parse(methodCall.arguments["totalSize"].toString()));
        oss._responseProgressController.add(res);
        break;
      case "onSign":
        SignResponse res=SignResponse(success: false);
        if("success"==methodCall.arguments["result"]){
          res.success=true;
          res.url=methodCall.arguments["url"];
        }else{
          res.msg=methodCall.arguments["message"];
        }
        res.key=methodCall.arguments["key"].toString();
        oss._responseSignController.add(res);
        break;
        case "onDelete":
        DeleteResponse res=DeleteResponse(success: false);
        if("success"==methodCall.arguments["result"]){
          res.success=true;
        }
        res.key=methodCall.arguments["key"];
        oss._responseDeleteController.add(res);
        break;
      case "onUpload":
        UploadResponse res=UploadResponse(success: false);
        if("success"==methodCall.arguments["result"]){
          res.success=true;
          res.servercallback=methodCall.arguments["servercallback"];
        }else{
          res.msg=methodCall.arguments["message"];
        }
        res.key=methodCall.arguments["key"];
        oss._responseUploadController.add(res);
        break;
      case "onDownload":
        DownloadResponse res=DownloadResponse(success: false);
        if("success"==methodCall.arguments["result"]){
          res.success=true;
          res.path=methodCall.arguments["path"];
        }else{
          res.msg=methodCall.arguments["message"];
        }
        res.key=methodCall.arguments["key"].toString();
        oss._responseDownloadController.add(res);
        break;
        case "asyncHeadObject":
          HeadObjectResponse res=HeadObjectResponse(success: false);
      if(methodCall.arguments["result"]){
        res.success=true;
      }
      res.key=methodCall.arguments["key"];
      res.lastModified=methodCall.arguments["lastModified"];
      oss._responseHeadObjectController.add(res);
      break;
    }
    return Future.value(true);
  }

//上传
  Future upload(String bucket, Uint8List file, String key,{String callbackUrl,String callbackHost,String callbackBodyType,String callbackBody,String callbackVars}) async {

    //Uint8List pngBytes = file.buffer.asUint8List();
    String bs64 = base64Encode(file);

    return await _invokeMethod(
        'upload', <String, String>{"bucket": bucket, "fileByte": bs64, "key": key, "callbackUrl": callbackUrl, "callbackHost": callbackHost, "callbackBodyType": callbackBodyType, "callbackBody": callbackBody, "callbackVars": callbackVars});
  }

//初始化
  Future init(String stsserver, String endpoint, {String cryptkey = "",String crypttype = "3des"}) async {
    return await _invokeMethod('init', <String, String>{
      "stsserver": stsserver,
      "endpoint": endpoint,
      "cryptkey": cryptkey,
      "crypttype": crypttype
    });
  }

  Future secretInit(String accessKeyId,String accessKeySecret, String endpoint) async {
    return await _invokeMethod('secretInit', <String, String>{
      "endpoint": endpoint,
      "accessKeyId": accessKeyId,
      "accessKeySecret": accessKeySecret
    });
  }

//url签名
  Future signUrl(String bucket, String key,
      {String type = "0",
      String interval = "1800",
      String process = ""}) async {
    return await _invokeMethod('signurl', <String, String>{
      "bucket": bucket,
      "key": key,
      "type": type,
      "interval": interval,
      "process": process
    });
  }

//下载
  Future download(String bucket, String key, String path,
      {String process = ""}) async {
    return await _invokeMethod('download', <String, String>{
      "bucket": bucket,
      "key": key,
      "path": path,
      "process": process
    });
  }

  Future exist(String bucket, String key) async {
    return await _invokeMethod('doesObjectExist', <String, String>{
      "bucket": bucket,
      "key": key
    });
  }
  Future delete(String bucket, String key) async {
    return await _invokeMethod('delete', <String, String>{
      "bucket": bucket,
      "key": key,
    });
  }
//3des 加解密
  Future des(String key, String type, String data,
      ) async {
    return await _invokeMethod('des', <String, String>{
      "key": key,
      "type": type,
      "data": data
    });
  }
  //aes 加解密
  Future aes(String key, String type, String data,
      ) async {
    return await _invokeMethod('aes', <String, String>{
      "key": key,
      "type": type,
      "data": data
    });
  }

  //获取文件元信息
  Future asyncHeadObject(String bucket, String key) async {
    return await _invokeMethod('asyncHeadObject', <String, String>{
      "bucket": bucket,
      "key": key
    });
  }
}
