import 'dart:async';
import 'dart:developer';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:logger/logger.dart';
import 'package:zwbase_flutter/zwbase_flutter.dart';

import 'zwhud.dart';
import 'zwrefreshlistvc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

///这里是参考之前IOS的基类,将常用的方法封装了
abstract class ViewCtr {
  BuildContext _context;
  BaseState _state;

  //是否显示右上角的调试图标
  bool get mShowDebugBanner => true;

  MediaQueryData mMediaQueryData;

  ///衔接state的 build 方法,将控件布局引入到控制器
  Widget vcBuildWidget(BuildContext context, BaseState state) {
    _context = context;
    _state = state;
    return realBuildWidget(context);
  }

  ///等待必须要的操作的时候UI显示,
  Widget waitingNecessaryOp() {
    return Center(child: Text("加载中..."));
  }

  ///控制器的真正build方法
  Widget realBuildWidget(BuildContext context);

  ///导出控制器真正的布局数据
  Widget getView({Key key}) {
    return BaseView(key: key, vc: this);
  }

  ///控制器更新数据,就是setstate
  void updateUI() {
    if (!kReleaseMode && _state == null && mIsDidBuildOnce) {
      vclog("maybe update when state is null");
    }
    _state?.setState(() {});
  }

  ///初始化控制器,子类自己初始化完成之后,调用父类
  ///inited 告诉父类,是否初始化完成了,可以显示了,
  ///如果false,那么后续尽快调用 allInitOK,否则 realBuildWidget 不会被执行
  ///如果ture,那么表明都初始化完成了,会按流程执行 realBuildWidget
  ///这里这样设计原因是,需要找到一个异步加载APP运行必须要的数据的机会,
  @mustCallSuper
  void onInitVC() {
    vclog("onInitVC");
  }

  ///调试重新热加载,reassemble被执行
  @mustCallSuper
  void onDebugReLoad() {
    vclog("onDebugReLoad...");
  }

  ///是否完成了至少一次build
  bool mIsDidBuildOnce = false;

  ///onDidBuild 之前被调用
  @mustCallSuper
  void onPreBuild() {
    vclog("onPreBuild");
  }

  ///根部组件变化之后会被执行,比如,第一次,子组件变化不会执行
  @mustCallSuper
  void onDidBuild() {
    vclog("onDidBuild");
    mIsDidBuildOnce = true;
  }

  ///被移除了显示,比如需要停止些动画什么的,deactivate被执行
  @mustCallSuper
  void onDidRemoved() {
    vclog("onDidRemoved");
  }

  ///state的dispose被执行,被释放的时候
  @mustCallSuper
  void onDispose() {
    vclog("onDispose");

    ///返回之后,直接将 _state 置空,防止继续更新
    _state = null;
  }

  void onAppLifecycleState(AppLifecycleState appState) {}

  ///是否自动保留,否则页面隐藏不显示的时候被移除了tree..,主要是tabbar的子页面
  bool wantKeepAlive = false;

  ///日志输出
  vclog(String msg) {
    log(msg);
  }
}

///基础控制器
abstract class BaseVC extends ViewCtr implements ZWListVCDelegate {
  var _logger = Logger(
      printer: PrettyPrinter(
    methodCount: 1,
    printTime: true,
  ));

  @override
  vclog(String msg) {
    _logger.d(msg);
  }

  BuildContext getContext() => _context;

