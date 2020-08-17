import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';

import 'zwhud.dart';
import 'zwrefreshlistvc.dart';

///这里是参考之前IOS的基类,将常用的方法封装了
abstract class ViewCtr {
  BuildContext _context;
  BaseState _state;

  ///衔接state的 build 方法,将控件布局引入到控制器
  Widget vcBuildWidget(BuildContext context, BaseState state) {
    _context = context;
    _state = state;
    return realBuildWidget(context);
  }

  ///控制器的真正build方法
  Widget realBuildWidget(BuildContext context);

  ///导出控制器真正的布局数据
  Widget getView({Key key}) {
    return BaseView(key: key, vc: this);
  }

  ///控制器更新数据,就是setstate
  void updateUI() {
    _state?.setState(() {});
  }

  ///初始化被调用
  void onInitVC() {
    log("onInitVC");
  }

  ///调试重新热加载
  void onDebugReLoad() {
    log("onDebugReLoad...");
  }

  ///是否自动保留,否则页面隐藏不显示的时候被移除了tree..,主要是tabbar的子页面
  bool wantKeepAlive = false;
}

///基础控制器
abstract class BaseVC extends ViewCtr implements ZWListVCDelegate {
  //获取控制器对应的视图
  Widget getView({Key key}) {
    assert(mPageName != null);
    //如果是导航的根view,那么需要包裹一层导航视图,
    if (_bIsNavRootVC)
      return BaseNavView(vc: this, view: BaseView(key: key, vc: this));
    //如果已经外层有了导航视图,那么这里不需要包裹导航视图了,普通页面都是这个
    if (_bHasNavView) return BaseView(key: key, vc: this);

    //一个页面如果不是被present的,也不是导航的根,也不是导航下面的普通页面,,,那不对了
    assert(false, "not way.....");
    return null;
  }

  var _leftBtStr;
  bool _lbimg = true;

  ///设置导航栏坐标按钮
  void setLeftBt(var str, bool bimg) {
    _leftBtStr = str;
    _lbimg = bimg;
    updateUI();
  }

  var _rightBtStr;
  bool _rbimg = true;

  ///设置导航栏右边按钮
  void setRightBt(var str, bool bimg) {
    _rightBtStr = str;
    _rbimg = bimg;
    updateUI();
  }

  ///创建顶部导航栏
  Widget makeTopBar(BuildContext context) {
    if (mHidNarBar) return null;
    Widget leftbt;
    if (!this.mHidenBackBt) {
      if (_lbimg)
        leftbt = IconButton(
            tooltip: "返回上一页",
            onPressed: this.onLeftBtClicked,
            icon: _leftBtStr != null
                ? (_leftBtStr is String
                    ? (ImageIcon(AssetImage(_leftBtStr)))
                    : (Icon(_leftBtStr)))
                : Icon(Icons.navigate_before));
      else
        leftbt = FlatButton(
            textColor: Colors.white,
            onPressed: this.onLeftBtClicked,
            child: Text(_leftBtStr));
    }
    var _ra = <Widget>[];
    if (this._rightBtStr != null) {
      Widget rightbt;
      if (_rbimg)
        rightbt = IconButton(
            tooltip: "更多",
            onPressed: this.onRightBtClicked,
            icon: (_rightBtStr is String
                ? ImageIcon(AssetImage(_rightBtStr))
                : Icon(_rightBtStr)));
      else
        rightbt = FlatButton(
            textColor: Colors.white,
            onPressed: this.onRightBtClicked,
            child: Text(_rightBtStr));
      _ra.add(rightbt);
    }
    return AppBar(
      title: Text(this.title),
      leading: leftbt,
      actions: _ra,
      centerTitle: true,
    );
  }

  // ignore: non_constant_identifier_names
  int tabbar_current_selected = 0;
  // ignore: non_constant_identifier_names
  Widget tabbar_Widget;

  static String mappname = "APP_NAME";

