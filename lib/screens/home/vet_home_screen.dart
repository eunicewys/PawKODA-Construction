import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import '../../services/user_notification_service.dart';
import '../../services/notification_service.dart';
import '../profile/edit_profile_screen.dart';
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
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: _coffeeBean.withAlpha(80),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
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

  /// Scroll-type Time Picker (with AM/PM scrolling)
  Future<String?> _showScrollTimePicker(BuildContext context, String initialTimeStr) async {
    int initialHour = 9;
    int initialMinute = 0;
    int initialPeriodIndex = 0; // 0 for AM, 1 for PM

    try {
      if (initialTimeStr.isNotEmpty) {
        final parts = initialTimeStr.trim().split(' ');
        if (parts.length >= 2) {
          final timeParts = parts[0].split(':');
          initialHour = int.parse(timeParts[0]);
          initialMinute = int.parse(timeParts[1]);
          initialPeriodIndex = parts[1].toUpperCase() == 'PM' ? 1 : 0;
        }
      }
    } catch (_) {}

    int selectedHour = initialHour;
    int selectedMinute = initialMinute;
    int selectedPeriod = initialPeriodIndex;

    final hoursList = List.generate(12, (index) => index + 1); // 1 to 12
    final minutesList = List.generate(12, (index) => index * 5); // 00, 05, 10... 55
    final periodsList = ['AM', 'PM'];

    int initialHourIdx = hoursList.indexOf(selectedHour);
    if (initialHourIdx < 0) initialHourIdx = 8; // Default 9
    int initialMinIdx = minutesList.indexOf(selectedMinute);
    if (initialMinIdx < 0) initialMinIdx = 0;

    return await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                  ),
                  const Text("Scroll Time Picker", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  TextButton(
                    onPressed: () {
                      final hStr = selectedHour.toString().padLeft(2, '0');
                      final mStr = selectedMinute.toString().padLeft(2, '0');
                      final pStr = periodsList[selectedPeriod];
                      Navigator.pop(ctx, "$hStr:$mStr $pStr");
                    },
                    child: Text("Done", style: TextStyle(fontWeight: FontWeight.bold, color: _coffeeBean)),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: Row(
                  children: [
                    // Hour Scroll Wheel
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(initialItem: initialHourIdx),
                        itemExtent: 40,
                        onSelectedItemChanged: (idx) => selectedHour = hoursList[idx],
                        children: hoursList.map((h) => Center(child: Text(h.toString().padLeft(2, '0'), style: TextStyle(fontSize: 18, color: _darkText, fontWeight: FontWeight.bold)))).toList(),
                      ),
                    ),
                    Text(":", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _darkText)),
                    // Minute Scroll Wheel
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(initialItem: initialMinIdx),
                        itemExtent: 40,
                        onSelectedItemChanged: (idx) => selectedMinute = minutesList[idx],
                        children: minutesList.map((m) => Center(child: Text(m.toString().padLeft(2, '0'), style: TextStyle(fontSize: 18, color: _darkText, fontWeight: FontWeight.bold)))).toList(),
                      ),
                    ),
                    // AM/PM Scroll Wheel
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(initialItem: initialPeriodIndex),
                        itemExtent: 40,
                        onSelectedItemChanged: (idx) => selectedPeriod = idx,
                        children: periodsList.map((p) => Center(child: Text(p, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _coffeeBean)))).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Operating Hours Modal with Weekly Saturday Update Restriction & Multiple Session Slots
  void _showManageOperatingHoursModal(
    BuildContext context, {
    required String currentHoursStr,
    DateTime? lastUpdatedAt,
  }) {
    final bool isSaturday = DateTime.now().weekday == DateTime.saturday;
    final bool isFirstTime = lastUpdatedAt == null;
    final bool canEdit = isSaturday || isFirstTime;

    // Parse existing slots or set default morning & afternoon sessions
    List<Map<String, String>> slots = [];
    if (currentHoursStr.isNotEmpty) {
      final parts = currentHoursStr.split(',');
      for (var p in parts) {
        final times = p.trim().split('-');
        if (times.length == 2) {
          slots.add({'start': times[0].trim(), 'end': times[1].trim()});
        }
      }
    }
    if (slots.isEmpty) {
      slots = [
        {'start': '09:00 AM', 'end': '01:00 PM'},
        {'start': '02:30 PM', 'end': '06:00 PM'},
      ];
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setMState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              height: MediaQuery.of(ctx).size.height * 0.78,
              decoration: BoxDecoration(
                color: _almondCream,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: _coffeeBean.withAlpha(80),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Weekly Operating Hours",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _coffeeBean),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: Icon(Icons.close_rounded, color: _coffeeBean),
                      ),
                    ],
                  ),

                  // Weekly Rule Banner
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: canEdit ? Colors.amber.shade50 : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: canEdit ? Colors.amber.shade300 : Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          canEdit ? Icons.edit_calendar_rounded : Icons.lock_clock_rounded,
                          color: canEdit ? Colors.amber.shade800 : Colors.blue.shade800,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isFirstTime
                                ? "Initial Setup: Set your clinic's operating hours & break sessions."
                                : (isSaturday
                                    ? "Saturday Update Window Open! Configure operating hours for Sunday through next Saturday."
                                    : "Operating hours can only be updated every Saturday for the coming week. System is using active hours."),
                            style: TextStyle(
                              fontSize: 12,
                              color: canEdit ? Colors.amber.shade900 : Colors.blue.shade900,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Text(
                    "Daily Operational Sessions & Breaks",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _darkText),
                  ),
                  const SizedBox(height: 8),

                  Expanded(
                    child: ListView.builder(
                      itemCount: slots.length,
                      itemBuilder: (context, index) {
                        final slot = slots[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _paleOak),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: _coffeeBean.withAlpha(25),
                                child: Text("${index + 1}", style: TextStyle(color: _coffeeBean, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Row(
                                  children: [
                                    // Start Time Scroll Picker
                                    Expanded(
                                      child: InkWell(
                                        onTap: canEdit
                                            ? () async {
                                                final picked = await _showScrollTimePicker(context, slot['start']!);
                                                if (picked != null) {
                                                  setMState(() => slot['start'] = picked);
                                                }
                                              }
                                            : null,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: _almondCream.withAlpha(80),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: _paleOak),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.access_time_rounded, size: 14, color: _coffeeBean),
                                              const SizedBox(width: 4),
                                              Flexible(
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Text(slot['start']!, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _darkText)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 6),
                                      child: Text("to", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                                    ),
                                    // End Time Scroll Picker
                                    Expanded(
                                      child: InkWell(
                                        onTap: canEdit
                                            ? () async {
                                                final picked = await _showScrollTimePicker(context, slot['end']!);
                                                if (picked != null) {
                                                  setMState(() => slot['end'] = picked);
                                                }
                                              }
                                            : null,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: _almondCream.withAlpha(80),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: _paleOak),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.access_time_rounded, size: 14, color: _coffeeBean),
                                              const SizedBox(width: 4),
                                              Flexible(
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Text(slot['end']!, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _darkText)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (canEdit && slots.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                  onPressed: () {
                                    setMState(() => slots.removeAt(index));
                                  },
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  if (canEdit) ...[
                    OutlinedButton.icon(
                      onPressed: () {
                        setMState(() {
                          slots.add({'start': '02:30 PM', 'end': '06:00 PM'});
                        });
                      },
                      icon: const Icon(Icons.more_time_rounded, size: 18),
                      label: const Text("Add Break / Additional Session"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _coffeeBean,
                        side: BorderSide(color: _coffeeBean),
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () async {
                        final formatted = slots.map((s) => "${s['start']} - ${s['end']}").join(', ');
                        final uid = FirebaseAuth.instance.currentUser?.uid;
                        if (uid != null) {
                          await FirebaseFirestore.instance.collection('USERS').doc(uid).update({
                            'operatingHours': formatted,
                            'lastHoursUpdatedAt': FieldValue.serverTimestamp(),
                          });
                          await FirebaseFirestore.instance.collection('CLINICS').doc(uid).set({
                            'operatingHours': formatted,
                            'lastHoursUpdatedAt': FieldValue.serverTimestamp(),
                          }, SetOptions(merge: true));
                        }
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("✓ Operating hours updated successfully!"), backgroundColor: Colors.green),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _coffeeBean,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text("Save Operating Hours", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showManageServicesModal(BuildContext context, {required List<String> currentServices}) {
    final List<String> availableServices = [
      'General Consultation',
      'Vaccination',
      'Soft Tissue Surgery',
      'Dental Care',
      'Blood Diagnostics',
      'Feline Care',
      'Deworming',
      'Grooming Services',
      'Microchipping',
      'Emergency Care',
    ];

    final List<String> selectedServices = List<String>.from(currentServices);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.medical_services_rounded, color: _coffeeBean, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Manage Offered Medical Services",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _coffeeBean),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Select medical services offered at your clinic. Updates sync in real time to the Admin Registry and Pet Owner Booking Screen.",
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableServices.map((svc) {
                      final isSelected = selectedServices.contains(svc);
                      return FilterChip(
                        label: Text(svc, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : _coffeeBean, fontWeight: FontWeight.bold)),
                        selected: isSelected,
                        selectedColor: _coffeeBean,
                        backgroundColor: _paleOak,
                        onSelected: (val) {
                          setSheetState(() {
                            if (val) {
                              selectedServices.add(svc);
                            } else {
                              selectedServices.remove(svc);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () async {
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid != null) {
                        await FirebaseFirestore.instance.collection('USERS').doc(uid).update({
                          'services': selectedServices,
                          'lastServicesUpdatedAt': FieldValue.serverTimestamp(),
                        });
                        await FirebaseFirestore.instance.collection('CLINICS').doc(uid).set({
                          'services': selectedServices,
                          'lastServicesUpdatedAt': FieldValue.serverTimestamp(),
                        }, SetOptions(merge: true));
                      }
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("✓ Offered services updated in real time!"), backgroundColor: Colors.green),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _coffeeBean,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text("Save Offered Services", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ],
              ),
            );
          },
        );
      },
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
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                          );
                        },
                        child: CircleAvatar(
                          radius: 26, 
                          backgroundColor: _coffeeBean, 
                          child: const Icon(Icons.local_hospital, color: Colors.white, size: 24)
                        ),
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
                stream: _bookingService.streamVetClinicBookings(
                  userProvider.uid ?? FirebaseAuth.instance.currentUser?.uid ?? '',
                  clinicName,
                  vetEmail: userProvider.email ?? FirebaseAuth.instance.currentUser?.email ?? '',
                ),
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
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseAuth.instance.currentUser?.uid != null
                    ? FirebaseFirestore.instance.collection('USERS').doc(FirebaseAuth.instance.currentUser!.uid).snapshots()
                    : null,
                builder: (context, userSnap) {
                  Map<String, dynamic>? userData;
                  if (userSnap.hasData && userSnap.data!.exists) {
                    userData = userSnap.data!.data() as Map<String, dynamic>?;
                  }
                  final String currentHours = userData?['operatingHours'] ?? "09:00 AM - 06:00 PM";
                  final Timestamp? lastUpdatedTs = userData?['lastHoursUpdatedAt'] as Timestamp?;
                  final DateTime? lastUpdatedAt = lastUpdatedTs?.toDate();

                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _paleOak, width: 1.5)
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _scheduleToggle("Accepting Bookings", _isAcceptingBookings, (val) => setState(() => _isAcceptingBookings = val)),
                        const Divider(),
                        _scheduleToggle("Emergency Service", _isEmergencyService, (val) => setState(() => _isEmergencyService = val)),
                        const Divider(),
                        
                        // Operating Hours Active Display
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.access_time_filled_rounded, color: _coffeeBean, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Operating Hours: $currentHours",
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _darkText),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Manage Operating Hours & Breaks Button
                        OutlinedButton.icon(
                          onPressed: () => _showManageOperatingHoursModal(
                            context,
                            currentHoursStr: currentHours,
                            lastUpdatedAt: lastUpdatedAt,
                          ),
                          icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                          label: const Text("Manage Operating Hours & Breaks", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _coffeeBean,
                            side: BorderSide(color: _coffeeBean),
                            minimumSize: const Size(double.infinity, 46),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Manage Offered Medical Services Button
                        OutlinedButton.icon(
                          onPressed: () => _showManageServicesModal(
                            context,
                            currentServices: List<String>.from(userData?['services'] ?? ['General Consultation', 'Vaccination', 'Deworming']),
                          ),
                          icon: const Icon(Icons.medical_services_outlined, size: 18),
                          label: const Text("Manage Offered Medical Services", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _coffeeBean,
                            side: BorderSide(color: _coffeeBean),
                            minimumSize: const Size(double.infinity, 46),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                        const SizedBox(height: 10),

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
                  );
                },
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
