import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:waypay_mobile/features/network_error/screens/network_error_screen.dart';

class NetworkListener extends StatefulWidget {
  final Widget child;
  const NetworkListener({super.key, required this.child});

  @override
  State<NetworkListener> createState() => _NetworkListenerState();
}

class _NetworkListenerState extends State<NetworkListener> {
  bool? isOffline;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();

    _checkInitialStatus();

    _subscription = Connectivity().onConnectivityChanged.listen((event) {
      final results = event is List
          ? event.cast<ConnectivityResult>()
          : <ConnectivityResult>[event as ConnectivityResult];

      final hasConnection = results.any((r) => r != ConnectivityResult.none);

      if (mounted) {
        setState(() {
          isOffline = !hasConnection;
        });
      }
    });
  }

  Future<void> _checkInitialStatus() async {
    final event = await Connectivity().checkConnectivity();
    final results = event is List
        ? event.cast<ConnectivityResult>()
        : <ConnectivityResult>[event as ConnectivityResult];

    final hasConnection = results.any((r) => r != ConnectivityResult.none);

    if (mounted) {
      setState(() {
        isOffline = !hasConnection;
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isOffline == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return isOffline! ? const NetworkErrorScreen() : widget.child;
  }
}
