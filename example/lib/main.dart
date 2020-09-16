import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:zwbase_flutter/zwbase_flutter.dart';

void main() {
  BaseTabBarVC vc = BaseTabBarVC();

  HomeVC homevc = HomeVC();
  homevc.iAMNavRootView();
  homevc.mPageName = "主页";
  homevc.title = "主页";

  MeVC mevc = MeVC();
  mevc.iAMNavRootView();
  mevc.mPageName = "个人中心";
  mevc.title = "个人中心";

  vc.tabitem_txt = <String>["主页", "个人中心"];
  vc.tabitme_icon = [Icons.home, Icons.message];
  vc.tabitme_vc = <BaseVC>[homevc, mevc];

  runApp(vc.getView());
  //runApp(homevc.getView());
}

class prjNetWapper extends NetWapper {
  prjNetWapper() : super("http://xxxx.com");

  @override
  String getLang() => '';

  @override
  String getToken() => 'zh-CN';
  static prjNetWapper _instance;
  static prjNetWapper get shareClient {
    if (_instance == null) _instance = prjNetWapper();
    return _instance;
  }
}

class HomeVC extends BaseVC {
  HomeVC() : super() {
    // int x = 0;
    // do {
    //   this.mDataArr.add("aa");
    // } while (x-- > 0);
    createListOrGirdVC(true);

    this.banner = ZWBanner();
    this.banner.onItemClicked = (index, item) {
      log("clicked:$index ");
    };
    this.banner.items = [];
    this.banner.items.add(ZWBannerItem(
        url:
            "https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1597829250129&di=e86401ba718eab1547647287f0d7b5ce&imgtype=0&src=http%3A%2F%2Fpic.feizl.com%2Fupload%2Fallimg%2F170614%2F0913162K0-3.jpg",
        txt: "哒哒哒哒哒哒",
        defimg: AssetImage("assets/default_video.png")));
    this.banner.items.add(ZWBannerItem(
        url:
            "https://ss1.bdstatic.com/70cFvXSh_Q1YnxGkpoWK1HF6hhy/it/u=379850206,786648567&fm=26&gp=0.jpg",
        txt: "bbbbbb",
        defimg: AssetImage("assets/default_video.png")));
  }

  int _testv = 1;

  ZWBanner banner;

  Widget makePageBody(BuildContext context) {
    return Column(
      children: <Widget>[
        this.banner.getView(),
        FloatingActionButton(
            onPressed: () {
              hudShowLoading("加载中...");
              mItListVC.startHeaderFresh();
            },
            child: Text("do")),
        Expanded(flex: 1, child: mItListVC.getView())
        /*FlatButton(
          onPressed: () => {},
          child: Text("FlatButton"),
        ),
        IconButton(
          icon: Icon(Icons.add),
          onPressed: () => {},
        ),
        RaisedButton.icon(
            onPressed: () => {},
            icon: Icon(Icons.local_airport),
            label: Text("RaisedButton")),
        FloatingActionButton(
          onPressed: () => {},
          child: Text("F"),
        ),
        Text("Text"),
        TextField(decoration: InputDecoration(hintText: "holder"))*/
      ],
    );
  }

  ///一个具备下拉刷新的列表,只需要实现下面3个方法即可
  @override
  Widget onListViewGetItemView(int listid, int index) {
    return Center(child: Text("cell at : $index"));
  }

  @override
  double onListViewGetItemHeight(int listid) {
    return 50;
  }

  Future<SResBase> onLoadHeaderData(int listid) {
    return Future.delayed(Duration(seconds: 2), () {
      var list = [];
      list.add("aa");
      list.add("bb");
      SResBase ret = SResBase.infoWithOKString("okstr");
      ret.mData = [];
      return ret;
      //return Future.value(2);
    });
  }

  Future<SResBase> onLoadFooterData(int listid) {
    return Future.delayed(Duration(seconds: 2), () {
      var list = [];
      list.add("fff");
      list.add("fff");
      SResBase ret = SResBase.infoWithOKString("okstr");
      ret.mData = list;
      return ret;
      //return Future.value(2);
    });
  }

  void clicked_bt() {
    _testv++;
    updateUI();
  }