  ///创建主要的控件部分,导航栏,tabbar,返回按钮,右侧按钮,标题等,底部tabbar由外部创建传入即可
  Widget realBuildWidget(BuildContext context) {
    Widget t = Scaffold(
        appBar: makeTopBar(context),
        body: makePageBody(context),
        bottomNavigationBar: tabbar_Widget);
    if (extOverlayer != null) {
      //如果有扩展覆盖层,那么就用stack堆积起来
      t = Stack(
        children: <Widget>[t, extOverlayer],
        fit: StackFit.expand,
        alignment: Alignment.center,
      );
    }
    return MaterialApp(
        title: BaseVC.mappname,
        home: t,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ));
  }

  ///正常创建页面业务控件的地方,子类继承并且修改这个,
  ///就是之前的build方法里面创建body的部分
  Widget makePageBody(BuildContext context);

  ///用于扩展显示覆盖层,比如,HUD,
  Widget _extOverlayer;
  Widget get extOverlayer => _extOverlayer;
  set extOverlayer(Widget val) {
    _extOverlayer = val;
    updateUI();
  }

  ///显示HUD加载中
  void hudShowLoading(String msg) {
    extOverlayer = ZWHud(showType: 0, showMsg: msg);
  }

  ///显示HUD错误信息
  void hudShowErrMsg(String msg) {
    extOverlayer = ZWHud(
      showType: 2,
      showMsg: msg,
    );
    _autoDismissHUD(msg.length > 11 ? 3000 : 1500);
  }

  ///显示HUD 成功新
  void hudShowSuccessMsg(String msg) {
    extOverlayer = ZWHud(
      showType: 1,
      showMsg: msg,
    );
    _autoDismissHUD(msg.length > 11 ? 3000 : 1500);
  }

  void hudShowInfoMsg(String msg) {
    extOverlayer = ZWHud(
      showType: 3,
      showMsg: msg,
    );
    _autoDismissHUD(msg.length > 11 ? 3000 : 1500);
  }

  void _autoDismissHUD([int dealy = 3000]) {
    Future.delayed(Duration(milliseconds: dealy), () => this.hudDismiss());
  }

  ///消失HUD
  void hudDismiss() {
    extOverlayer = null;
  }

  ///页面名字,用于统计
  String mPageName;

  bool _mHidNarBar = false;

  ///是否隐藏导航栏,默认false
  bool get mHidNarBar => _mHidNarBar;
  set mHidNarBar(bool val) {
    _mHidNarBar = val;
    this.updateUI();
  }

  ///是否隐藏返回按钮
  bool _mHidenBackBt = false;
  bool get mHidenBackBt => _mHidenBackBt;
  set mHidenBackBt(bool val) {
    _mHidenBackBt = val;
    this.updateUI();
  }

  String _title = "title";

  ///导航栏顶部title文字
  String get title => _title;
  set title(String val) {
    _title = val;
    this.updateUI();
  }

  ///左边返回按钮被点击之后
  void onLeftBtClicked() {
    this.popBack();
  }

  ///右边按钮被点击之后
  void onRightBtClicked() {}

  ///是否已经添加了导航视图,Flutter如果要支持导航,需要顶层为 StatelessWidget
  bool _bHasNavView = false;
  bool _bIsNavRootVC = false;
  void iAMNavRootView() {
    _bIsNavRootVC = true;
  }

  ///页面的返回值
  var mRetVal;
  void popBack() {
    if (Navigator.of(this._context).canPop()) {
      Navigator.pop(_context, mRetVal);
      return;
    }
    log("can not pop ,now is root");
  }

  ///返回到root VC,
  void popToRoot() {
    Navigator.of(this._context).popUntil(ModalRoute.withName("/"));
  }

  ///PUSH到指定VC,并且有返回异步返回值
  Future pushToVC(BaseVC to) {
    to._bHasNavView = this._bHasNavView || _bIsNavRootVC;
    to._bIsPresent = this._bIsPresent;
    return Navigator.of(this._context).push(MaterialPageRoute(
        maintainState: true,
        builder: (context) {
          return to.getView();
        }));
  }

  ///直接跳转到指定VC,不保留当前页面在栈里面
  void setToVC(BaseVC to) {
    to._bHasNavView = this._bHasNavView || _bIsNavRootVC;
    to._bIsPresent = this._bIsPresent;
    if (Navigator.of(this._context).canPop()) {
      Navigator.pushReplacement(
          this._context,
          MaterialPageRoute(
              maintainState: true,
              builder: (context) {
                return to.getView();
              }));
    } else {
      log("can not replace root view");
    }
  }

  ///表明当前VC是否 是present来的
  bool _bIsPresent = false;

  ///�������态弹出VC,
  void presentVC(BaseVC to) {
    to._bIsPresent = true;
    to._bHasNavView = this._bHasNavView || _bIsNavRootVC;
    Navigator.of(this._context).push(MaterialPageRoute(
        fullscreenDialog: true,
        maintainState: true,
        builder: (context) {
          return to.getView();
        }));
  }

  void delayBackClicked() {
    Future.delayed(Duration(milliseconds: 300), () => this.popBack());
  }

  ///显示对话框,返回点击事件索引,0:取消,1:确定
  Future<int> showAlert(String title, String msg,
      [String leftbtstr = "取消", String rightbtstr = "确定"]) {
    assert(leftbtstr != null || rightbtstr != null);
    var acts = <Widget>[];
    var _c = new Completer<int>();
    if (leftbtstr != null)
      acts.add(FlatButton(
          onPressed: () => {extOverlayer = null, _c.complete(0)},
          child: Text(leftbtstr)));
    acts.add(FlatButton(
        onPressed: () => {extOverlayer = null, _c.complete(1)},
        child: Text(rightbtstr)));
    extOverlayer =
        AlertDialog(title: Text(title), content: Text(msg), actions: acts);
    return _c.future;
  }

  ///显示模态输入框,返回输入字符串,如果取消,则返回""
  Future<String> showAlertInput(String title,
      [String holder = "请输入内容",
      String leftbtstr = "取消",
      String rightbtstr = "确定"]) {
    assert(leftbtstr != null && rightbtstr != null);
    var acts = <Widget>[];
    var _c = new Completer<String>();
    TextEditingController _input_ctr = TextEditingController();
    TextField _t = TextField(
        controller: _input_ctr,
        autofocus: true,
        decoration: InputDecoration(hintText: holder));
    acts.add(FlatButton(
        onPressed: () => {extOverlayer = null, _c.complete("")},
        child: Text(leftbtstr)));
    acts.add(FlatButton(
        onPressed: () => {extOverlayer = null, _c.complete(_input_ctr.text)},
        child: Text(rightbtstr)));
    extOverlayer = AlertDialog(title: Text(title), content: _t, actions: acts);
    return _c.future;
  }

  ///显示从下往上的选择界面
  Future<int> showSheet(String title, List<String> bts) {
    var _c = new Completer<int>();
    var list = <Widget>[];
    list.add(Column(children: [
      Padding(
          padding: EdgeInsets.all(20),
          child: Text(title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 18))),
      Divider(color: Colors.grey, height: 0.5, thickness: 0.5)
    ]));
    for (int i = 0; i < bts.length; i++) {
      list.add(Column(children: [
        SizedBox(
            width: double.infinity,
            child: FlatButton(
                onPressed: () {
                  Navigator.pop(_context);
                  _c.complete(i);
                },
                child: Text(bts[i],
                    style: TextStyle(
                        color: Theme.of(this._context).primaryColor)))),
        Divider(color: Colors.grey, height: 0.5, thickness: 0.5)
      ]));
    }
    var _a = Padding(
        padding: EdgeInsets.only(left: 10, right: 10),
        child: Container(
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(10)),
          child: Center(heightFactor: 1, child: Column(children: list)),
        ));
    var _b = Padding(
        padding: EdgeInsets.all(10),
        child: Container(
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: Center(
                heightFactor: 1,
                child: SizedBox(
                    width: double.infinity,
                    child: FlatButton(
                        onPressed: () {
                          Navigator.pop(_context);
                          _c.complete(-1);
                        },
                        child: Text("取消",
                            style: TextStyle(
                                color:
                                    Theme.of(this._context).primaryColor)))))));
    showModalBottomSheet(
        backgroundColor: Colors.transparent,
        context: _context,
        builder: (context) {
          return Column(mainAxisSize: MainAxisSize.min, children: [_a, _b]);
        });
    return _c.future;
  }

  //列表相关
  List mDataArr = [];

  int mPage = 0;

  int onListViewGetCount(int listid) => this.mDataArr.length;

  Widget onListViewGetItemView(int listid, int index) => null;

  double onListViewGetItemHeight(int listid) => null;

  void onListViewItemClicked(int listid, int index) {}

  Future<Object> onHeaderStartRefresh(int listid) => null;

  Future<Object> onFooterStartRefresh(int listid) => null;

  ZWGridInfo onGridViewGetConfig(int gridid) => ZWGridInfo.noramlInfo();
}

