import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

///刷新回调,bheader 是头部,否则是底部,bstart 是开始刷新,否则完成刷新
typedef ZWRefeshCallback = Future<Object> Function(bool bheader, bool bstart);

///一个下拉刷新,上拉加载的组件
///原理很简单,监听滚动条位置,拉到一定位置就在某些地方显示某些东西~~
///最外层就是 ZWRefresh,上下就是指示器,提示信息部分,中间就是列表
///+---------------------+
///|    +------------+   |
///|    |  indicator |   |
///|    +------------+   |
///|    |            |   |
///|    |            |   |
///|    |            |   |
///|    |            |   |
///|    |  listivew  |   |
///|    |            |   |
///|    |            |   |
///|    |            |   |
///|    |            |   |
///|    +------------+   |
///|    |  indicator |   |
///|    +------------+   |
///+---------------------+
class ZWRefreshView extends StatefulWidget {
  ///对应的列表视图
  final Widget list;
  final ZWBaseHeaderImmp header;
  final ZWBaseHeaderImmp footer;

  ///刷新回调
  final ZWRefeshCallback callback;

  ///是不是外面在手动强制下拉刷新
  bool isManualRefreshing = false;
  ZWRefreshView(
      {Key key, this.list, this.header, this.footer, @required this.callback})
      : super(key: key) {
    assert(this.header != null || this.footer != null,
        "header or footer must has one.");
  }
  //带有普通的下拉刷新和上拉加载..
  ZWRefreshView.withBaseHeader({Key key, this.list, this.callback})
      : this.header = ZWBaseHeader(),
        this.footer = ZWBaseFooter(),
        super(key: key);

  @override
  State<StatefulWidget> createState() => ZWRefreshState();
}

