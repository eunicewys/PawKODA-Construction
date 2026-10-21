import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import '../../services/user_notification_service.dart';
import '../../services/notification_service.dart';
import '../login_screen.dart';

/// VetHomeScreen: Dashboard for Veterinarians.
/// Uses the Warm Brown/Sand Palette (Coffee/Toffee/Oak).
class VetHomeScreen extends StatefulWidget {
  const VetHomeScreen({super.key});

  @override
  State<VetHomeScreen> createState() => _VetHomeScreenState();
}

class _VetHomeScreenState extends State<VetHomeScreen> {
  // Warm Brown/Sand Palette
  final Color _coffeeBean = const Color(0xFF7F5539);
  final Color _toffeeBrown = const Color(0xFF9C6644);
  final Color _fadedCopper = const Color(0xFFB08968);
  final Color _almondCream = const Color(0xFFEDE0D4);
  final Color _paleOak = const Color(0xFFE6CCB2);
  final Color _tan = const Color(0xFFDDB892);
  final Color _darkText = const Color(0xFF2D3142);

  final BookingService _bookingService = BookingService();

  bool _isAcceptingBookings = true;
  bool _isEmergencyService = false;

  final List<Map<String, dynamic>> _staffList = [
    {"name": "Dr. Kenique Lim (Senior Surgeon)", "isAvailable": true},
    {"name": "Dr. Amanda Tan (Feline Specialist)", "isAvailable": true},
    {"name": "Dr. Marcus Wong (General Practitioner)", "isAvailable": true},
  ];