  int reloadcount = 0;
  @override
  void onDebugReLoad() {
    super.onDebugReLoad();
    reloadcount++;
    this.title = "主页$reloadcount";
    //this.hudShowLoading("加载中...");
    //this.hudShowErrMsg("msg1111111111");
    //this.hudShowSuccessMsg("12312312312");
    //this.hudShowInfoMsg("msg");
    //this.hudDismiss();
    //this.showAlert("title", "msg" ,null);
    //this.showAlertInput("title").then((value) => log("sss:"+value) );
    //this.showSheet("title", ["选择1","选择2","选择3","选择4"] ).then((value) =>log(" sel:" + value.toString() ));

    // prjNetWapper.shareClient.postPath("App/token", {
    //   "sid": "0ED6EFB419A542C786C5003C7857B196",
    //   "client": "app"
    // }).then((SResBase resb) {});

    // String ss =
    //     "{\"status\":false,\"data\":\"\",\"msg\":\"\u8bf7\u586b\u5199sid\",\"loginStatus\":0}";
    // Map<String, dynamic> aaa = json.decode(ss);
    // SResBase.baseWithData(aaa);
/*
    Future.delayed(Duration(seconds: 1), () {
      listvc.startHeaderFresh();
    });*/
  }

  void clicked_push() {
    ForPush vc = ForPush();
    vc.mPageName = "forpush";
    vc.itid = 1;
    pushToVC(vc);
  }

  void clicked_present() {
    ForPush vc = ForPush();
    vc.mPageName = "forpush";
    vc.itid = 1;
    presentVC(vc);
  }

  MediaQueryData mMediaQueryData;
  @override
  void onDidBuild() {
    super.onDidBuild();
    mMediaQueryData = MediaQuery.of(this.getContext());
  }
}

class MeVC extends BaseVC {
  int _testv = 1;
  Widget makePageBody(BuildContext context) {
    return Center(
        child: Column(children: <Widget>[
      Row(children: [
        IconButton(icon: Icon(Icons.add), onPressed: clicked_bt),
        Text("now v is $_testv" +
            " tab at : " +
            tabbar_current_selected.toString())
      ]),
      IconButton(icon: Icon(Icons.share), onPressed: clicked_push),
      FlatButton(onPressed: () => this.setto_vc(), child: Text("set to vc")),
      FlatButton(
          onPressed: () => this.presend_vc(), child: Text("prsent to vc")),
      FlatButton(
          onPressed: () {
            hudShowSuccessMsg("show ok");
          },
          child: Text("show hud success")),
      FlatButton(
          onPressed: () {
            hudShowErrMsg("show err");
          },
          child: Text("show hud err")),
      FlatButton(
          onPressed: () {
            hudShowInfoMsg("show info");
          },
          child: Text("show hud info")),
      FlatButton(
          onPressed: () {
            hudShowLoading("show loading...");
            Future.delayed(Duration(seconds: 2), () {
              hudDismiss();
            });
          },
          child: Text("show hud loading")),
      FlatButton(
        onPressed: () {
          showAlert(
            "alertbox",
            "alert",
          );
        },
        child: Text(
          "show alert",
          style: TextStyle(fontSize: 15),
        ),
      ),
      FlatButton(
          onPressed: () {
            showAlertInput("inputalert", "输入holder");
          },
          child: Text(
            "show alert input",
            style: TextStyle(fontSize: 15),
          )),
      FlatButton(
          onPressed: () {
            showSheet("Sheet", ["选择1", "选择2"]);
          },
          child: Text("show sheet")),
    ]));
  }

  void clicked_bt() {
    _testv++;
    updateUI();
  }

  void clicked_push() {
    ForPush vc = ForPush();
    vc.mPageName = "forpush";
    vc.itid = 2;
    pushToVC(vc);
  }

  void setto_vc() {
    ForPush vc = ForPush();
    vc.mPageName = "for set";
    vc.itid = 3;
    setToVC(vc);
  }

  void presend_vc() {
    ForPush vc = ForPush();
    vc.mPageName = "for prsent";
    vc.itid = 4;
    presentVC(vc);
  }

  @override
  void onDebugReLoad() {
    super.onDebugReLoad();
    this.title = "个人中心1";
    this.mHidenBackBt = true;
  }
}

class ForPush extends BaseVC {
  int itid = 0;
  @override
  Widget makePageBody(BuildContext context) {
    return Center(
        child: Row(children: <Widget>[
      Text("test for  $itid"),
      IconButton(icon: Icon(Icons.share), onPressed: clicked_push)
    ]));
  }

  void clicked_push() {
    ForPush vc = ForPush();
    vc.mPageName = "forpush2222";
    vc.itid = this.itid + 1;
    pushToVC(vc);
  }

  @override
  void onLeftBtClicked() {
    // TODO: implement onLeftBtClicked
    if (itid < 5)
      super.onLeftBtClicked();
    else
      popToRoot();
  }
}