class ZWRefreshState extends State<ZWRefreshView>
    with SingleTickerProviderStateMixin {
  AnimationController anctr;

  ZWBaseHeaderImmp nowrefreshing;
  @override
  void initState() {
    super.initState();

    anctr = AnimationController(
        duration: const Duration(milliseconds: 200), vsync: this);
    anctr.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        //log("AnimationStatus.completed");
        nowrefreshing.refreshCompleted();
        nowrefreshing = null;
        anctr.reset();
      }
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    anctr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (nowrefreshing != null &&
            nowrefreshing.getRefreshStatus() == RefreshStatus.status_done ||
        true) {
      //这里全部都包裹到动画里面,如果来回切换 底部刷新,无法保留滚动条到最底部位置
      ///如果这样有其他问题,就只有主动设置滚动条位置
      return AnimatedBuilder(
          child: widget.list,
          animation: anctr,
          builder: (context, child) {
            return _build(context, child);
          });
    } else {
      return _build(context, null);
    }
  }

  Widget _build(BuildContext context, Widget child) {
    Widget _list = NotificationListener<ScrollNotification>(
      child: child == null ? widget.list : child,
      onNotification: onScrollNotif,
    );
    _list = Listener(
        child: _list, onPointerUp: (PointerUpEvent e) => _onPointerUp(e));

    List<Widget> cs = [];

    if (widget.header != null &&
        widget.header.getRefreshStatus() != RefreshStatus.status_normal) {
      //如果有header,并且已经不是普通状态,就需要显示了
      //log("header....");
      cs.add(getHeaderFooter(context, true));
    }
    if (widget.footer != null &&
        widget.footer.getRefreshStatus() != RefreshStatus.status_normal) {
      //log("footer....");
      cs.add(getHeaderFooter(context, false));
    }

    _list = Padding(
      padding: EdgeInsets.only(top: getListTopAt(), bottom: getListBottomAt()),
      child: _list,
    );
    cs.add(_list);
    return Stack(
        children: cs, fit: StackFit.expand, alignment: Alignment.topCenter);
  }

  void _onPointerUp(PointerUpEvent e) {
    if (widget.header != null && widget.header.touchup(_headerDragDiff)) {
      //log("start header");
      nowrefreshing = widget.header;
      _headerDragDiff = 0;
      widget.callback(true, true).then((value) => onRefreshOk(value, true));
    }
    if (widget.footer != null && widget.footer.touchup(_footerDragDiff)) {
      //log("start footer");
      nowrefreshing = widget.footer;
      _footerDragDiff = 0;
      widget.callback(false, true).then((value) => onRefreshOk(value, false));
    }
  }

  double getListTopAt() {
    if (widget.header == null) return 0;
    RefreshStatus ss = widget.header.getRefreshStatus();
    //这种情况就需要 listview 停留在header之下
    if (ss == RefreshStatus.status_refreshing)
      return widget.header.getHeight() + widget.header.showatRefreshing();
    //如果是完成了,那么开始做动画了,
    if (ss == RefreshStatus.status_done) {
      if (anctr.isAnimating)
        return (anctr.upperBound - anctr.value) * widget.header.getHeight();
      else //如果还没开始动画,还处理停留状态,先继续停留
        return widget.header.getHeight() + widget.header.showatRefreshing();
    }
    return 0;
  }

  double getListBottomAt() {
    if (widget.footer == null) return 0;
    RefreshStatus ss = widget.footer.getRefreshStatus();
    //这种情况就需要 listview 停留在header之下
    if (ss == RefreshStatus.status_refreshing)
      return widget.footer.getHeight() + widget.footer.showatRefreshing();
    //如果是完成了,那么开始做动画了,
    if (ss == RefreshStatus.status_done) {
      if (anctr.isAnimating)
        return (anctr.upperBound - anctr.value) * widget.footer.getHeight();
      else
        return widget.footer.getHeight() + widget.footer.showatRefreshing();
    }
    return 0;
  }

  Widget getHeaderFooter(BuildContext context, bool bheader) {
    if (bheader) {
      double _v = null;
      if (widget.header.getRefreshStatus() == RefreshStatus.status_done) {
        if (anctr.isAnimating || anctr.isCompleted)
          _v = anctr.value * widget.header.getHeight() * -1;
        else //处理刷新完成之后的悬停.....
          _v = widget.header.showatRefreshing();
      }
      return Positioned(
          child: widget.header.getWidget(context),
          top: _v == null ? widget.header.showat(_headerDragDiff) : _v,
          height: widget.header.getHeight());
    } else {
      double _v = null;
      if (widget.footer.getRefreshStatus() == RefreshStatus.status_done) {
        if (anctr.isAnimating || anctr.isCompleted)
          _v = anctr.value * widget.footer.getHeight() * -1;
        else {
          _v = widget.footer.showatRefreshing();
        }
      }
      return Positioned(
          child: widget.footer.getWidget(context),
          bottom: _v == null ? widget.footer.showat(_footerDragDiff) : _v,
          height: widget.footer.getHeight());
    }
  }

  void onRefreshOk(Object value, bool bheader) {
    if (bheader)
      widget.header.refreshDone(value);
    else
      widget.footer.refreshDone(value);

    widget.callback(bheader, false);

    setState(() {});
    //停留下完成的显示内容,再开始慢慢消失
    Future.delayed(Duration(milliseconds: 400), () {
      //log("start forward");
      anctr.forward();
    });
  }

  bool onScrollNotif(ScrollNotification notification) {
    //log("scroll_pixels:" + notification.metrics.pixels.toStringAsFixed(2));
    /*log("scroll_pixels:" +
        notification.metrics.pixels.toStringAsFixed(2) +
        " maxSc:" +
        notification.metrics.maxScrollExtent.toStringAsFixed(2) +
        " minSc:" +
        notification.metrics.minScrollExtent.toStringAsFixed(2) +
        " Before:" +
        notification.metrics.extentBefore.toStringAsFixed(2) +
        " side:" +
        notification.metrics.extentInside.toStringAsFixed(2) +
        " After:" +
        notification.metrics.extentAfter.toStringAsFixed(2) +
        " viewportDimension " +
        notification.metrics.viewportDimension.toStringAsFixed(2) +
        " dic:" +
        notification.metrics.axisDirection.toString());*/

    if (widget.header != null) {
      if (notification.metrics.pixels <= notification.metrics.minScrollExtent) {
        _onDragingHeader(notification.metrics.pixels.abs());
      }
    }
    if (widget.footer != null) {
      if (notification.metrics.pixels >= notification.metrics.maxScrollExtent) {
        _onDragingFooter(
            notification.metrics.pixels - notification.metrics.maxScrollExtent);
      }
    }
    return false;
  }

  void _onDragingHeader(double dragoffset) {
    _headerDragDiff = dragoffset;
    widget.header.draging(_headerDragDiff);
    if (widget.header.getRefreshStatus() == RefreshStatus.status_done &&
        anctr.isAnimating) {
      ///顶部刷新,暂时没有发现底部那个问题..但是先处理
    } else {
      setState(() {});
    }
    if (widget.isManualRefreshing && dragoffset > widget.header.getExpSpace()) {
      _onPointerUp(null);
    }
  }

  void _onDragingFooter(double dragoffset) {
    _footerDragDiff = dragoffset;
    widget.footer.draging(_footerDragDiff);
    if (widget.footer.getRefreshStatus() == RefreshStatus.status_done &&
        anctr.isAnimating) {
      ///当底部刷新完成的时候,移动listview的时候,依然会有滚动事件,
      ///这时候如果调用 setState 会有错误
    } else {
      setState(() {});
    }
    if (widget.isManualRefreshing && dragoffset > widget.footer.getExpSpace()) {
      _onPointerUp(null);
    }
  }

  double _headerDragDiff = 0;
  double _footerDragDiff = 0;
}

