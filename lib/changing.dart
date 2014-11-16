library changing;

import 'dart:collection';
import 'dart:async';

/** Base class for a changing object. */
abstract class Changing {
  StreamController<bool> _onChangeController = new StreamController<bool>.broadcast(sync: true);
  Stream<bool> _onChange;

  /** Get stream of booleans that informs about changes to this object. True means tentative, false means permanent. */ 
  Stream<bool> get onChange {
    if (_onChange == null) // singleton approach, because constructor is forbidden for mixin
      _onChange = _onChangeController.stream;
    return _onChange;
  }

  /** Whether to report changes currently. */
  bool reportChanges = true;

  /** Notify a change to the observers, potentially a tentative one. */
  notifyChange(bool tentative) {
    if (reportChanges)
      _onChangeController.add(tentative);
  }

  /** Notify a tentative change to the observers. */
  notifyTentativeChange() {
    notifyChange(true);
  }

  /** Notify a permanent change to the observers. */
  notifyPermanentChange() {
    notifyChange(false);
  }
}

/** A list of changing objects.
 *  Any change to any of the list object will trigger a change notification on this list. 
 *  Also, adding or removing an object is considered a change. */
class ChangingList<T extends Changing> extends ListBase<T> with Changing {
  List<T> _list; // substrate for ListBase
  Map<T, StreamSubscription> _changeSubscriptions;

  ChangingList() {
    _list = new List<T>();
    _changeSubscriptions = new Map<T, StreamSubscription>();
  }

  /** Add an element, considering this a permanent change. */
  void add(T t) {
    _add(t);
    notifyPermanentChange();
  }

  /** Add an element, considering this a tentative change. */
  void addTentative(T t) {
    _add(t);
    notifyTentativeChange();
  }

  void _add(T t) {
    super.add(t);
    _changeSubscriptions[t] = t.onChange.listen((bool quick) { notifyChange(quick); });
  }

  /** Remove an element, considering this a permanent change. */
  bool remove(T t) {
    bool success = _remove(t);
    notifyPermanentChange();
    return success;
  }

  /** Remove an element, considering this a tentative change. */
  bool removeTentative(T t) {
    bool success = _remove(t);
    notifyTentativeChange();
    return success;
  }

  bool _remove(T t) {
    StreamSubscription s = _changeSubscriptions.remove(t);
    if (s != null)
      s.cancel();
    bool success = super.remove(t);
    return success;
  }

  void clear() {
    for (StreamSubscription s in _changeSubscriptions.values)
      s.cancel();
    _changeSubscriptions.clear();
    super.clear();
  }

  // ListBase implements all List methods based on these four
  T operator[](int i) => _list[i];
  void operator[]=(int i, value) { _list[i] = value; }
  int get length => _list.length;
  set length(int l) { _list.length = l; }
}
