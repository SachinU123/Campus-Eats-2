import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

enum ConnectivityStatus { online, offline, unknown }

class ConnectivityNotifier extends Notifier<ConnectivityStatus> {
  StreamSubscription<List<ConnectivityResult>>? _sub;

  @override
  ConnectivityStatus build() {
    ref.onDispose(() => _sub?.cancel());
    _init();
    return ConnectivityStatus.unknown;
  }

  Future<void> _init() async {
    final results = await Connectivity().checkConnectivity();
    state = _fromResults(results);
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      state = _fromResults(results);
    });
  }

  ConnectivityStatus _fromResults(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.mobile) ||
        results.contains(ConnectivityResult.ethernet)) {
      return ConnectivityStatus.online;
    }
    return ConnectivityStatus.offline;
  }

  bool get isOffline => state == ConnectivityStatus.offline;
}

final connectivityProvider =
    NotifierProvider<ConnectivityNotifier, ConnectivityStatus>(() {
  return ConnectivityNotifier();
});