///视图中间件...
// ignore: must_be_immutable
class BaseView extends StatefulWidget {
  ViewCtr vc;
  BaseView({Key key, this.vc}) : super(key: key);
  @override
  State<BaseView> createState() => BaseState();
}

///导航View,默认会添加名为 root 的路由表,用于返回首页
///主要是外层需要包裹 StatelessWidget的组件..
class BaseNavView extends StatelessWidget {
  final BaseView view;
  final Key key;
  final ViewCtr vc;
  BaseNavView({this.vc, this.view, this.key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: BaseVC.mappname,
        home: view,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ));
  }
}

///状态中间件....
class BaseState extends State<BaseView> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => widget.vc.wantKeepAlive;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.vc.vcBuildWidget(context, this);
  }

  @override
  void initState() {
    super.initState();
    widget.vc.onInitVC();
  }

  @override
  void reassemble() {
    super.reassemble();
    widget.vc.onDebugReLoad();
  }
}

///封装的tabbar控制器
class BaseTabBarVC extends BaseVC {
  BaseTabBarVC() {
    mPageName = "tabbar";
  }

  ///底部tabbar的文字列表
  // ignore: non_constant_identifier_names
  var tabitem_txt = <String>[];

  ///底部tabbar的图标列表
  // ignore: non_constant_identifier_names
  var tabitme_icon = [];

