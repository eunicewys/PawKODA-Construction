import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/user_notification_model.dart';
import '../../providers/user_provider.dart';
import '../../services/user_notification_service.dart';
import '../widgets/fringe_header.dart';

/// NotificationCenterScreen: Manages notification preferences (turn ON/OFF)
/// and displays past notification logs stored for up to 30 days.
/// Provides filters: "Past 7 days", "Past 14 days", "Past 21 days", and "Past 30 days".
class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final UserNotificationService _notificationService = UserNotificationService();

  // Morandi Palette
  final Color _dustyOlive = const Color(0xFF6B705C);
  final Color _lightBronze = const Color(0xFFCB997E);
  final Color _powderPetal = const Color(0xFFFFE8D6);
  final Color _darkCharcoal = const Color(0xFF2D3142);
  final Color _ashGrey = const Color(0xFF8A8A7C);

  bool _notificationsEnabled = true;
  bool _isLoadingPreference = true;
  int _selectedDaysFilter = 30; // Options: 7, 14, 21, 30

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    final uid = Provider.of<UserProvider>(context, listen: false).uid ?? '';
    if (uid.isNotEmpty) {
      final enabled = await _notificationService.getNotificationSettings(uid);
      await _notificationService.cleanupOldNotifications(uid);
      if (mounted) {
        setState(() {
          _notificationsEnabled = enabled;
          _isLoadingPreference = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoadingPreference = false);
    }
  }

  Future<void> _toggleNotificationPreference(bool value) async {
    final uid = Provider.of<UserProvider>(context, listen: false).uid ?? '';
    setState(() => _notificationsEnabled = value);
    if (uid.isNotEmpty) {
      await _notificationService.setNotificationSettings(uid, value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? "Notifications enabled! You will receive health & booking alerts."
                  : "Notifications disabled.",
            ),
            backgroundColor: _dustyOlive,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<UserProvider>().uid ?? '';

    const Color beachBg = Color(0xFFE6CCB2);

    return Scaffold(
      backgroundColor: beachBg,
      body: Column(
        children: [
          FringeHeader(
            title: "Notifications",
            subtitle: "Settings & History (30 Days)",
            onBack: () => Navigator.pop(context),
            trailing: uid.isNotEmpty
                ? PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                    onSelected: (value) async {
                      if (value == 'mark_read') {
                        await _notificationService.markAllAsRead(uid);
                      } else if (value == 'clear_all') {
                        _showClearConfirmationDialog(uid);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'mark_read',
                        child: Row(
                          children: [
                            const Icon(Icons.done_all, color: Colors.blue, size: 20),
                            const SizedBox(width: 8),
                            const Text("Mark all as read"),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'clear_all',
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            const Text("Clear all notifications"),
                          ],
                        ),
                      ),
                    ],
                  )
                : null,
          ),
          Expanded(
            child: Column(
              children: [
                // Compact Push Notifications Switch Card
                Container(
                  margin: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _powderPetal,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _notificationsEnabled
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_off_rounded,
                          color: _dustyOlive,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Push Notifications",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _darkCharcoal,
                              ),
                            ),
                            Text(
                              _notificationsEnabled
                                  ? "Health, vaccine & booking alerts ON"
                                  : "Notifications are turned OFF",
                              style: TextStyle(fontSize: 11, color: _ashGrey),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      _isLoadingPreference
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Transform.scale(
                              scale: 0.85,
                              child: Switch(
                                value: _notificationsEnabled,
                                activeThumbColor: _dustyOlive,
                                onChanged: _toggleNotificationPreference,
                              ),
                            ),
                    ],
                  ),
                ),

                // Compact Retention Note & Filter Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.history_rounded, size: 14, color: _dustyOlive),
                          const SizedBox(width: 4),
                          Text(
                            "HISTORY:",
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _darkCharcoal, letterSpacing: 0.3),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 12, color: _lightBronze),
                          const SizedBox(width: 3),
                          Text(
                            "30-day auto-purge",
                            style: TextStyle(fontSize: 10, color: _darkCharcoal.withAlpha(180), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                // Filter Chips Bar ("7 Days", "14 Days", "21 Days", "30 Days")
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      _buildFilterChip("7 Days", 7),
                      const SizedBox(width: 6),
                      _buildFilterChip("14 Days", 14),
                      const SizedBox(width: 6),
                      _buildFilterChip("21 Days", 21),
                      const SizedBox(width: 6),
                      _buildFilterChip("30 Days", 30),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Notifications List
                Expanded(
                  child: StreamBuilder<List<UserNotificationModel>>(
                    stream: _notificationService.streamNotifications(uid, pastDays: _selectedDaysFilter),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final notifications = snapshot.data ?? [];

                      if (notifications.isEmpty) {
                        return _buildEmptyState();
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        itemCount: notifications.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = notifications[index];
                          return _buildNotificationCard(item);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    ],
  ),
);
}

  Widget _buildFilterChip(String label, int days) {
    final bool isSelected = _selectedDaysFilter == days;
    return ChoiceChip(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      visualDensity: VisualDensity.compact,
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : _darkCharcoal,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          fontSize: 11,
        ),
      ),
      selected: isSelected,
      selectedColor: _dustyOlive,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? _dustyOlive : _ashGrey.withAlpha(80),
        ),
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedDaysFilter = days;
          });
        }
      },
    );
  }

  Widget _buildNotificationCard(UserNotificationModel item) {
    IconData iconData;
    Color iconBg;
    Color iconColor;

    switch (item.type.toLowerCase()) {
      case 'vaccine':
      case 'deworming':
        iconData = Icons.vaccines_rounded;
        iconBg = const Color(0xFFE8F5E9);
        iconColor = const Color(0xFF2E7D32);
        break;
      case 'booking':
        iconData = Icons.event_available_rounded;
        iconBg = const Color(0xFFE3F2FD);
        iconColor = const Color(0xFF1565C0);
        break;
      case 'health':
        iconData = Icons.health_and_safety_rounded;
        iconBg = const Color(0xFFFFF3E0);
        iconColor = const Color(0xFFE65100);
        break;
      default:
        iconData = Icons.notifications_rounded;
        iconBg = _powderPetal;
        iconColor = _dustyOlive;
        break;
    }

    final String dateFormatted = DateFormat('dd MMM yyyy • hh:mm a').format(item.timestamp);

    return Container(
      decoration: BoxDecoration(
        color: item.isRead ? Colors.white : const Color(0xFFFFFDF5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.isRead ? Colors.grey.withAlpha(30) : _lightBronze.withAlpha(120),
          width: item.isRead ? 1 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                            fontSize: 13,
                            color: _darkCharcoal,
                          ),
                        ),
                      ),
                      if (!item.isRead)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _lightBronze,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.body,
                    style: TextStyle(
                      fontSize: 12,
                      color: _darkCharcoal.withAlpha(220),
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateFormatted,
                    style: TextStyle(fontSize: 10, color: _ashGrey, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _powderPetal.withAlpha(150),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.notifications_none_rounded, size: 60, color: _dustyOlive),
            ),
            const SizedBox(height: 16),
            Text(
              "No Notifications",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _darkCharcoal),
            ),
            const SizedBox(height: 6),
            Text(
              "No notifications found in the past $_selectedDaysFilter days.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _ashGrey),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearConfirmationDialog(String uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Clear Notification History?", style: TextStyle(color: _darkCharcoal, fontWeight: FontWeight.bold)),
        content: const Text("This will delete all stored notifications from your history."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await _notificationService.clearAllNotifications(uid);
            },
            child: const Text("Clear All", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
