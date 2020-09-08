import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SResBase<T> {
  bool get mSuccess => mCode == 0;
  int mCode;
  String mMsg;

  ///这里应该使用泛型之类的,,但是不喜欢到处是尖括号,,
  ///dart居然可以不设置 T,,,那就没有到处尖括号了,good...
  T mData;

  SResBase.infoWithOKString(String okstr) {
    mCode = 0;
    mMsg = okstr;
    mData = null;
  }
  SResBase.infoWithErrorString(String errstr) {
    mCode = 0;
    mMsg = errstr;
    mData = null;
  }
  SResBase.baseWithData(Map<String, dynamic> data) {
    if (data["status"] == null) {
      SResBase.infoWithErrorString("请求服务器失败,请稍微再试");
      return;
    }
    mMsg = data["msg"] ?? "未知信息";
    if (data["status"])
      mCode = 0;
    else
      mCode = 1;
    mData = data["data"];
  }
  SResBase.baseWithSResb(SResBase resb) {
    mCode = resb.mCode;
    mMsg = resb.mMsg;
  }
}

///数据模型基类,封装常用的方法
typedef dynamic FetchFunc(Map<String, dynamic> json, dynamic instance);
typedef dynamic FromJsonFunc(Map<String, dynamic> json);

abstract class SAutoEx {
  SAutoEx({Map<String, dynamic> json, FetchFunc fetchfunc}) {
    fetchIt(json, fetchfunc: fetchfunc);
  }

  ///填充类数据
  void fetchIt(Map<String, dynamic> json, {FetchFunc fetchfunc}) {
    if (json != null && fetchfunc != null) {
      fetchfunc(json, this);
    }
  }

  ///将自己存储到本地
  Future<bool> dumpSelf(String key, Map<String, dynamic> jsonmap) async {
    SharedPreferences perfs = await SharedPreferences.getInstance();
    return perfs.setString(key, json.encode(jsonmap));
  }

  ///加载自己存储的数据
  static Future<Map<String, dynamic>> loadSelf(String key) async {
    var perfs = await SharedPreferences.getInstance();
    var t = perfs.getString(key);
    if (t != null) return json.decode(t);
    return null;
  }

  static bool _someopinited = false;

  ///数据模型一些必须的初始化动作,
  ///比如加载当前用户存储到磁盘的数据,由于读取磁盘是异步,所以让外层使用非常不方便
  ///这里提供一个初始化操作的机会
  static Future<SResBase> someInitOp() async {
    if (_someopinited) throw Exception("some op had inited");
    _someopinited = true;
    return SResBase.infoWithOKString("成功");
  }

  ///直接生成List的对象
  static dynamic toListFromJson(List list, FromJsonFunc func) {
    return list
        .map((e) => e == null ? null : func(e as Map<String, dynamic>))
        ?.toList();
  }
}
