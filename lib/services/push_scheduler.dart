import 'dart:async';

/// Gathers a burst of changes into one push to the cloud.
///
/// A child answering question after question used to send their whole
/// record after every answer — five or so a minute. Thirty children in one
/// room made thousands of writes an hour: enough to use up a free Firebase
/// project's daily allowance in a morning and to fill the daycare's Wi-Fi.
/// Every change still lands on the phone at once; only the cloud copy now
/// waits for a quiet moment ([idle]), and never longer than [maxWait] while
/// the child keeps going.
class PushScheduler {
  PushScheduler(
    this._push, {
    this.idle = const Duration(seconds: 20),
    this.maxWait = const Duration(seconds: 60),
  });

  final Future<void> Function() _push;
  final Duration idle;
  final Duration maxWait;

  Timer? _idleTimer;
  Timer? _maxTimer;

  /// Whether a push is waiting to go.
  bool get pending => _idleTimer != null || _maxTimer != null;

  /// There is something new to send: send it once things settle.
  void schedule() {
    _idleTimer?.cancel();
    _idleTimer = Timer(idle, () => flush());
    _maxTimer ??= Timer(maxWait, () => flush());
  }

  /// Sends now whatever is waiting — or, with [force], even if nothing is.
  Future<void> flush({bool force = false}) async {
    final had = pending;
    _cancel();
    if (had || force) await _push();
  }

  void dispose() => _cancel();

  void _cancel() {
    _idleTimer?.cancel();
    _maxTimer?.cancel();
    _idleTimer = null;
    _maxTimer = null;
  }
}
