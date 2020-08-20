import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:zwbase_flutter/zwbase_flutter.dart';

class ZWBannerItem {
  ZWBannerItem({@required String url, AssetImage defimg, String txt})
      : this.imgurl = url,
        this.imgdefault = defimg,
        this.text = txt;

  ///图片URL链接
  String imgurl;

  ///默认图片
  AssetImage imgdefault;

  ///文字
  String text;
}

typedef void ZWBannerItemClicked(int index, ZWBannerItem item);

///自动轮播控件
class ZWBanner extends ViewCtr {
  List<ZWBannerItem> items;

  ///自动轮播间隔时间,默认3500毫秒
  int graptime = 3500;

  ///整个视图的高度,
  double height = 150;

  ///文字显示是否在顶部,否则就是底部,默认底部
  bool txtattop = false;

  ///显示文字的背景颜色,默认黑色+透明度
  Color txtbgcolor = Color.fromARGB(125, 0, 0, 0);

  ///文字颜色,默认白色
  Color txtcolor = Color.fromARGB(255, 255, 255, 255);

  double txtsize = 14;

  PageController _ctr =
      PageController(initialPage: 0, keepPage: true, viewportFraction: 1);

  ZWBannerItemClicked onItemClicked;

  Timer _timer;
  int _page = 0;

  int getNowPageIndex() {
    return _page % items.length;
  }

  @override
  void onDidBuild() {
    super.onDidBuild();
    startAutoScr();
  }

  @override
  void onDidRemoved() {
    super.onDidRemoved();
    _timer.cancel();
    _timer = null;
  }

  ///开始自动滚动banner
  void startAutoScr() {
    if (_timer != null) return;

    _timer = Timer.periodic(Duration(milliseconds: graptime), (Timer timer) {
      _page++;
      _ctr.animateToPage(getNowPageIndex(),
          duration: Duration(milliseconds: 350), curve: Curves.easeOut);
    });
  }

  @override
  Widget realBuildWidget(BuildContext context) {
    return Listener(
        onPointerUp: (PointerUpEvent e) {
          int t = getNowPageIndex();
          onItemClicked?.call(t, items[t]);
        },
        child: Container(
            height: this.height,
            color: Colors.grey,
            child: PageView(
              scrollDirection: Axis.horizontal,
              controller: _ctr,
              physics: NeverScrollableScrollPhysics(),
              children: _makeList(),
            )));
  }

  List<Widget> _makeList() {
    var r = <Widget>[];

    for (var item in items) {
      Widget _txt;
      if (item.text != null) {
        _txt = Container(
            padding: EdgeInsets.all(3),
            alignment: Alignment.centerLeft,
            color: this.txtbgcolor,
            child: Text(
              item.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: txtcolor,
                fontSize: txtsize,
              ),
            ));
      }
      Widget _img;
      if (item.imgurl != null) {
        _img = FadeInImage(
            fit: BoxFit.fill,
            placeholder: item.imgdefault,
            image: NetworkImage(item.imgurl));
      }
      if (_img != null && _txt != null) {
        r.add(Stack(
          fit: StackFit.expand,
          children: <Widget>[
            _img,
            this.txtattop
                ? Positioned(
                    child: _txt,
                    top: 0,
                    right: 0,
                    left: 0,
                  )
                : Positioned(
                    child: _txt,
                    bottom: 0,
                    right: 0,
                    left: 0,
                  )
          ],
        ));
      } else {
        r.add(_img ?? _txt);
      }
    }
    return r;
  }
}