  //获取控制器对应的视图
  Widget getView({Key key}) {
    assert(mPageName != null, "为页面取个名字");
    //如果是导航的根view,那么需要包裹一层导航视图,主要是最外层必须StatelessWidget,
    if (bIsNavRootVC)
      return BaseNavView(vc: this, view: BaseView(key: key, vc: this));
    //如果已经外层有了导航视图,那么这里不需要包裹导航视图了,普通页面都是这个
    if (bHasNavView) return BaseView(key: key, vc: this);

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

  ///页面的背景颜色,透明,可以制作半透明的控制器
  Color mBackGroudColor;

  ///创建主要的控件部分,导航栏,tabbar,返回按钮,右侧按钮,标题等,底部tabbar由外部创建传入即可
  Widget realBuildWidget(BuildContext context) {
    mMediaQueryData = MediaQuery.of(context);

    Widget t = Scaffold(
        backgroundColor: mBackGroudColor,
        resizeToAvoidBottomInset: false,
        appBar: makeTopBar(context),
        body: wapperForExt(makePageBody(context), context),
        bottomNavigationBar: tabbar_Widget,
        //去除虚拟键
        resizeToAvoidBottomPadding: false);
    var l = [t];

    ///如果有扩展覆盖层,那么就用stack堆积起来
    if (extOverlayer != null) l.add(extOverlayer);

    t = Stack(
      children: l,
      fit: StackFit.expand,
      alignment: Alignment.center,
    );

    return MaterialApp(
      title: BaseVC.mappname,
      home: t,
      theme: getThemeData(context),
      debugShowCheckedModeBanner: mShowDebugBanner,

      ///这玩意没搞懂~~,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        //奇葩问题,
        //https://blog.csdn.net/julystroy/article/details/90231588
        const FallbackCupertinoLocalisationsDelegate(),
      ],
      localeResolutionCallback: onGetLocalInfo,
      supportedLocales: getSupportedLocals(),
      //locale: ,先不考虑那么复杂的情况,本地这个就先不管了,遇到书写顺序有问题的再说
    );
  }

  ///当获取到区域信息之后的回调
  Locale onGetLocalInfo(Locale locale, Iterable<Locale> supportedLocales) {
    //记录当前系统的语言,和地区设置
    sysLang = locale.languageCode;
    sysCountry = locale.countryCode;
    vclog("get app local info:$locale");
    return locale;
  }

  ///子类重载..
  List<Locale> getSupportedLocals() {
    return [Locale('zh'), Locale('en')];
  }

  ///当前系统的语言,默认英语
  static String sysLang = 'en';

  ///当前系统的地区,国家
  static String sysCountry = 'US';

