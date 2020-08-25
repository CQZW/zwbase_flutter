class SResBase {
  bool get mSuccess => mCode == 0;
  int mCode;
  String mMsg;

  ///这里应该使用泛型之类的,,但是不喜欢到处是尖括号
  ///使用as转换下
  Object mData;

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
}
