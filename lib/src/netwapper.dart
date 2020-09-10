import 'dart:convert';
import 'dart:developer';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:package_info/package_info.dart';
import 'datamodel.dart';
/*
网络请求封装

请求就4个参数,token作为参数传递,没有用HTTP自带的认证方式
req => { token,lang,version,data },

返回就3个数据,
resb => { code,data,msg}

*/

class NetWapper {
  static void setBaseURL(String url) {
    if (_g_baseurl != null) return;
    _g_baseurl = url;
  }

  //基础URL请求
  static String _g_baseurl = null;

  static NetWapper _g_nstance;

  Dio _dio;
  static NetWapper shareClient() {
    if (_g_nstance == null) _g_nstance = NetWapper(_g_baseurl);
    return _g_nstance;
  }

  String _baseurl;
  NetWapper(String baseurl) {
    assert(baseurl != null, "call setBaseURL frist...");
    this._baseurl = baseurl;
    _initNetWapper();
  }

  void _initNetWapper() {
    BaseOptions baseopt = BaseOptions(
      connectTimeout: 1000 * 30,
      receiveTimeout: 1000 * 30,
    );
    _dio = Dio(baseopt);
  }

  ///获取认证token
  String getToken() => '';

  ///获取设备语言设置
  String getLang() => 'zh-CN';

  ///请求之前做些额外处理,比如数据加密,添加公共字段
  Future<Map> preDeal(String path, Map param) async {
    Map r = Map();
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    r["version"] = packageInfo.version;
    r["lang"] = getLang();
    r['token'] = getToken();

    ///如果需要加密,这里处理,只加密data字段
    r["data"] = json.encode(param != null ? param : Map());
    return r;
  }

  ///请求之后做些额外处理,比如数据解密,,
  Future<Map<String, dynamic>> postDeal(String resbstr) async {
    Map<String, dynamic> r = json.decode(resbstr);

    ///如果要解密,只处理data字段即可
    ///r['data'] = decryp( r['data'] );
    return r;
  }

  Future<SResBase> postPath(String path, Map parameters) async {
    try {
      String url = makeApiPath(path);
      Map reqparam = await preDeal(path, parameters);

      log("req url:" + _g_baseurl + url + " param:" + reqparam.toString());
      Response<String> resb = await _dio.post(
        url,
        data: reqparam,
      );
      if (resb != null) {
        log("resb url:" + url + " data:" + resb.data);
        return SResBase.baseWithData(await postDeal(resb.data));
      } else {
        return SResBase.infoWithErrorString("网络请求错误");
      }
    } catch (e) {
      return SResBase.infoWithErrorString("网络请求异常");
    }
  }

  String makeApiPath(String path) {
    //如果是http开头就是全路径
    if (path.startsWith("http")) return path;
    return _baseurl + path;
  }
}