  ///获取主题数据
  ThemeData getThemeData(BuildContext context) {
    ///主题这玩意感觉太复杂了,flutter有自己的逻辑,如果设计不是这种思路,就太麻烦了
    ///比如按钮,看 button_theme.dart 源码,textcolor设置,不是简单的设置,是根据各个情况来自己设置的,
    return ThemeData(
      ///主题颜色,比如 导航栏背景 通常是最能表明一个App主题的,
      ///FloatingActionButton背景色也是这里
      primarySwatch: Colors.blue,
      //buttonColor: Colors.green,//RaisedButton的背景色,下面也可以设置
      //buttonTheme: ButtonTheme.of(context).copyWith(buttonColor: Colors.white, textTheme: ButtonTextTheme.primary),

      //textTheme: TextTheme(bodyText2: TextStyle(color: Colors.white)), //普通的text的前景色
      scaffoldBackgroundColor: Colors.white,

      ///APP的空白地方背景色
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  ///正常创建页面业务控件的地方,子类继承并且修改这个,
  ///就是之前的build方法里面创建body的部分
  Widget makePageBody(BuildContext context);

  ///是否需要键盘处理,比如有输入框,滚动视图,输入状态点击空白消失
  bool mEnableKeyBoardHelper = false;

  Widget wapperForKeyBoard(Widget body, BuildContext context) {
    return GestureDetector(
      child: SingleChildScrollView(child: body),
      onTap: () => onTapedWhenKeyBoardShow(),
    );
  }

  ///用于控制输入焦点.处理键盘
  FocusNode mFocusNode = FocusNode();
  void onTapedWhenKeyBoardShow() {
    mFocusNode.unfocus();
  }

  ///方便扩展处理,
  Widget wapperForExt(Widget body, BuildContext context) {
    if (mEnableKeyBoardHelper) return wapperForKeyBoard(body, context);
    return body;
  }

  ///扩展层的动画控制
  AnimationController animationCtrForExt;

  ///用于扩展显示覆盖层,比如,HUD,
  Widget _extOverlayer;
  Widget get extOverlayer => _extOverlayer;

  ///HUD动画时间
  int get hudAnimationLong => 250;

  set extOverlayer(Widget val) {
    if (animationCtrForExt == null) {
      animationCtrForExt = AnimationController(
          vsync: _state, duration: Duration(milliseconds: hudAnimationLong));
    }
    if (val != null) {
      animationCtrForExt.reset();
      _extOverlayer = FadeTransition(
        opacity: animationCtrForExt,
        child: val,
      );
      updateUI();
      animationCtrForExt.reset();
      animationCtrForExt.forward();
    } else {
      //如果是要值空
      if (_extOverlayer != null) {
        animationCtrForExt.reverse().then((value) {
          whenDismisscb?.call();
          whenDismisscb = null;
          _extOverlayer = null;
          updateUI();
        });
      } else {
        //如果已经是空了,那么立即返回cb,因为可能 whenDismisscb有人在等待
        whenDismisscb?.call();
        whenDismisscb = null;
      }
    }
  }

  ///显示HUD加载中
  void hudShowLoading(String msg) {
    extOverlayer = ZWHud(showType: 0, showMsg: msg);
  }

  VoidCallback whenDismisscb;

  ///显示HUD错误信息
  Future<void> hudShowErrMsg(String msg) {
    extOverlayer = ZWHud(
      showType: 2,
      showMsg: msg,
    );
    return autoDismissHUD(msg.length > 11 ? 3000 : 1500);
  }

  ///显示HUD 成功新
  Future<void> hudShowSuccessMsg(String msg) {
    extOverlayer = ZWHud(
      showType: 1,
      showMsg: msg,
    );
    return autoDismissHUD(msg.length > 11 ? 3000 : 1500);
  }

  Future<void> hudShowInfoMsg(String msg) {
    extOverlayer = ZWHud(showType: 3, showMsg: msg);
    return autoDismissHUD(msg.length > 11 ? 3000 : 1500);
  }

  Future<void> autoDismissHUD([int dealy = 3000]) {
    return Future.delayed(
        Duration(milliseconds: dealy), () => this.hudDismiss());
  }

  ///消失HUD
  Future<void> hudDismiss() {
    var comp = Completer();
    whenDismisscb = () => comp.complete();
    extOverlayer = null;
    return comp.future;
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
  bool bHasNavView = false;
  bool bIsNavRootVC = false;
  void iAMNavRootView() {
    bIsNavRootVC = true;

    ///如果是导航的rootview,通常自动把返回按钮隐藏了
    mHidenBackBt = true;
  }

  ///页面的返回值
  dynamic mRetVal;
  void popBack() {
    if (Navigator.of(this._context).canPop()) {
      Navigator.pop(_context, mRetVal);
      return;
    }
    if (this.bIsPresent) {
      dismissPreSentVC();
      return;
    }
    log("can not pop ,now is root");
  }

  ///返回到root VC,
  void popToRoot() {
    Navigator.of(this._context).popUntil(ModalRoute.withName("/"));
  }

  ///PUSH到指定VC,并且有返回异步返回值
  Future<dynamic> pushToVC(BaseVC to) {
    to.bHasNavView = this.bHasNavView || bIsNavRootVC;
    to.bIsPresent = this.bIsPresent;
    return Navigator.of(this._context).push(MaterialPageRoute(
        maintainState: true,
        builder: (context) {
          return to.getView();
        }));
  }

  ///PUSH到指定VC,并且有返回异步返回值,淡入动画,
  Future<dynamic> pushToVCFade(BaseVC to) {
    to.bHasNavView = this.bHasNavView || bIsNavRootVC;
    to.bIsPresent = this.bIsPresent;
    return Navigator.of(this._context).push(PageRouteBuilder(
      transitionDuration: Duration(milliseconds: 500),
      pageBuilder: (context, animation, secondaryAnimation) {
        return new FadeTransition(
          //使用渐隐渐入过渡,
          opacity: animation,
          child: to.getView(), //路由B
        );
      },
    ));
  }

  ///PUSH到指定VC,并且有返回异步返回值,可以实现透明的VC,默认是淡入动画
  Future<dynamic> pushToTransparentVC(BaseVC to) {
    to.mBackGroudColor = Colors.transparent;
    to.bHasNavView = this.bHasNavView || bIsNavRootVC;
    to.bIsPresent = this.bIsPresent;
    return Navigator.of(this._context)
        .push(CustomTransitionRoute((context) => to.getView()));
  }
  //更多路由动画. https://www.cnblogs.com/joe235/p/11230780.html

  ///直接跳转到指定VC,不保留当前页面在栈里面
  void setToVC(BaseVC to) {
    to.bHasNavView = this.bHasNavView || bIsNavRootVC;
    to.bIsPresent = this.bIsPresent;
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
  bool bIsPresent = false;

  ///上一个界面的context
  BuildContext _presentMeContext;

  ///�������态弹出VC,
  Future<dynamic> presentVC(BaseVC to) {
    to.bIsPresent = true;
    to.bHasNavView = this.bHasNavView || bIsNavRootVC;
    to._presentMeContext = this._context;
    return Navigator.of(this._context).push(MaterialPageRoute(
        fullscreenDialog: true,
        maintainState: true,
        builder: (context) {
          return to.getView();
        }));
  }

  ///消失 presentVC来的VC
  void dismissPreSentVC() {
    if (this._presentMeContext != null)
      Navigator.pop(this._presentMeContext, mRetVal);
  }

  void delayBackClicked() {
    Future.delayed(Duration(milliseconds: 300), () => this.popBack());
  }

  ///显示对话框,返回点击事件索引,0:取消,1:确定
  Future<int> showAlert(String title, String msg,
      [String leftbtstr = "取消", String rightbtstr = "确定"]) {
    var acts = <Widget>[];
    var _c = new Completer<int>();
    if (leftbtstr == null && rightbtstr == null) {
      ///无确定的对话框...一直挡住
    } else {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        if (leftbtstr != null)
          acts.add(CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => {extOverlayer = null, _c.complete(0)},
              child: Text(leftbtstr)));
        acts.add(CupertinoDialogAction(
            onPressed: () => {extOverlayer = null, _c.complete(1)},
            child: Text(rightbtstr)));
      } else {
        if (leftbtstr != null)
          acts.add(FlatButton(
              onPressed: () => {extOverlayer = null, _c.complete(0)},
              child: Text(leftbtstr)));
        acts.add(FlatButton(
            onPressed: () => {extOverlayer = null, _c.complete(1)},
            child: Text(rightbtstr)));
      }
    }

    extOverlayer = Container(
        color: Colors.transparent,
        constraints: BoxConstraints(
            minWidth: double.infinity, minHeight: double.infinity),
        child: defaultTargetPlatform == TargetPlatform.iOS
            ? CupertinoAlertDialog(
                title: Text(title),
                content: Text(msg),
                actions: acts,
              )
            : AlertDialog(
                title: Text(title), content: Text(msg), actions: acts));
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
        decoration:
            InputDecoration(hintText: holder, border: InputBorder.none));
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      acts.add(CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () => {extOverlayer = null, _c.complete("")},
          child: Text(leftbtstr)));
      acts.add(CupertinoDialogAction(
          onPressed: () => {extOverlayer = null, _c.complete(_input_ctr.text)},
          child: Text(rightbtstr)));
    } else {
      acts.add(SimpleDialogOption(
          onPressed: () => {extOverlayer = null, _c.complete("")},
          child: Text(leftbtstr)));
      acts.add(SimpleDialogOption(
          onPressed: () => {extOverlayer = null, _c.complete(_input_ctr.text)},
          child: Text(rightbtstr)));
    }
    extOverlayer = Container(
        color: Colors.transparent,
        constraints: BoxConstraints(
            minWidth: double.infinity, minHeight: double.infinity),
        child: defaultTargetPlatform == TargetPlatform.iOS
            ? CupertinoAlertDialog(
                title: Text(title), content: _t, actions: acts)
            : AlertDialog(title: Text(title), content: _t, actions: acts));
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
  //当前页码
  int mPage = 0;