  // Logout Logic
  Future<void> _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Provider.of<UserProvider>(context, listen: false).clearUser();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _showManageStaffModal(BuildContext context) {
    final nameCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setMState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              height: MediaQuery.of(ctx).size.height * 0.75,
              decoration: BoxDecoration(
                color: _almondCream,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Manage Doctor Staff & Slots",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _coffeeBean),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: Icon(Icons.close_rounded, color: _coffeeBean),
                      ),
                    ],
                  ),
                  Text(
                    "Enable/disable availability or add/remove doctors for slot booking.",
                    style: TextStyle(fontSize: 12, color: _fadedCopper),
                  ),
                  const SizedBox(height: 16),

                  // Add New Staff Row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: nameCtrl,
                          decoration: InputDecoration(
                            hintText: "e.g. Dr. Sarah Lee (Surgeon)",
                            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                            fillColor: Colors.white,
                            filled: true,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          style: TextStyle(fontSize: 13, color: _darkText, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          if (nameCtrl.text.trim().isNotEmpty) {
                            setState(() {
                              _staffList.add({
                                "name": nameCtrl.text.trim(),
                                "isAvailable": true,
                              });
                            });
                            setMState(() {
                              nameCtrl.clear();
                            });
                          }
                        },
                        icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                        label: const Text("Add", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _coffeeBean,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Staff List
                  Expanded(
                    child: ListView.builder(
                      itemCount: _staffList.length,
                      itemBuilder: (context, index) {
                        final staff = _staffList[index];
                        final bool isAvailable = staff["isAvailable"] ?? true;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _paleOak),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: isAvailable ? _coffeeBean.withAlpha(25) : Colors.grey.shade200,
                                child: Icon(
                                  Icons.person,
                                  size: 18,
                                  color: isAvailable ? _coffeeBean : Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      staff["name"],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: isAvailable ? _darkText : Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      isAvailable ? "Available for bookings" : "Off-Duty / Disabled",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isAvailable ? Colors.green.shade700 : Colors.redAccent,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: isAvailable,
                                activeThumbColor: _coffeeBean,
                                activeTrackColor: _tan,
                                onChanged: (val) {
                                  setState(() {
                                    _staffList[index]["isAvailable"] = val;
                                  });
                                  setMState(() {});
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _staffList.removeAt(index);
                                  });
                                  setMState(() {});
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final String clinicName = userProvider.displayName ?? "PawKODA Veterinary Clinic";

    return Scaffold(
      backgroundColor: _almondCream, // Warm background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header: Clinic Profile
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(clinicName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _coffeeBean)),
                            const SizedBox(width: 6),
                            Icon(Icons.verified, color: _toffeeBrown, size: 18),
                          ],
                        ),
                        Text("Subang Jaya, Selangor", style: TextStyle(color: _fadedCopper, fontSize: 13)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _handleLogout(context),
                        icon: Icon(Icons.logout_rounded, color: _coffeeBean),
                        tooltip: "Logout",
                      ),
                      CircleAvatar(
                        radius: 26, 
                        backgroundColor: _coffeeBean, 
                        child: const Icon(Icons.local_hospital, color: Colors.white, size: 24)
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2. Appointment Queue
              Text("Appointment Queue", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _darkText)),
              const SizedBox(height: 12),
              StreamBuilder<List<BookingModel>>(
                stream: _bookingService.streamAllBookings(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                  }
                  final bookings = snapshot.data ?? [];
                  if (bookings.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                      child: Center(
                        child: Text(
                          "No appointment requests in queue.",
                          style: TextStyle(color: _fadedCopper, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: bookings.map((b) => _appointmentCard(context, b)).toList(),
                  );
                },
              ),
              const SizedBox(height: 32),

              // 3. Schedule Panel
              Text("Operational Schedule", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _darkText)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _paleOak, width: 1.5)
                ),
                child: Column(
                  children: [
                    _scheduleToggle("Accepting Bookings", _isAcceptingBookings, (val) => setState(() => _isAcceptingBookings = val)),
                    const Divider(),
                    _scheduleToggle("Emergency Service", _isEmergencyService, (val) => setState(() => _isEmergencyService = val)),
                    const SizedBox(height: 15),
                    ElevatedButton.icon(
                      onPressed: () => _showManageStaffModal(context),
                      icon: const Icon(Icons.people_alt_rounded, color: Colors.white, size: 18),
                      label: const Text("Manage Doctors & Staff Availability", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _coffeeBean, 
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 4. Clinic Manager Shortcuts
              Text("Clinic Manager", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _darkText)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _managerShortcut(Icons.photo_library, "Clinic Photos")),
                  const SizedBox(width: 12),
                  Expanded(child: _managerShortcut(Icons.contact_phone, "Contacts")),
                ],
              ),
              const SizedBox(height: 80), 
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _appointmentCard(BuildContext context, BookingModel booking) {
    final String statusUpper = booking.status.toUpperCase();
    final Color statusColor = statusUpper == 'PENDING'
        ? _toffeeBrown
        : (statusUpper == 'CONFIRMED' ? Colors.green : Colors.red);

    final String dateStr = DateFormat('dd MMM yyyy').format(booking.bookingDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20), 
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 8)]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(booking.petName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _darkText)),
                  Text("${booking.petSpecies} • ${booking.serviceType}", style: TextStyle(color: _fadedCopper, fontSize: 12)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                child: Text(statusUpper, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 14, color: _fadedCopper),
              const SizedBox(width: 6),
              Text("$dateStr at ${booking.timeSlot}", style: TextStyle(color: _darkText, fontWeight: FontWeight.w500, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.person_outline_rounded, size: 14, color: _fadedCopper),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  "Pref Vet: ${booking.preferredVet}", 
                  style: TextStyle(color: _darkText, fontWeight: FontWeight.w500, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (statusUpper == 'PENDING') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    await BookingService().updateBookingStatus(booking.userId, booking.id, 'CANCELLED');
                    
                    await UserNotificationService().logNotification(
                      userId: booking.userId,
                      title: "Booking Declined",
                      body: "${booking.clinicName} was unable to accept your booking for ${booking.petName} on $dateStr.",
                      type: 'booking',
                    );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Declined booking for ${booking.petName}")),
                      );
                    }
                  }, 
                  child: const Text("Reject", style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    await BookingService().updateBookingStatus(booking.userId, booking.id, 'CONFIRMED');

                    // 1. Log notification for Pet Owner
                    await UserNotificationService().logNotification(
                      userId: booking.userId,
                      title: "Booking Confirmed! 🎉",
                      body: "${booking.clinicName} has confirmed your appointment for ${booking.petName} on $dateStr at ${booking.timeSlot}.",
                      type: 'booking',
                    );

                    // 2. Trigger push notification for Pet Owner
                    await NotificationService().showNotification(
                      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                      title: "Booking Confirmed! 🎉",
                      body: "${booking.clinicName} confirmed appointment for ${booking.petName} on $dateStr at ${booking.timeSlot}.",
                    );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("✓ Confirmed booking for ${booking.petName}!"),
                          backgroundColor: Colors.green.shade700,
                        ),
                      );
                    }
                  }, 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _toffeeBrown, 
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Accept", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _scheduleToggle(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: _darkText, fontWeight: FontWeight.w500)),
        Switch(
          value: value, 
          onChanged: onChanged, 
          activeThumbColor: _coffeeBean,
          activeTrackColor: _tan,
        ),
      ],
    );
  }

  Widget _managerShortcut(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _paleOak)
      ),
      child: Column(
        children: [
          Icon(icon, color: _coffeeBean, size: 28),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _darkText)),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      selectedItemColor: _coffeeBean,
      unselectedItemColor: _fadedCopper,
      backgroundColor: Colors.white,
      currentIndex: 0,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: "Dashboard"),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: "Schedule"),
        BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: "Patients"),
        BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: "Settings"),
      ],
    );
  }
}
