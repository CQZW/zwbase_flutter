import 'dart:io';

///写着玩的,别认真...
///实现一个简单的锁,简单来说就是一直死循环等到要的东西为止
///这样可以把异步方法变成同步,但是不能在主线程里面使用,因为会宕住当前线程..
///Future<int> func() async
///{
///XX: await DISKOP 这里有必须要做的异步操作,比如磁盘请求
///XXX
///}
///
///int func()
///{
///ZWSpinLock t = ZWSpinLock();
/// DISKOP().then( v => t.unlock(v); )
///return t.wait(v);
///}
///
class ZWSpinLock {
  ///循环检查的间隔时间
  final int spin_grap_ms;
  ZWSpinLock({this.spin_grap_ms = 50});

  int _state = 0;
  void lock() {
    _state++;
  }

  Object _v;
  void unlock(Object v) {
    _v = v;
    _state--;
  }

  ///等待锁被释放.timeout_ms=0表示一直等待,否则就是等待的时间,超时了返回null
  ///所以自己要注意区分,如果返回Null值
  Object wait({int timeout_ms = 0}) {
    lock();

    ///只是应该<=1,否则已经被其他人锁一次了,
    assert(_state <= 1, "just use it for your self,lock is locked");
    int c = 0;
    while (_state > 0) {
      sleep(Duration(milliseconds: this.spin_grap_ms));
      if (timeout_ms > 0) {
        c++;

        ///如果超时了
        if ((c * this.spin_grap_ms) > timeout_ms) break;
      }
    }
    return _v;
  }
}
