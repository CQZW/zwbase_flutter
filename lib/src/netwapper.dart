import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:package_info/package_info.dart';
import 'datamodel.dart';
/*
网络请求封装

请求就4个参数,token作为参数传递,没有用HTTP自带的认证方式
req => { token,lang,version,client,data },

返回就3个数据,
resb => { code,data,msg}

*/

abstract class NetWapper {
  Dio dio;

  ///子类自己实现,因为需要自己实现  getToken,getLang等
  //static NetWapper _g_nstance;
//   static NetWapper shareClient() {
//     if (_g_nstance == null) _g_nstance = NetWapper(_g_baseurl);
//     return _g_nstance;
//   }

  String baseurl;
  NetWapper(String baseurl) {
    assert(baseurl != null, "baseurl must has...");
    this.baseurl = baseurl;
    _initNetWapper();
  }

  void _initNetWapper() {
    BaseOptions baseopt = BaseOptions(
      connectTimeout: kReleaseMode ? (1000 * 30) : (1000 * 3600),
      receiveTimeout: kReleaseMode ? (1000 * 30) : (1000 * 3600),
    );
    dio = Dio(baseopt);
  }

  ///获取认证token
  String getToken(); // => '';

  ///获取设备语言设置
  String getLang(); // => 'zh-CN';

  ///获取设备ID
  Future<String> getDeviceId();

  ///请求之前做些额外处理,比如数据加密
  Future<Map<String, dynamic>> preDeal(
      String path, Map<String, dynamic> param) async {
    Map<String, dynamic> r = Map<String, dynamic>();

    ///如果需要加密,这里处理,只加密data字段
    //r["data"] = json.encode(param != null ? param : Map());
    //r["data"] = param != null ? param : Map();
    r = param != null ? param : Map<String, dynamic>();
    return r;
  }

  ///预处理header,公共参数放到header里面
  Future<Map<String, dynamic>> preHeader(
      String path, Map<String, dynamic> param) async {
    Map<String, dynamic> r = Map<String, dynamic>();
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    r["version"] = packageInfo.version;
    r["lang"] = getLang();
    r['token'] = getToken();
    r['deviceId'] = await getDeviceId();
    if (defaultTargetPlatform == TargetPlatform.iOS)
      r['client'] = 'ios';
    else if (defaultTargetPlatform == TargetPlatform.android)
      r['client'] = 'android';
    else
      r['client'] = 'unkown';
    return r;
  }

  ///请求之后做些额外处理,比如数据解密,,
  Future<Map<String, dynamic>> dealPost(String resbstr) async {
    Map<String, dynamic> r = json.decode(resbstr);

    ///如果要解密,只处理data字段即可
    ///r['data'] = decryp( r['data'] );
    return r;
  }

  Future<SResBase> postPath(String path, Map<String, dynamic> param) async {
    try {
      String url = makeApiPath(path);
      var reqparam = await preDeal(path, param);
      var header = await preHeader(path, param);
      log("req url:" +
          url +
          " param:" +
          reqparam.toString() +
          " header:" +
          header.toString());
      Response<String> resb = await dio.post(url,
          data: reqparam, options: Options(headers: header));
      if (resb != null) {
        log("resb url:" + url + " data:" + resb.data);
        return SResBase.baseWithData(await dealPost(resb.data));
      } else {
        return SResBase.infoWithErrorString("网络请求错误");
      }
    } catch (e) {
      log("resb exp:" + e.toString());
      return SResBase.infoWithErrorString("网络请求异常");
    }
  }

  String makeApiPath(String path) {
    //如果是http开头就是全路径
    if (path.startsWith("http")) return path;
    return this.baseurl + path;
  }
}
