import 'package:flutter/material.dart';

class ZWHud extends StatelessWidget {
  ///显示类型,0 显示加载中..1显示成功,2显示错误,3,显示提示信息
  final int showType;

  ///显示消息
  final String showMsg;

  ///图标,文字前景色
  final Color frontColor;

  ///文字,图标部分背景颜色
  final Color backColor;

  ///整个背景颜色
  final Color backGroundColor;

  ZWHud({
    Key key,
    @required this.showType,
    @required this.showMsg,
    this.frontColor = Colors.white,
    this.backColor = Colors.grey,
    this.backGroundColor = const Color.fromARGB(50, 0, 0, 0),
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    Widget _ind;
    if (showType == 0)
      _ind = CircularProgressIndicator(
          valueColor: new AlwaysStoppedAnimation<Color>(frontColor));
    else if (showType == 1)
      _ind = Icon(Icons.done, size: 36, color: frontColor);
    else if (showType == 2)
      _ind = Icon(Icons.clear, size: 36, color: frontColor);
    else if (showType == 3)
      _ind = Icon(Icons.info, size: 36, color: frontColor);

    return Container(
        decoration: BoxDecoration(color: this.backGroundColor),
        child: Center(
            child: Container(
                constraints: BoxConstraints(
                    minWidth: 100,
                    minHeight: 100,
                    maxWidth: 200,
                    maxHeight: 200),
                decoration: BoxDecoration(
                    color: backColor, borderRadius: BorderRadius.circular(8)),
                padding: EdgeInsets.all(5),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      _ind,
                      Padding(
                          padding:
                              EdgeInsets.only(top: (showType == 0 ? 5 : 0)),
                          child: Text(showMsg,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  decoration: TextDecoration.none,
                                  fontSize: 20,
                                  color: frontColor)))
                    ]))));
  }
}
