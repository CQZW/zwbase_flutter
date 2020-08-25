import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'datamodel.dart';

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

  String getToken() {
    return null;
  }

  Future<SResBase> postPath(String path, Map parameters) async {
    try {
      String url = makeApiPath(path);
      Map<String, dynamic> header = Map();
      String token = getToken();
      Map reqparam;
      if (parameters != null)
        reqparam = Map.from(parameters);
      else
        reqparam = Map();

      if (token != null) {
        header["authorization"] = "Bearer " + token;
      }
      log("req url:" + _g_baseurl + url + " param:" + reqparam.toString());
      Response<String> resb = await _dio.post(url,
          data: parameters, options: Options(headers: header));
      if (resb != null) {
        log("resb url:" + url + " data:" + resb.data);
        return SResBase.baseWithData(json.decode(resb.data));
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
