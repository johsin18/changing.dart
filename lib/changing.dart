library changing;

import 'dart:collection';
import 'dart:async';

abstract class Changing {
  StreamController<bool> _onChangeController = new StreamController<bool>.broadcast(sync: true);
  Stream<bool> _onChange;
  Stream<bool> get onChange {
    if (_onChange == null) // singleton approach, because constructor is forbidden for mixin
      _onChange = _onChangeController.stream;
    return _onChange;
  }

  bool reportChanges = true;

  notifyChange(bool quick) {
    if (reportChanges)
      _onChangeController.add(quick);
  }

  notifyTentativeChange() {
    notifyChange(true);
  }

  notifyPermanentChange() {
    notifyChange(false);
  }
}

class ChangingList<T extends Changing> extends ListBase<T> with Changing {
  List<T> list; // substrate for ListBase
  Map<T, StreamSubscription> changeSubscriptions;

  ChangingList() {
    list = new List<T>();
    changeSubscriptions = new Map<T, StreamSubscription>();
  }

  void add(T t) {
    _add(t);
    notifyPermanentChange();
  }

  void addTentative(T t) {
    _add(t);
    notifyTentativeChange();
  }

  void _add(T t) {
    super.add(t);
    changeSubscriptions[t] = t.onChange.listen((bool quick) { notifyChange(quick); });
  }

  bool remove(T t) {
    bool success = _remove(t);
    notifyPermanentChange();
    return success;
  }

  bool removeTentative(T t) {
    bool success = _remove(t);
    notifyTentativeChange();
    return success;
  }

  bool _remove(T t) {
    StreamSubscription s = changeSubscriptions.remove(t);
    if (s != null)
      s.cancel();
    bool success = super.remove(t);
    return success;
  }

  void clear() {
    changeSubscriptions.forEach((T t, StreamSubscription s) { s.cancel(); });
    super.clear();
  }

  T operator[](int i) => list[i];
  void operator[]=(int i, value) { list[i] = value; }
  int get length => list.length;
  set length(int l) { list.length = l; }
}