  ///底部tabbar 对应的每个VC
  // ignore: non_constant_identifier_names
  var tabitme_vc = <BaseVC>[];

  var _pageController = PageController();

  ///底部tabbar被点击
  void onTabbarItemClicked(int index) {
    tabbar_current_selected = index;
    _pageController.jumpToPage(index);
    updateUI();
  }

// ignore: non_constant_identifier_names
  Color _tabbar_item_selected_color = Colors.amber[800];
  Widget makeBottomBar(BuildContext context) {
    assert(tabitem_txt.length != 0 || tabitme_icon.length != 0);
    assert(tabitem_txt.length == tabitme_icon.length);
    var items = <BottomNavigationBarItem>[];
    for (int i = 0; i < tabitem_txt.length; i++) {
      var _icon = tabitme_icon[i];
      items.add(BottomNavigationBarItem(
          title: Text(tabitem_txt[i]),
          icon: (_icon is String
              ? ImageIcon(AssetImage(tabitme_icon[i]))
              : Icon(_icon))));
    }
    return BottomNavigationBar(
        onTap: (value) => onTabbarItemClicked(value),
        items: items,
        currentIndex: tabbar_current_selected,
        selectedItemColor: _tabbar_item_selected_color);
  }

  @override
  Widget realBuildWidget(BuildContext context) {
    // ignore: non_constant_identifier_names

    return MaterialApp(
        title: "tabbar",
        home: Scaffold(
            body: PageView.builder(
          physics: NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            BaseVC tab_item_basevc = this.tabitme_vc[index];
            tab_item_basevc.tabbar_current_selected = index;
            //一个页面分3部分,底部tabbar,顶部Navbar,中部body
            //如果有tabbar,那么 tabbar 归 要显示tabbar的VC管理,中部和顶部由 对应的tab页面管理,和iOS类似吧
            tab_item_basevc.tabbar_Widget = makeBottomBar(context);
            tab_item_basevc.wantKeepAlive = true;
            return tab_item_basevc.getView();
          },
          controller: _pageController,
          itemCount: tabitme_vc.length,
        )));
  }

  @override
  Widget getView({Key key}) {
    return BaseView(vc: this, key: key);
  }

  @override
  Widget makePageBody(BuildContext context) {
    // TODO: implement makePageBody
    throw UnimplementedError();
  }
}