  ///当前列表视图控制器,这3个变量作用就是快捷简化处理列表问题
  ///mItListVC记得将mItListVC赋值,如果不是base创建的
  ZWRefreshListVC mItListVC;

  ///创建带下拉列表,刷新列表控制器,创建了,通过 mItListVC获取
  void createListOrGirdVC(bool blist) {
    assert(mItListVC == null, "you areadly have mItListVC ...");
    mItListVC = ZWRefreshListVC(this, islistview: blist);
  }

  ///下面所有方法都是列表,刷新相关的,回调处理,基本上和IOS的原理差不多了
  int onListViewGetCount(int listid) => this.mDataArr.length;

  Widget onListViewGetItemView(int listid, int index) => null;

  ///获取列表每行高度,和IOS heightForRowAtIndexPath一样,gridview不会执行
  double onListViewGetItemHeight(int listid) => null;

  void onListViewItemClicked(int listid, int index) {}

  ///获取gridview配置,和IOS UICollectionViewFlowLayout 那套意思差不多
  ZWGridInfo onGridViewGetConfig(int gridid) => ZWGridInfo.noramlInfo();

  ///作为base,这里添加一个刷新快捷处理,在普通列表情况下
  ///让子类只需要几个简单的回调就行了
  Future<Object> onHeaderStartRefresh(int listid) async {
    SResBase resb = await onLoadHeaderData(listid);
    vclog("load complteted");

    mDataArr.clear();
    if (resb.mSuccess) {
      hudDismiss();
      mDataArr.addAll(resb.mData);
    } else {
      hudShowErrMsg(resb.mMsg);
    }
    mItListVC.updateListVC();
    return true;
  }

