import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/connectivity_provider.dart';

/// OfflineBanner: Displays a clear "Offline Mode – Read Only" indicator
/// informing users when the app is offline and viewing cached passport data.
class OfflineBanner extends StatelessWidget {
  final EdgeInsetsGeometry? margin;
  const OfflineBanner({super.key, this.margin});

  @override
  Widget build(BuildContext context) {
    final isOffline = context.watch<ConnectivityProvider>().isOffline;
    if (!isOffline) return const SizedBox.shrink();

    const Color warningBackground = Color(0xFFFFF3E0); // Warm cream-amber
    const Color warningBorder = Color(0xFFFFB74D);
    const Color darkCharcoal = Color(0xFF2D3142);
    const Color iconColor = Color(0xFFE65100);

    return Container(
      width: double.infinity,
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: warningBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: warningBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Offline Mode – Read Only",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: darkCharcoal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Viewing cached pet passport data. Connect to the internet to sync updates.",
                  style: TextStyle(
                    fontSize: 11,
                    color: darkCharcoal.withAlpha(190),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
