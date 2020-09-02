import 'package:flutter/material.dart';

import 'base.dart';
import 'zwrefresh.dart';

class ZWGridInfo {
  ZWGridInfo(int columnCount, double columnSpace, double rowSpace, aspectRatio)
      : this.columnCount = columnCount,
        this.columnSpace = columnSpace,
        this.rowSpce = rowSpace,
        this.aspectRatio = aspectRatio;

  ///有多少列表,如果是横向滚动表示多少有行
  final int columnCount;

  ///列间距,如果横向滚动和下面互换
  final double columnSpace;

  ///行间距,如果横向滚动和上面互换
  final double rowSpce;

  ///宽高比例,如果横向滚动就是高宽比例
  final double aspectRatio;

  //返回一个常用的grid布局信息,2列,间距10,item大小一样
  ZWGridInfo.noramlInfo()
      : this.columnCount = 2,
        this.columnSpace = 10,
        this.rowSpce = 10,
        this.aspectRatio = 1;
}

abstract class ZWListVCDelegate {
  int onListViewGetCount(int listid);

  Widget onListViewGetItemView(int listid, int index);

  double onListViewGetItemHeight(int listid);

  void onListViewItemClicked(int listid, int index);

  Future<Object> onHeaderStartRefresh(int listid);

  Future<Object> onFooterStartRefresh(int listid);

  ZWGridInfo onGridViewGetConfig(int gridid);

  Widget onGetEmptyView(int list);
}

class ZWRefreshListVC extends ViewCtr implements ZWListVCDelegate {
  ZWRefreshListVC(ZWListVCDelegate delegate,
      {int id = 0, bool islistview = true})
      : this.mListId = id,
        this.mDelegate = delegate,
        this._isListView = islistview,
        assert(delegate != null, "must has delegate") {
    if (_isListView)
      _listview = ZWListVC(id, delegate, mShowScrollBar);
    else
      _gridview = ZWGridVC(id, delegate, mShowScrollBar);
  }

  final ZWListVCDelegate mDelegate;

  //列表ID
  final int mListId;

  final bool _isListView;

  ZWListVC _listview;
  ZWGridVC _gridview;

  ZWListVC _getTagView() {
    return _isListView ? _listview : _gridview;
  }

  //是否滚动条
  bool _mShowScrollBar = true;
  bool get mShowScrollBar => _mShowScrollBar;
  set mShowScrollBar(bool val) {
    _mShowScrollBar = val;
    _getTagView().scrollbar = val;
    this.updateUI();
    this.updateListVC();
  }

  ///是否有顶部刷新
  bool _mHasHeader = true;
  bool get mHasHeader => _mHasHeader;
  set mHasHeader(bool val) {
    _mHasHeader = val;
    this.updateUI();
  }

  ///是否有底部刷新
  bool _mHasFooter = false;
  bool get mHasFooter => _mHasFooter;
  set mHasFooter(bool val) {
    _mHasFooter = val;
    this.updateUI();
  }

  ///刷新列表控
  void updateListVC() {
    this._getTagView().updateUI();
  }

  ///主动开始头部刷新
  void startHeaderFresh() {
    _refreshView.isManualRefreshing = true;

    _getTagView().mScrollCtr.jumpTo(_refreshView.getHeaderManualExp());
  }

  ZWRefreshView _refreshView;
  @override
  Widget realBuildWidget(BuildContext context) {
    _refreshView = ZWRefreshView(
        hasHeader: true,
        hasFooter: true,
        callback: (bheader, bstart) => onRefreshCallBack(bheader, bstart),
        list: _getTagView().getView());
    return _refreshView;
  }

  Future<Object> onRefreshCallBack(bool bheader, bstart) {
    ///主动刷新已经完成了
    _refreshView.isManualRefreshing = false;
    if (bstart) {
      if (bheader) return onHeaderStartRefresh(mListId);
      return onFooterStartRefresh(mListId);
    } else {
      updateListVC();
      return null;
    }
  }

  int onListViewGetCount(int listid) {
    return mDelegate.onListViewGetCount(listid);
  }

  Widget onListViewGetItemView(int listid, int index) {
    return mDelegate.onListViewGetItemView(listid, index);
  }

  double onListViewGetItemHeight(int listid) {
    return mDelegate.onListViewGetItemHeight(listid);
  }

  void onListViewItemClicked(int listid, int index) {
    return mDelegate.onListViewItemClicked(listid, index);
  }

  Future<Object> onHeaderStartRefresh(int listid) {
    return mDelegate.onHeaderStartRefresh(listid);
  }

  Future<Object> onFooterStartRefresh(int listid) {
    return mDelegate.onFooterStartRefresh(listid);
  }

  ZWGridInfo onGridViewGetConfig(int gridid) => null;

  Widget onGetEmptyView(int list) {
    return mDelegate.onGetEmptyView(list);
  }
}

class ZWListVC extends ViewCtr {
  ZWListVC(int listid, ZWListVCDelegate delegate, bool scrollbar)
      : this.listid = listid,
        this.delegate = delegate,
        this.scrollbar = scrollbar;

  final int listid;
  final ZWListVCDelegate delegate;
  bool scrollbar;

  ScrollController mScrollCtr = ScrollController();
  @override
  Widget realBuildWidget(Object context) {
    Widget list = ListView.builder(
        controller: mScrollCtr,
        physics: AlwaysScrollableScrollPhysics(),
        itemCount: delegate.onListViewGetCount(listid),
        itemExtent: delegate.onListViewGetItemHeight(listid),
        itemBuilder: (BuildContext context, int index) {
          return delegate.onListViewGetItemView(listid, index);
        });
    if (scrollbar) list = Scrollbar(child: list);
    return wapperEmptyView(list);
  }

  Widget wapperEmptyView(Widget c) {
    Widget e = delegate.onGetEmptyView(listid);
    var l = [c];
    if (e != null && delegate.onListViewGetCount(listid) == 0) l.add(e);
    return Stack(
      children: l,
      fit: StackFit.expand,
      alignment: Alignment.center,
    );
  }
}

class ZWGridVC extends ZWListVC {
  ZWGridVC(int listid, ZWListVCDelegate delegate, bool scrollbar)
      : super(listid, delegate, scrollbar);

  @override
  Widget realBuildWidget(Object context) {
    ZWGridInfo info = delegate.onGridViewGetConfig(this.listid);
    Widget grid = GridView.builder(
        controller: mScrollCtr,
        physics: AlwaysScrollableScrollPhysics(),
        itemCount: delegate.onListViewGetCount(listid),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: info.columnCount,
            crossAxisSpacing: info.columnSpace,
            mainAxisSpacing: info.rowSpce,
            childAspectRatio: info.aspectRatio),
        itemBuilder: (BuildContext context, int index) {
          return delegate.onListViewGetItemView(this.listid, index);
        });
    if (scrollbar) grid = Scrollbar(child: grid);
    return wapperEmptyView(grid);
  }
}