  Future<Object> onFooterStartRefresh(int listid) async {
    SResBase resb = await onLoadFooterData(listid);
    if (resb.mSuccess) {
      hudDismiss();
      mDataArr.addAll(resb.mData);
    } else {
      hudShowErrMsg(resb.mMsg);
    }
    mItListVC.updateListVC();
    return true;
  }

  ///当列表没有数据的时候,显示一个空的提示
  Widget onGetEmptyView(int list) {
    return Center(
      child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 26,
            ),
            Text("暂无数据...")
          ]),
    );
  }

  ///通常一个最简单列表实现2个方法 ,onLoadHeaderData,onListViewGetItemView 这个就类似IOS的cellForRowAtIndexPath
  ///
  ///如果不重写上面的方法,就重新这2个方法,快捷的简单的加载数据
  Future<SResBase> onLoadHeaderData(int listid) {
    assert(false, "immp this func ...");
  }

  Future<SResBase> onLoadFooterData(int listid) {
    assert(false, "immp this func ...");
  }
}

class BaseElement extends StatefulElement {
  BaseElement(StatefulWidget widget) : super(widget);

  @override
  void performRebuild() {
    Element _old;
    visitChildren((element) {
      _old = element;
    });

    super.performRebuild();
    Element _new;
    visitChildren((element) {
      _new = element;
    });

    if (_old != _new) {
      ///延迟35毫秒,30帧率,基本上可以保证已经渲染完了,可以直接在onDidBuild里面做些操作了
      Future.delayed(Duration(milliseconds: 35), () {
        (widget as BaseView).vc.onPreBuild();
        (widget as BaseView).vc.onDidBuild();
      });
    }
  }
}

///视图中间件...串联控制器的地方将控制器和state链接起来
// ignore: must_be_immutable
class BaseView extends StatefulWidget {
  final ViewCtr vc;
  BaseView({Key key, this.vc}) : super(key: key);

  @override
  State<BaseView> createState() => BaseState();
  @override
  StatefulElement createElement() => BaseElement(this);
}

///导航View,
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
        debugShowCheckedModeBanner: vc.mShowDebugBanner,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ));
  }
}