///当前指示器刷��状态
enum RefreshStatus {
  ///普���状态,还没有��示出来的时候
  status_normal,

  ///正������被拖动
  status_draging,

  ///拖动距��已经足够了,���手即可触发刷新
  status_drag_enough,

  ///开始刷新状��了,等待刷新完成,
  status_refreshing,

  ///刷新完成
  status_done
}

abstract class ZWBaseHeaderImmp {
  ///获取当前状态
  RefreshStatus getRefreshStatus() => RefreshStatus.status_normal;

  ///获取header的高度
  double getHeight() => 0;

  ///获取刷新临界点值,比如,下拉超过50松手就可以开始刷新
  double getExpSpace() => 0;

  ///返回真正的布���组件
  Widget getWidget(BuildContext context) => null;

  ///询问应该显示到什么地方,外层是stack,这里header,footer使用绝对布局位置
  ///header返回距离top的位置,footer返������距离bottom的位置
  ///dragoffset 表示滚动超过顶部,底部多少了,
  ///这个方��被调用说明已经开始要布局了.
  double showat(double dragoffset) => null;

  ///刷新的时候���留位置
  double showatRefreshing() => 0;

  ///开始拖动了,告知拖动了��少
  void draging(double dragoffset) {}

  ///滚动���拖动停止���,手放开了,
  /// dragoffset 放开的时候的位置,需要返回���否已经触发了刷新,
  bool touchup(double dragoffset) => false;

  ///刷新回调完成了,数据加载好了,状态变成 done,
  void refreshDone(Object val) {}

  ///整个刷新流程完成,状态恢复到了 noraml,意味着隐藏动画结束了,
  void refreshCompleted() {}
}

class ZWBaseHeader implements ZWBaseHeaderImmp {
  RefreshStatus getRefreshStatus() {
    return _refreshstatus;
  }

  @override
  void draging(double dragoffset) {
    ///如果已经是刷新状态了,不更新状态了
    if (_refreshstatus == RefreshStatus.status_refreshing) return;

    ///如果是刷新完成,也不管,动画完成会自动恢复
    if (_refreshstatus == RefreshStatus.status_done) return;

    _refreshstatus = dragoffset > getExpSpace()
        ? RefreshStatus.status_drag_enough
        : RefreshStatus.status_draging;
  }

