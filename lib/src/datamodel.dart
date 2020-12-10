import 'dart:convert';
import 'dart:developer';

import 'package:shared_preferences/shared_preferences.dart';

typedef dynamic newFunc(Map<String, dynamic> e);

///接口返回的通用数据结构
class SResBase<T> {
  bool get mSuccess => mCode == 0;

  ///服务器返回的错误码,这里占用几个
  ///1:错误,不知道具体的错误,都是1,这里没有使用,建议这样使用,
  ///2:服务器返回数据异常
  ///3:网络请求异常
  int mCode;

  ///服务器返回的消息,用于调试吧
  String mMsg;

  ///需要UI显示的消息
  String mUIMsg;

  ///这里应该使用泛型之类的,,但是不喜欢到处是尖括号,,
  ///dart居然可以不设置 T,,,那就没有到处尖括号了,good...
  T mData;

  ///创建通用对象,添加成功的描述
  SResBase.infoWithOKString(String okstr, [cdoe = 0, fetchuimsg = false]) {
    mCode = cdoe;
    mMsg = okstr;
    mUIMsg = fetchuimsg ? okstr : null;
    mData = null;
  }

  ///创建通用对象,添加失败的描述,错误码默认1
  SResBase.infoWithErrorString(String errstr, [cdoe = 1, fetchuimsg = false]) {
    mCode = cdoe;
    mMsg = errstr;
    mUIMsg = fetchuimsg ? errstr : null;

    mData = null;
  }
  SResBase.baseWithData(Map<String, dynamic> data) {
    if (data["code"] == null) {
      SResBase.infoWithErrorString("请求服务器失败,请稍微再试", 2);
      return;
    }
    if (data["code"] is! int) {
      SResBase.infoWithErrorString("服务器数据,请稍微再试", 2);
      return;
    }
    mCode = data["code"] as int;
    mMsg = data["msg"] ?? "";
    mData = data["data"];

    mUIMsg = data["uiMsg"] != null ? data["uiMsg"] as String : null;
  }

  List getDataAsList([newFunc f, String k]) {
    if (!mSuccess) return [];
    var t = (mData as Map)[k == null ? 'list' : k];
    if (t != null && t is List) {
      return t.map((e) => e == null ? null : f(e)).toList();
    }
    return [];
  }

  ///转换成另外一个类型的数据,就拷贝了
  SResBase<T> toTypeResb<T>() {
    return SResBase<T>.infoWithOKString(this.mMsg, this.mCode);
  }
}

abstract class SAutoEx {
  SAutoEx([Map<String, dynamic> json]) {
    if (json != null)
      fetchIt(json);
    else
      log("maybe null json,do't call fetchIt");
  }

  ///JSON->对象,自己必须实现
  void fetchIt(Map<String, dynamic> json);

  ///对象 -> JSON,自己必须实现
  Map<String, dynamic> toJson();

  ///将自己存储到本地
  Future<bool> dumpSelf(String key) async {
    SharedPreferences perfs = await SharedPreferences.getInstance();
    return perfs.setString(key, json.encode(toJson()));
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
}