///状态中间件....
class BaseState extends State<BaseView>
    with
        AutomaticKeepAliveClientMixin,
        TickerProviderStateMixin,
        WidgetsBindingObserver {
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
    WidgetsBinding.instance.addObserver(this);

    widget.vc.onInitVC();
  }

  @override
  void reassemble() {
    super.reassemble();
    widget.vc.onDebugReLoad();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
    widget.vc.onDispose();
  }

  @override
  void deactivate() {
    super.deactivate();
    widget.vc.onDidRemoved();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    widget.vc.onAppLifecycleState(state);
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

  ///底部tabbar的图标列表,如果是string就是图标名字,否则是IconData
  // ignore: non_constant_identifier_names
  var tabitme_icon = [];

  ///底部未选中情况下图片
  var tabitme_icon_unselected = [];

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
  Color tabbar_item_selected_color = Colors.amber[800];
  Widget makeBottomBar(BuildContext context) {
    assert(tabitem_txt.length != 0 || tabitme_icon.length != 0);
    assert(tabitem_txt.length == tabitme_icon.length);
    var items = <BottomNavigationBarItem>[];
    for (int i = 0; i < tabitem_txt.length; i++) {
      var _icon = tabitme_icon[i];
      items.add(BottomNavigationBarItem(
          title: Text(tabitem_txt[i]),
          icon: (_icon is String
              ? Image(
                  image: AssetImage(tabitme_icon_unselected[i]),
                  height: 36,
                  width: 36,
                )
              : Icon(_icon)),
          activeIcon: (_icon is String
              ? Image(
                  image: AssetImage(tabitme_icon[i]),
                  width: 36,
                  height: 36,
                )
              : Icon(_icon))));
    }
    return cfgBottomBar(items, context);
  }

  ///单独将配置底部的方法提出来方便继承
  Widget cfgBottomBar(
      List<BottomNavigationBarItem> items, BuildContext context) {
    return BottomNavigationBar(
        onTap: (value) => onTabbarItemClicked(value),
        items: items,
        currentIndex: tabbar_current_selected,
        selectedItemColor: tabbar_item_selected_color,
        type: BottomNavigationBarType.fixed);
  }

  @override
  Widget realBuildWidget(BuildContext context) {
    // ignore: non_constant_identifier_names

    return MaterialApp(
        title: "tabbar",
        debugShowCheckedModeBanner: mShowDebugBanner,
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
    //这个不需要了,直接 重新了 realBuildWidget
    throw UnimplementedError();
  }
}

///验证码按钮
class ZWTickBt extends ViewCtr {
  ZWTickBt(this.onClicked, {this.ticks = 60});
  final VoidCallback onClicked;
  final int ticks;
  String bttext = "获取验证码";

  void _onBtClicked() {
    if (_timer != null && _timer.isActive) return;
    this.onClicked();
  }

  Timer _timer;
  int _timer_ticks;
  void startTick() {
    if (_timer == null) {
      _timer_ticks = this.ticks;
      _timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
        _timer_ticks--;
        bttext = ticks.toString();
        if (ticks == 0) {
          stopTick();
        } else
          updateUI();
      });
      return;
    }
  }

  void stopTick() {
    _timer?.cancel();
    _timer = null;
    bttext = "获取验证码";
    updateUI();
  }

  @override
  Widget realBuildWidget(Object context) {
    return FlatButton(
      textColor: Colors.white,
      onPressed: () => _onBtClicked(),
      child: Text(
        bttext,
        style: TextStyle(fontSize: 12),
      ),
      color: Color.fromARGB(255, 249, 105, 77),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
    );
  }
}

///自定义的过度路由,主要是创建透明的路由页面
class CustomTransitionRoute extends PageRoute {
  CustomTransitionRoute(this.builder, {this.transitBuilder}) : super();
  final WidgetBuilder builder;
  final RouteTransitionsBuilder transitBuilder;

  @override
  Color get barrierColor => null;

  @override
  bool get opaque => false;

  @override
  String get barrierLabel => null;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return this.builder(context);
  }

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => Duration(milliseconds: 200);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (this.transitBuilder != null)
      return this.transitBuilder(context, animation, secondaryAnimation, child);
    return FadeTransition(opacity: animation, child: child);
  }
}

//https://blog.csdn.net/julystroy/article/details/90231588
class FallbackCupertinoLocalisationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const FallbackCupertinoLocalisationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      DefaultCupertinoLocalizations.load(locale);

  @override
  bool shouldReload(FallbackCupertinoLocalisationsDelegate old) => false;
}