  @override
  double getExpSpace() {
    return 50;
  }

  @override
  double getHeight() {
    return 50;
  }

  @override
  Widget getWidget(BuildContext context) {
    String _desc = "继续下拉刷新数据";
    Widget Indic;
    if (_refreshstatus == RefreshStatus.status_refreshing) {
      _desc = "正在刷新数据...";
      Indic = SizedBox(
        child: CircularProgressIndicator(strokeWidth: 3),
        height: 25,
        width: 25,
      );
    } else if (_refreshstatus == RefreshStatus.status_drag_enough) {
      _desc = "松开立即刷新数据";
      Indic = Icon(Icons.arrow_upward);
    } else if (_refreshstatus == RefreshStatus.status_done) {
      _desc = "刷新完成";
      Indic = Icon(Icons.done);
    } else
      Indic = Icon(Icons.arrow_downward);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Indic,
        Padding(padding: EdgeInsets.only(left: 5), child: Text(_desc))
      ],
    );
  }

  ///刷新回调完成了,数据加载好了,状态变成 done,
  void refreshDone(Object val) {
    _refreshstatus = RefreshStatus.status_done;
  }

  ///整个刷新流程完成,状态恢复到了 noraml,意味着隐藏动画结束了,
  void refreshCompleted() {
    _refreshstatus = RefreshStatus.status_normal;
  }

  RefreshStatus _refreshstatus = RefreshStatus.status_normal;

  @override
  double showat(double dragoffset) {
    if (_refreshstatus == RefreshStatus.status_refreshing) {
      //如果已经进入了刷新状态,,那么显示的位置就固定下来,先别弹回去,
      return showatRefreshing();
    }
    double v = getHeight();
    if (v == null) {
      v = 0;
    } else {
      v = dragoffset - getHeight();
      //log("will show header at:" + v.toStringAsFixed(2));
    }
    return v;
  }

  @override
  bool touchup(double dragoffset) {
    if (_refreshstatus == RefreshStatus.status_refreshing) return false;
    if (dragoffset > getExpSpace())
      _refreshstatus = RefreshStatus.status_refreshing;
    else
      _refreshstatus = RefreshStatus.status_normal;
    return _refreshstatus == RefreshStatus.status_refreshing;
  }

  @override
  double showatRefreshing() {
    return 10;
  }
}

class ZWBaseFooter extends ZWBaseHeader {
  ///footer的刷新完成,单独处理,因为在隐藏动画完成之后,Listview居然继续在发起滚动事件
  ///因为刷新之前拖动的滚动条位置并不是底部,这时候他继续回归到底部,所以感觉是在拉动,就又会把
  ///footer拉出来,这里做个延时拦截拉动

  bool _justcomp = false;
  @override
  void draging(double dragoffset) {
    if (!_justcomp) super.draging(dragoffset);
  }

  @override
  void refreshCompleted() {
    super.refreshCompleted();
    _justcomp = true;
    Future.delayed(Duration(milliseconds: 300), () {
      _justcomp = false;
    });
  }

  @override
  Widget getWidget(BuildContext context) {
    String _desc = "继续上拉加载更多数据";
    Widget Indic;
    //log("get status:" + _refreshstatus.toString());
    if (_refreshstatus == RefreshStatus.status_refreshing) {
      _desc = "正在加载数据...";
      Indic = SizedBox(
        child: CircularProgressIndicator(strokeWidth: 3),
        height: 25,
        width: 25,
      );
    } else if (_refreshstatus == RefreshStatus.status_drag_enough) {
      _desc = "松开立即加载更多";
      Indic = Icon(Icons.arrow_downward);
    } else if (_refreshstatus == RefreshStatus.status_done) {
      _desc = "加载完成";
      Indic = Icon(Icons.done);
    } else
      Indic = Icon(Icons.arrow_upward);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Indic,
        Padding(padding: EdgeInsets.only(left: 5), child: Text(_desc))
      ],
    );
  }
}
