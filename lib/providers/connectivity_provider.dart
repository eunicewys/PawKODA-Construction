import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

/// ConnectivityProvider: Monitors internet connectivity state in real time
/// and provides utility methods for enforcing offline read-only constraints.
class ConnectivityProvider extends ChangeNotifier {
  bool _isOffline = false;
  Timer? _timer;

  bool get isOffline => _isOffline;
  bool get isOnline => !_isOffline;

  ConnectivityProvider() {
    _checkConnectivity();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkConnectivity();
    });
  }

  Future<bool> _checkConnectivity() async {
    bool offline = false;
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 2));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        offline = false;
      } else {
        offline = true;
      }
    } catch (_) {
      offline = true;
    }

    if (_isOffline != offline) {
      _isOffline = offline;
      notifyListeners();
    }
    return !_isOffline;
  }

  /// Manually triggers a quick connectivity check and returns whether connected.
  Future<bool> checkOnline() async {
    await _checkConnectivity();
    return !_isOffline;
  }

  /// Displays a Morandi-styled dialog informing the user that write operations are disabled in Offline Read-Only mode.
  static void showOfflineReadOnlyDialog(BuildContext context, {String? action}) {
    const Color darkCharcoal = Color(0xFF2D3142);
    const Color errorCoral = Color(0xFFB56576);

    final String actionText = action ?? "This operation";

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: errorCoral.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  color: errorCoral,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Offline Mode – Read Only",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: darkCharcoal,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "$actionText requires an active internet connection. Please reconnect to the internet to perform updates.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: darkCharcoal.withAlpha(200),
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: errorCoral,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    "Understood",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
