import 'dart:convert';
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
import '../profile/vet_privacy_security_screen.dart';
import '../widgets/fringe_header.dart';
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

  bool _hasCheckedClinicStatus = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVetClinicRegistrationStatus();
    });
  }

  Future<void> _showWarningDialog(BuildContext context, {required String title, required String message}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        elevation: 10,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _darkText,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _coffeeBean,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSuccessDialog(BuildContext context, {required String title, required String message}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        elevation: 10,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle_rounded, color: Colors.green.shade800, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _darkText,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade800,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkVetClinicRegistrationStatus() async {
    if (_hasCheckedClinicStatus) return;
    _hasCheckedClinicStatus = true;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final String uid = user.uid;
    final String email = user.email?.toLowerCase().trim() ?? '';

    try {
      // 1. Check if document exists in CLINICS collection by doc ID (uid)
      final clinicDocByUid = await FirebaseFirestore.instance.collection('CLINICS').doc(uid).get();
      bool existsInClinics = clinicDocByUid.exists;

      if (!existsInClinics && email.isNotEmpty) {
        // Query CLINICS collection by email
        final queryByEmail = await FirebaseFirestore.instance
            .collection('CLINICS')
            .where('email', isEqualTo: email)
            .get();
        if (queryByEmail.docs.isNotEmpty) {
          existsInClinics = true;
        }
      }

      // 2. Also check USERS doc status
      final userDoc = await FirebaseFirestore.instance.collection('USERS').doc(uid).get();
      final userData = userDoc.data();
      final status = (userData?['status'] ?? '').toString().toLowerCase();

      if (!existsInClinics || status == 'removed') {
        if (mounted) {
          _showVetProfileRemovedDialog();
        }
      }
    } catch (e) {
      debugPrint("Error checking clinic registration status: $e");
    }
  }

  void _showVetProfileRemovedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                "Vet Profile Removed",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Your Vet profile has been removed from Booking System. Contact PawKODA support line if this was a mistake.",
              style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF2D3142)),
            ),
            SizedBox(height: 16),
            Divider(height: 1),
            SizedBox(height: 12),
            Text(
              "PAWKODA SUPPORT LINE",
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.8),
            ),
            SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.email_outlined, size: 15, color: Color(0xFF7F5539)),
                SizedBox(width: 6),
                SelectableText(
                  "support@pawkoda.com",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF7F5539)),
                ),
              ],
            ),
            SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.phone_outlined, size: 15, color: Color(0xFF7F5539)),
                SizedBox(width: 6),
                SelectableText(
                  "+60 11-56939880",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF7F5539)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7F5539),
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Provider.of<UserProvider>(context, listen: false).clearUser();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text("Okay", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  final List<Map<String, dynamic>> _staffList = [];

  // Logout Logic with Confirmation Dialog Box
  Future<void> _handleLogout(BuildContext context) async {
    final bool? confirmLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.logout_rounded, color: Colors.red.shade700, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                "Logout from Vet Portal?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _darkText,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Are you sure you want to sign out from PawKODA Veterinary Portal?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: _fadedCopper,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(dialogCtx, false),
                      child: const Text("CANCEL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(dialogCtx, true),
                      child: const Text("LOGOUT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmLogout != true) return;

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

  void _showManageStaffModal(BuildContext context) async {
    final nameCtrl = TextEditingController();

    // Fetch existing doctors list & operating time slots from Firestore for this clinic
    final uid = FirebaseAuth.instance.currentUser?.uid;
    List<String> clinicOperatingTimeSlots = [];

    if (uid != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('USERS').doc(uid).get();
        if (doc.exists) {
          final data = doc.data();
          clinicOperatingTimeSlots = List<String>.from(data?['operatingTimeSlots'] ?? []);
          clinicOperatingTimeSlots.sort((a, b) => _parseTimeToMinutes(a).compareTo(_parseTimeToMinutes(b)));

          final List<dynamic> savedDetails = data?['doctorDetails'] ?? data?['veterinarians'] ?? [];
          _staffList.clear();
          for (var v in savedDetails) {
            if (v is Map) {
              final List<String> slots = List<String>.from(v["timeSlots"] ?? []);
              slots.sort((a, b) => _parseTimeToMinutes(a).compareTo(_parseTimeToMinutes(b)));
              _staffList.add({
                "name": _toTitleCase(v["name"].toString()),
                "isAvailable": v["isAvailable"] ?? false,
                "timeSlots": slots,
              });
            } else if (v is String) {
              _staffList.add({
                "name": _toTitleCase(v.toString()),
                "isAvailable": true,
                "timeSlots": List<String>.from(clinicOperatingTimeSlots),
              });
            }
          }
        }
      } catch (_) {}
    }

    final String initialStaffJson = jsonEncode(_staffList);

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setMState) {
          Future<bool> checkUnsavedAndConfirmExit() async {
            final String currentStaffJson = jsonEncode(_staffList);
            if (currentStaffJson != initialStaffJson) {
              final bool? shouldDiscard = await showDialog<bool>(
                context: ctx,
                barrierDismissible: false,
                builder: (dialogCtx) => Dialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  backgroundColor: Colors.white,
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 30),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Unsaved Changes",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _darkText,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "You have unsaved changes in your vet list and time slots. Are you sure you want to exit without saving?",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: _fadedCopper,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.grey.shade700,
                                  side: BorderSide(color: Colors.grey.shade300),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onPressed: () => Navigator.pop(dialogCtx, false),
                                child: const Center(
                                  child: Text("CANCEL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade700,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onPressed: () => Navigator.pop(dialogCtx, true),
                                child: const Center(
                                  child: Text("DISCARD", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );

              return shouldDiscard == true;
            }
            return true;
          }

          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;
              final bool canExit = await checkUnsavedAndConfirmExit();
              if (canExit && ctx.mounted) {
                Navigator.pop(ctx);
              }
            },
            child: Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                height: MediaQuery.of(ctx).size.height * 0.82,
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
                        Expanded(
                          child: Text(
                            "Manage Doctor Staff",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _coffeeBean),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            final bool canExit = await checkUnsavedAndConfirmExit();
                            if (canExit && ctx.mounted) {
                              Navigator.pop(ctx);
                            }
                          },
                          icon: Icon(Icons.close_rounded, color: _coffeeBean),
                        ),
                      ],
                    ),
                    Text(
                      "Configure working time slots for each doctor.",
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
                            final String formattedName = _toTitleCase(nameCtrl.text);
                            if (formattedName.isNotEmpty) {
                              setState(() {
                                _staffList.add({
                                  "name": formattedName,
                                  "isAvailable": false,
                                  "timeSlots": <String>[],
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
                      child: _staffList.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Text(
                                  "No doctors/staff added yet. Add your clinic's doctors above.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: _fadedCopper, fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _staffList.length,
                              itemBuilder: (context, index) {
                                final staff = _staffList[index];
                                final bool isAvailable = staff["isAvailable"] == true;
                                final List<String> staffSlots = List<String>.from(staff["timeSlots"] ?? []);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: _paleOak),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
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
                                                    fontSize: 14,
                                                    color: isAvailable ? _darkText : Colors.grey.shade700,
                                                  ),
                                                ),
                                                Text(
                                                  isAvailable ? "Available for bookings" : "Off-Duty / Disabled",
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: isAvailable ? Colors.green.shade700 : Colors.redAccent,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Switch(
                                            value: isAvailable,
                                            activeThumbColor: _coffeeBean,
                                            activeTrackColor: _tan,
                                            onChanged: (val) async {
                                              if (val == true && staffSlots.isEmpty) {
                                                await _showWarningDialog(
                                                  context,
                                                  title: "No Time Slot Selected",
                                                  message: "Please select at least one working time slot for ${staff['name']} before enabling availability for bookings.",
                                                );
                                                return;
                                              }
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
                                      const Divider(height: 16),
                                      Text(
                                        "Working Time Slots (Preset in Operating Schedule):",
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _fadedCopper),
                                      ),
                                      const SizedBox(height: 8),
                                      if (clinicOperatingTimeSlots.isEmpty) ...[
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                          child: Text(
                                            "No time slots configured in Operating Schedule (Section 3) yet.",
                                            style: TextStyle(fontSize: 11, color: Colors.redAccent, fontStyle: FontStyle.italic),
                                          ),
                                        ),
                                      ] else ...[
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: clinicOperatingTimeSlots.map((slot) {
                                            final bool isSelected = staffSlots.contains(slot);
                                            return InkWell(
                                              onTap: () {
                                                setMState(() {
                                                  if (isSelected) {
                                                    staffSlots.remove(slot);
                                                    if (staffSlots.isEmpty) {
                                                      _staffList[index]["isAvailable"] = false;
                                                    }
                                                  } else {
                                                    staffSlots.add(slot);
                                                  }
                                                  staffSlots.sort((a, b) => _parseTimeToMinutes(a).compareTo(_parseTimeToMinutes(b)));
                                                  _staffList[index]["timeSlots"] = staffSlots;
                                                });
                                                setState(() {});
                                              },
                                              borderRadius: BorderRadius.circular(8),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: isSelected ? _coffeeBean : Colors.grey.shade100,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: isSelected ? _coffeeBean : Colors.grey.shade300,
                                                  ),
                                                ),
                                                child: Text(
                                                  slot,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: isSelected ? Colors.white : _darkText,
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),

                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () async {
                        final String currentStaffJson = jsonEncode(_staffList);
                        final bool hasChanges = currentStaffJson != initialStaffJson;

                        if (hasChanges) {
                          final allVets = _staffList.map((s) => s["name"].toString()).toList();

                          if (uid != null) {
                            await FirebaseFirestore.instance.collection('USERS').doc(uid).update({
                              'doctorDetails': _staffList,
                              'veterinarians': allVets,
                            });
                            await FirebaseFirestore.instance.collection('CLINICS').doc(uid).set({
                              'doctorDetails': _staffList,
                              'veterinarians': allVets,
                            }, SetOptions(merge: true));
                          }

                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("✓ Vet list saved successfully!"), backgroundColor: Colors.green),
                            );
                          }
                        } else {
                          if (context.mounted) {
                            Navigator.pop(ctx);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _coffeeBean,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text("Save Vet List", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ],
                ),
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

  /// Computes operating dates for the active week and coming week
  List<DateTime> _getCurrentWeekOperatingDates() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final int daysFromMonday = today.weekday - 1;
    final DateTime currentMonday = today.subtract(Duration(days: daysFromMonday));

    if (today.weekday >= DateTime.saturday) {
      // Saturday or Sunday: Include current Sat & Sun AND upcoming week's Mon-Sun
      final currentSat = currentMonday.add(const Duration(days: 5));
      final currentSun = currentMonday.add(const Duration(days: 6));
      final nextMon = currentMonday.add(const Duration(days: 7));

      final List<DateTime> dates = [currentSat, currentSun];
      for (int i = 0; i < 7; i++) {
        dates.add(nextMon.add(Duration(days: i)));
      }
      return dates; // 9 dates total
    } else {
      // Mon-Fri: Standard current week Mon-Sun
      return List.generate(7, (index) => currentMonday.add(Duration(days: index)));
    }
  }

  bool _isDayInActiveSchedule(DateTime date, List<String> activeDays) {
    if (activeDays.isEmpty) return false;
    final String dayName = DateFormat('EEE').format(date).toLowerCase().trim(); // e.g. 'sat'
    final String shortLabel = DateFormat('EEE, dd MMM').format(date).toLowerCase().trim(); // e.g. 'sat, 22 feb'

    return activeDays.any((d) {
      final String trimmed = d.trim().toLowerCase();
      return trimmed == shortLabel ||
             trimmed == dayName ||
             trimmed.startsWith(dayName);
    });
  }

  Widget _buildDateCardWidget(
    DateTime date,
    List<String> selectedDays,
    bool canEdit,
    StateSetter setMState, {
    bool forceSelected = false,
    bool isClosed = false,
  }) {
    final String dayName = DateFormat('EEE').format(date); // e.g. Mon
    final String monthDay = DateFormat('dd MMM').format(date); // e.g. 27 Jan
    final String shortLabel = "$dayName, $monthDay"; // e.g. Mon, 27 Jan

    final bool isSelected = !isClosed && (forceSelected ||
        selectedDays.contains(shortLabel) ||
        selectedDays.contains(dayName) ||
        selectedDays.any((d) => d.toLowerCase().startsWith(dayName.toLowerCase())));

    Widget cardChild = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 58,
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
      decoration: BoxDecoration(
        color: isClosed
            ? Colors.grey.shade100
            : (isSelected ? _coffeeBean : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isClosed
              ? Colors.grey.shade300
              : (isSelected ? _coffeeBean : _paleOak),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [BoxShadow(color: _coffeeBean.withAlpha(50), blurRadius: 6, offset: const Offset(0, 3))]
            : [],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              dayName.toUpperCase(),
              style: TextStyle(
                color: isClosed
                    ? Colors.grey.shade500
                    : (isSelected ? Colors.white70 : _fadedCopper),
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              monthDay,
              style: TextStyle(
                color: isClosed
                    ? Colors.grey.shade500
                    : (isSelected ? Colors.white : _darkText),
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isClosed) ...[
              const SizedBox(height: 1),
              Text(
                "CLOSED",
                style: TextStyle(
                  color: Colors.red.shade400,
                  fontSize: 7.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (isClosed) {
      cardChild = CustomPaint(
        foregroundPainter: DiagonalSlashPainter(color: Colors.red.shade300, strokeWidth: 1.8),
        child: cardChild,
      );
    }

    return GestureDetector(
      onTap: (canEdit && !isClosed)
          ? () {
              setMState(() {
                if (isSelected) {
                  selectedDays.removeWhere((d) =>
                      d == shortLabel ||
                      d == dayName ||
                      d.toLowerCase().startsWith(dayName.toLowerCase()));
                } else {
                  selectedDays.add(shortLabel);
                }
              });
            }
          : null,
      child: cardChild,
    );
  }

  /// Capitalizes the first letter of each word in a string (Title Case)
  String _toTitleCase(String text) {
    if (text.trim().isEmpty) return '';
    return text.trim().split(RegExp(r'\s+')).map((word) {
      if (word.isEmpty) return '';
      if (word.startsWith('(') && word.length > 1) {
        return '(${word[1].toUpperCase()}${word.substring(2).toLowerCase()}';
      }
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Generates 30-minute interval time slots from operating session ranges
  List<String> _generateSlotsFromSessions(List<Map<String, String>> sessions) {
    final List<String> slots = [];

    for (var s in sessions) {
      final startStr = s['start'];
      final endStr = s['end'];
      if (startStr == null || endStr == null || startStr.isEmpty || endStr.isEmpty) continue;

      final startMin = _parseTimeToMinutes(startStr);
      final endMin = _parseTimeToMinutes(endStr);

      if (startMin < endMin) {
        for (int m = startMin; m < endMin; m += 30) {
          slots.add(_formatMinutesToTimeString(m));
        }
      }
    }

    final List<String> uniqueSlots = slots.toSet().toList();
    uniqueSlots.sort((a, b) => _parseTimeToMinutes(a).compareTo(_parseTimeToMinutes(b)));
    return uniqueSlots;
  }

  int _parseTimeToMinutes(String timeStr) {
    try {
      final parts = timeStr.trim().split(' ');
      if (parts.length >= 2) {
        final timeParts = parts[0].split(':');
        int hour = int.parse(timeParts[0]);
        int minute = int.parse(timeParts[1]);
        final isPm = parts[1].toUpperCase() == 'PM';
        if (isPm && hour < 12) hour += 12;
        if (!isPm && hour == 12) hour = 0;
        return hour * 60 + minute;
      }
    } catch (_) {}
    return 540; // Default 9:00 AM
  }

  String _formatMinutesToTimeString(int totalMinutes) {
    int hour = (totalMinutes ~/ 60) % 24;
    int minute = totalMinutes % 60;
    final String period = hour >= 12 ? 'PM' : 'AM';
    int displayHour = hour % 12;
    if (displayHour == 0) displayHour = 12;
    final hStr = displayHour.toString().padLeft(2, '0');
    final mStr = minute.toString().padLeft(2, '0');
    return "$hStr:$mStr $period";
  }

  /// Handles Accepting Bookings toggle validation across all 4 prerequisite sections
  Future<void> _handleToggleAcceptingBookings(
    BuildContext context,
    bool targetVal, {
    required String currentHours,
    required List<String> currentDays,
    required List<String> currentTimeslots,
    required List<String> currentServices,
    required DateTime? lastUpdatedAt,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (targetVal == true) {
      final bool hasDays = currentDays.isNotEmpty;
      final bool hasHours = currentHours.trim().isNotEmpty;
      final bool hasSlots = currentTimeslots.isNotEmpty;
      final bool hasServices = currentServices.isNotEmpty;

      // If any of the 4 prerequisite sections is missing, prevent enabling accepting bookings
      if (!hasDays || !hasHours || !hasSlots || !hasServices) {
        List<String> missingItems = [];
        if (!hasDays) missingItems.add("Operating Days (Sec 1)");
        if (!hasHours) missingItems.add("Operating Sessions (Sec 2)");
        if (!hasSlots) missingItems.add("Time Slots (Sec 3)");
        if (!hasServices) missingItems.add("Offered Services");

        await _showWarningDialog(
          context,
          title: "Prerequisites Missing",
          message: "Cannot enable accepting bookings until all sections are configured:\n\nMissing: ${missingItems.join(', ')}",
        );

        if (!context.mounted) return;

        if (!hasDays || !hasHours || !hasSlots) {
          _showManageOperatingHoursModal(
            context,
            currentHoursStr: currentHours,
            currentDays: currentDays,
            currentTimeSlots: currentTimeslots,
            lastUpdatedAt: lastUpdatedAt,
          );
        } else if (!hasServices) {
          _showManageServicesModal(
            context,
            currentServices: currentServices,
          );
        }
        return;
      }

      // If ALL 4 sections are fulfilled, enable accepting bookings with 100% full profile sync
      if (uid != null) {
        Map<String, dynamic> fullData = {};
        try {
          final userDoc = await FirebaseFirestore.instance.collection('USERS').doc(uid).get();
          if (userDoc.exists && userDoc.data() != null) {
            fullData = Map<String, dynamic>.from(userDoc.data()!);
          }
        } catch (_) {}

        final String clinicName = fullData['clinicName'] ?? fullData['displayName'] ?? fullData['name'] ?? 'Veterinary Clinic';
        List<String> vetsList = List<String>.from(fullData['veterinarians'] ?? []);
        List<Map<String, dynamic>> doctorDetailsList = List<Map<String, dynamic>>.from(
          (fullData['doctorDetails'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ?? []
        );

        if (vetsList.isEmpty) {
          vetsList = ['Duty Veterinarian ($clinicName)'];
        }

        final syncData = {
          'isAcceptingBookings': true,
          'operatingHours': currentHours,
          'operatingDays': currentDays,
          'operatingTimeSlots': currentTimeslots,
          'services': currentServices,
          'veterinarians': vetsList,
          'doctorDetails': doctorDetailsList,
        };

        await FirebaseFirestore.instance.collection('USERS').doc(uid).set(syncData, SetOptions(merge: true));
        await FirebaseFirestore.instance.collection('CLINICS').doc(uid).set(syncData, SetOptions(merge: true));
      }
    } else {
      // Disable accepting bookings
      if (uid != null) {
        await FirebaseFirestore.instance.collection('USERS').doc(uid).set({'isAcceptingBookings': false}, SetOptions(merge: true));
        await FirebaseFirestore.instance.collection('CLINICS').doc(uid).set({'isAcceptingBookings': false}, SetOptions(merge: true));
      }
    }
  }

  /// Operating Hours & Days Modal with Weekly Saturday Update Restriction & Multiple Session Slots
  void _showManageOperatingHoursModal(
    BuildContext context, {
    required String currentHoursStr,
    required List<String> currentDays,
    List<String>? currentTimeSlots,
    DateTime? lastUpdatedAt,
  }) {
    final bool isSaturday = DateTime.now().weekday == DateTime.saturday;
    final bool isFirstTime = lastUpdatedAt == null;
    final bool canEdit = isSaturday || isFirstTime;

    final currentWeekDates = _getCurrentWeekOperatingDates();
    final List<String> selectedDays = List<String>.from(currentDays);

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

    List<String> selectedTimeSlots = List<String>.from(currentTimeSlots ?? []);
    bool isTimeSlotsExpanded = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setMState) {
          final currentGeneratedSlots = _generateSlotsFromSessions(slots);

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              height: MediaQuery.of(ctx).size.height * 0.82,
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
                      Expanded(
                        child: Text(
                          "Operating Schedule",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _coffeeBean),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: Icon(Icons.close_rounded, color: _coffeeBean),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Weekly Rule Banner
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 14),
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
                                        ? "Initial Setup: Choose weekly operating days & session hours."
                                        : (isSaturday
                                            ? "Saturday Update Window Open! Configure operating days & hours for the coming week."
                                            : "Schedule can only be updated every Saturday for the coming week. System is using active schedule."),
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
                            "1. Weekly Operating Dates & Days",
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _darkText),
                          ),
                          const SizedBox(height: 8),

                          if (currentWeekDates.length > 7) ...[
                            // Present Week Active Weekend Days (Sat & Sun)
                            Builder(
                              builder: (ctx) {
                                final bool isPresentSatOpen = _isDayInActiveSchedule(currentWeekDates[0], currentDays);
                                final bool isPresentSunOpen = _isDayInActiveSchedule(currentWeekDates[1], currentDays);

                                return Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: _paleOak),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.lock_rounded, color: Colors.grey.shade600, size: 14),
                                          const SizedBox(width: 6),
                                          Text(
                                            "Present Active Days",
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildDateCardWidget(
                                              currentWeekDates[0],
                                              selectedDays,
                                              false,
                                              setMState,
                                              forceSelected: isPresentSatOpen,
                                              isClosed: !isPresentSatOpen,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: _buildDateCardWidget(
                                              currentWeekDates[1],
                                              selectedDays,
                                              false,
                                              setMState,
                                              forceSelected: isPresentSunOpen,
                                              isClosed: !isPresentSunOpen,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Expanded(child: SizedBox()),
                                          const SizedBox(width: 8),
                                          const Expanded(child: SizedBox()),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            Text(
                              "Coming Week Operating Days",
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _fadedCopper),
                            ),
                            const SizedBox(height: 6),
                            // Upper Row (Mon, Tue, Wed, Thu)
                            Row(
                              children: [
                                for (int i = 2; i < 6; i++) ...[
                                  if (i > 2) const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildDateCardWidget(
                                      currentWeekDates[i],
                                      selectedDays,
                                      canEdit,
                                      setMState,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Lower Row (Fri, Sat, Sun)
                            Row(
                              children: [
                                for (int i = 6; i < 9; i++) ...[
                                  if (i > 6) const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildDateCardWidget(
                                      currentWeekDates[i],
                                      selectedDays,
                                      canEdit,
                                      setMState,
                                    ),
                                  ),
                                ],
                                const SizedBox(width: 8),
                                const Expanded(child: SizedBox()),
                              ],
                            ),
                          ] else ...[
                            // Standard Mon-Fri 2-Row Layout
                            Column(
                              children: [
                                // Upper Row (4 Days)
                                Row(
                                  children: [
                                    for (int i = 0; i < 4; i++) ...[
                                      if (i > 0) const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildDateCardWidget(
                                          currentWeekDates[i],
                                          selectedDays,
                                          canEdit,
                                          setMState,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Lower Row (3 Days)
                                Row(
                                  children: [
                                    for (int i = 4; i < 7; i++) ...[
                                      if (i > 4) const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildDateCardWidget(
                                          currentWeekDates[i],
                                          selectedDays,
                                          canEdit,
                                          setMState,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(width: 8),
                                    const Expanded(child: SizedBox()), // Alignment placeholder
                                  ],
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 14),

                          Text(
                            "2. Daily Operational Sessions & Breaks",
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _darkText),
                          ),
                          const SizedBox(height: 8),

                          // Session Cards
                          Column(
                            children: List.generate(slots.length, (index) {
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
                            }),
                          ),

                          if (canEdit) ...[
                            const SizedBox(height: 4),
                            // Button directly under session cards
                            OutlinedButton.icon(
                              onPressed: () {
                                setMState(() {
                                  slots.add({'start': '02:30 PM', 'end': '06:00 PM'});
                                });
                              },
                              icon: const Icon(Icons.more_time_rounded, size: 18),
                              label: const Text("Add Break / Additional Session"),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: _coffeeBean,
                                side: BorderSide(color: _coffeeBean, width: 1.5),
                                minimumSize: const Size(double.infinity, 44),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],

                          const SizedBox(height: 16),

                          // 3. Open Booking Time Slots Selection (Dropdown Box)
                          Text(
                            "3. Open Booking Time Slots for the Week",
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _darkText),
                          ),
                          const SizedBox(height: 8),

                          if (currentGeneratedSlots.isEmpty)
                            Text(
                              "Configure operational sessions above to auto-generate booking time slots.",
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                            )
                          else
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: _paleOak, width: 1.5),
                              ),
                              child: Column(
                                children: [
                                  // Dropdown Header Tile
                                  InkWell(
                                    onTap: () {
                                      setMState(() {
                                        isTimeSlotsExpanded = !isTimeSlotsExpanded;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(16),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      child: Row(
                                        children: [
                                          Icon(Icons.more_time_rounded, color: _coffeeBean, size: 22),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Select Open Booking Time Slots",
                                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _darkText),
                                                ),
                                                Text(
                                                  "${selectedTimeSlots.length} of ${currentGeneratedSlots.length} time slots selected for booking",
                                                  style: TextStyle(fontSize: 11, color: _fadedCopper),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            isTimeSlotsExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                            color: _coffeeBean,
                                            size: 24,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Expanded Content (Multi-Choice Grid & Quick Select Controls)
                                  if (isTimeSlotsExpanded) ...[
                                    const Divider(height: 1),
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (canEdit)
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    "Tap to check/uncheck slots:",
                                                    style: TextStyle(fontSize: 11, color: _fadedCopper, fontWeight: FontWeight.w600),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Row(
                                                  children: [
                                                    InkWell(
                                                      onTap: () {
                                                        setMState(() {
                                                          selectedTimeSlots = List.from(currentGeneratedSlots);
                                                        });
                                                      },
                                                      child: Text("Select All", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _coffeeBean)),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text("•", style: TextStyle(color: _fadedCopper, fontSize: 10)),
                                                    const SizedBox(width: 8),
                                                    InkWell(
                                                      onTap: () {
                                                        setMState(() {
                                                          selectedTimeSlots.clear();
                                                        });
                                                      },
                                                      child: const Text("Clear All", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          const SizedBox(height: 10),

                                          // Clean 3-Column Grid for Time Slots
                                          GridView.builder(
                                            shrinkWrap: true,
                                            physics: const NeverScrollableScrollPhysics(),
                                            itemCount: currentGeneratedSlots.length,
                                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 3,
                                              childAspectRatio: 2.8,
                                              crossAxisSpacing: 8,
                                              mainAxisSpacing: 8,
                                            ),
                                            itemBuilder: (context, idx) {
                                              final slotTime = currentGeneratedSlots[idx];
                                              final bool isSlotSelected = selectedTimeSlots.contains(slotTime);

                                              return InkWell(
                                                onTap: canEdit
                                                    ? () {
                                                        setMState(() {
                                                          if (isSlotSelected) {
                                                            selectedTimeSlots.remove(slotTime);
                                                          } else {
                                                            selectedTimeSlots.add(slotTime);
                                                          }
                                                        });
                                                      }
                                                    : null,
                                                borderRadius: BorderRadius.circular(10),
                                                child: AnimatedContainer(
                                                  duration: const Duration(milliseconds: 150),
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: isSlotSelected ? _coffeeBean : _almondCream.withAlpha(80),
                                                    borderRadius: BorderRadius.circular(10),
                                                    border: Border.all(
                                                      color: isSlotSelected ? _coffeeBean : _paleOak,
                                                      width: isSlotSelected ? 1.5 : 1,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(
                                                        isSlotSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                                                        size: 14,
                                                        color: isSlotSelected ? Colors.white : _fadedCopper,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Flexible(
                                                        child: FittedBox(
                                                          fit: BoxFit.scaleDown,
                                                          child: Text(
                                                            slotTime,
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              fontWeight: FontWeight.bold,
                                                              color: isSlotSelected ? Colors.white : _darkText,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                          if (canEdit) ...[
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () async {
                                final formatted = slots.map((s) => "${s['start']} - ${s['end']}").join(', ');

                                // 1. Validate all 3 sections are selected
                                final bool hasDays = selectedDays.isNotEmpty;
                                final bool hasSessions = formatted.trim().isNotEmpty;
                                final bool hasTimeSlots = selectedTimeSlots.isNotEmpty;

                                if (!hasDays || !hasSessions || !hasTimeSlots) {
                                  List<String> missing = [];
                                  if (!hasDays) missing.add("Operating Days (Sec 1)");
                                  if (!hasSessions) missing.add("Session Hours (Sec 2)");
                                  if (!hasTimeSlots) missing.add("Booking Time Slots (Sec 3)");

                                  await _showWarningDialog(
                                    context,
                                    title: "Incomplete Schedule",
                                    message: "Please select all 3 sections before saving:\n\nMissing: ${missing.join(', ')}",
                                  );
                                  return;
                                }

                                // 2. Show confirmation popup window dialog
                                final bool? confirmSave = await showDialog<bool>(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (dialogCtx) => Dialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                    backgroundColor: Colors.white,
                                    elevation: 8,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 56,
                                            height: 56,
                                            decoration: BoxDecoration(
                                              color: _coffeeBean.withAlpha(25),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(Icons.lock_clock_rounded, color: _coffeeBean, size: 30),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            "Lock Operating Schedule?",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: _darkText,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            "Once saved, your operating schedule will be locked for the active week and cannot be changed until next Saturday.\n\nAre you sure you want to lock and save this schedule?",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: _fadedCopper,
                                              height: 1.4,
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                child: OutlinedButton(
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor: Colors.grey.shade700,
                                                    side: BorderSide(color: Colors.grey.shade300),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                                  ),
                                                  onPressed: () => Navigator.pop(dialogCtx, false),
                                                  child: const Center(
                                                    child: Text(
                                                      "CANCEL",
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: _coffeeBean,
                                                    foregroundColor: Colors.white,
                                                    elevation: 0,
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                                  ),
                                                  onPressed: () => Navigator.pop(dialogCtx, true),
                                                  child: const Center(
                                                    child: Text(
                                                      "CONFIRM",
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );

                                if (confirmSave != true) return;

                                // 3. Save to Firestore with 100% full profile sync
                                final uid = FirebaseAuth.instance.currentUser?.uid;

                                List<String> currentServices = [];
                                List<String> currentVets = [];
                                List<Map<String, dynamic>> currentDoctors = [];
                                String clinicName = 'Veterinary Clinic';

                                if (uid != null) {
                                  try {
                                    final doc = await FirebaseFirestore.instance.collection('USERS').doc(uid).get();
                                    if (doc.exists && doc.data() != null) {
                                      final data = doc.data()!;
                                      clinicName = data['clinicName'] ?? data['displayName'] ?? data['name'] ?? 'Veterinary Clinic';
                                      currentServices = List<String>.from(data['services'] ?? []);
                                      currentVets = List<String>.from(data['veterinarians'] ?? []);
                                      currentDoctors = List<Map<String, dynamic>>.from(
                                        (data['doctorDetails'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ?? []
                                      );
                                    }
                                  } catch (_) {}
                                }

                                if (currentVets.isEmpty) {
                                  currentVets = ['Duty Veterinarian ($clinicName)'];
                                }

                                final bool isFullyConfigured = currentServices.isNotEmpty;

                                if (uid != null) {
                                  final updatePayload = {
                                    'operatingHours': formatted,
                                    'operatingDays': selectedDays,
                                    'operatingTimeSlots': selectedTimeSlots,
                                    'isAcceptingBookings': isFullyConfigured,
                                    'services': currentServices,
                                    'veterinarians': currentVets,
                                    'doctorDetails': currentDoctors,
                                    'lastHoursUpdatedAt': FieldValue.serverTimestamp(),
                                  };

                                  await FirebaseFirestore.instance.collection('USERS').doc(uid).set(updatePayload, SetOptions(merge: true));
                                  await FirebaseFirestore.instance.collection('CLINICS').doc(uid).set(updatePayload, SetOptions(merge: true));
                                }

                                if (context.mounted) {
                                  Navigator.pop(ctx);
                                  await _showSuccessDialog(
                                    context,
                                    title: "Schedule Saved & Locked",
                                    message: isFullyConfigured
                                        ? "Operating schedule locked and saved successfully! Accepting bookings is now active."
                                        : "Operating schedule locked and saved. Please select offered services to enable accepting bookings.",
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _coffeeBean,
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Center(
                                child: Text(
                                  "Save & Lock Schedule",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                        ],
                      ),
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

  void _showManageServicesModal(BuildContext context, {required List<String> currentServices}) {
    final TextEditingController otherSvcCtrl = TextEditingController();

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

    // Capitalize and include any custom services from currentServices into availableServices
    for (var c in currentServices) {
      final cap = _toTitleCase(c);
      if (cap.isNotEmpty && !availableServices.contains(cap)) {
        availableServices.add(cap);
      }
    }

    final List<String> selectedServices = List<String>.from(
      currentServices.map((s) => _toTitleCase(s)).where((s) => s.isNotEmpty),
    );

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
                          "Manage Offered Services",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _coffeeBean),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Select medical services offered at your clinic. Updates sync real time to Pet Owner Booking screen",
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 14),

                  // Add Custom / "Others" Service Row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: otherSvcCtrl,
                          decoration: InputDecoration(
                            hintText: "Add custom service / Others...",
                            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                            fillColor: Colors.white,
                            filled: true,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _paleOak)),
                          ),
                          style: TextStyle(fontSize: 12, color: _darkText, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          final rawText = otherSvcCtrl.text.trim();
                          if (rawText.isNotEmpty) {
                            final capitalized = _toTitleCase(rawText);
                            setSheetState(() {
                              if (!availableServices.contains(capitalized)) {
                                availableServices.add(capitalized);
                              }
                              if (!selectedServices.contains(capitalized)) {
                                selectedServices.add(capitalized);
                              }
                              otherSvcCtrl.clear();
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
                  const SizedBox(height: 14),

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

                      List<String> currentDays = [];
                      String currentHours = "";
                      List<String> currentSlots = [];
                      List<String> currentVets = [];
                      List<Map<String, dynamic>> currentDoctors = [];
                      String clinicName = 'Veterinary Clinic';

                      if (uid != null) {
                        try {
                          final doc = await FirebaseFirestore.instance.collection('USERS').doc(uid).get();
                          if (doc.exists && doc.data() != null) {
                            final data = doc.data()!;
                            clinicName = data['clinicName'] ?? data['displayName'] ?? data['name'] ?? 'Veterinary Clinic';
                            currentDays = List<String>.from(data['operatingDays'] ?? []);
                            currentHours = (data['operatingHours'] ?? "").toString();
                            currentSlots = List<String>.from(data['operatingTimeSlots'] ?? []);
                            currentVets = List<String>.from(data['veterinarians'] ?? []);
                            currentDoctors = List<Map<String, dynamic>>.from(
                              (data['doctorDetails'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ?? []
                            );
                          }
                        } catch (_) {}
                      }

                      if (currentVets.isEmpty) {
                        currentVets = ['Duty Veterinarian ($clinicName)'];
                      }

                      final bool isFullyConfigured = selectedServices.isNotEmpty &&
                          currentDays.isNotEmpty &&
                          currentHours.trim().isNotEmpty &&
                          currentSlots.isNotEmpty;

                      if (uid != null) {
                        final updatePayload = {
                          'services': selectedServices,
                          'operatingHours': currentHours,
                          'operatingDays': currentDays,
                          'operatingTimeSlots': currentSlots,
                          'veterinarians': currentVets,
                          'doctorDetails': currentDoctors,
                          'isAcceptingBookings': isFullyConfigured,
                          'lastServicesUpdatedAt': FieldValue.serverTimestamp(),
                        };

                        await FirebaseFirestore.instance.collection('USERS').doc(uid).set(updatePayload, SetOptions(merge: true));
                        await FirebaseFirestore.instance.collection('CLINICS').doc(uid).set(updatePayload, SetOptions(merge: true));
                      }
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        await _showSuccessDialog(
                          context,
                          title: "Services Saved",
                          message: isFullyConfigured
                              ? "Offered services updated successfully! Accepting bookings is now active."
                              : "Offered services updated. Please complete your operating schedule to enable accepting bookings.",
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

  int _currentNavIndex = 0;
  String _patientStatusFilter = 'ALL';
  final TextEditingController _patientSearchCtrl = TextEditingController();

  String _getNavHeaderTitle() {
    switch (_currentNavIndex) {
      case 0:
        return "PAWKODA VETERINARY";
      case 1:
        return "OPERATIONAL SCHEDULE";
      case 2:
        return "PATIENTS & APPOINTMENTS";
      case 3:
        return "VET CLINIC SETTINGS";
      default:
        return "PAWKODA VETERINARY";
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final String clinicName = userProvider.displayName ?? "PawKODA Veterinary Clinic";

    return Scaffold(
      backgroundColor: _almondCream, // Warm background
      body: Column(
        children: [
          // 1. Sticky Wave Fringe Header for Vet Module
          DashboardFringeHeader(
            greeting: _getNavHeaderTitle(),
            userName: clinicName,
            photoUrl: userProvider.photoUrl,
            backgroundColor: _coffeeBean,
            onLogout: () => _handleLogout(context),
            onTapAvatar: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              );
            },
          ),

          // 2. Scrollable Body Content corresponding to selected navigation tab
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: _buildCurrentTabView(userProvider, clinicName),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildCurrentTabView(UserProvider userProvider, String clinicName) {
    switch (_currentNavIndex) {
      case 0:
        return _buildDashboardTab(userProvider, clinicName);
      case 1:
        return _buildScheduleTab(userProvider);
      case 2:
        return _buildPatientsTab(userProvider, clinicName);
      case 3:
        return _buildSettingsTab(userProvider, clinicName);
      default:
        return _buildDashboardTab(userProvider, clinicName);
    }
  }

  // TAB 0: DASHBOARD TAB
  Widget _buildDashboardTab(UserProvider userProvider, String clinicName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Appointment Queue Title Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Appointment Queue", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _darkText)),
            InkWell(
              onTap: () {
                setState(() {
                  _currentNavIndex = 2; // Redirect to Patient Bookings tab
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "View All",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _coffeeBean,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.arrow_forward_ios_rounded, size: 12, color: _coffeeBean),
                  ],
                ),
              ),
            ),
          ],
        ),
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

            // Display maximum 2 appointment items on Dashboard tab
            final displayedBookings = bookings.take(2).toList();

            return Column(
              children: displayedBookings.map((b) => _appointmentCard(context, b)).toList(),
            );
          },
        ),
        const SizedBox(height: 32),

        // Real-Time Daily Slot Management & Self-Occupied Lock
        Text("Daily Slot View", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _darkText)),
        const SizedBox(height: 12),
        _buildDailySlotManagementCard(userProvider, clinicName),
        const SizedBox(height: 32),

        // Schedule Panel
        Text("Operational Schedule", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _darkText)),
        const SizedBox(height: 12),
        _buildDashboardScheduleCard(userProvider),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildDailySlotManagementCard(UserProvider userProvider, String clinicName) {
    final String clinicUid = userProvider.uid ?? FirebaseAuth.instance.currentUser?.uid ?? '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final String dayNameStr = DateFormat('EEEE').format(now).toUpperCase(); // e.g. SATURDAY
    final String dateNumMonthYearStr = DateFormat('dd MMMM yyyy').format(now); // e.g. 31 October 2026

    return StreamBuilder<DocumentSnapshot>(
      stream: clinicUid.isNotEmpty
          ? FirebaseFirestore.instance.collection('USERS').doc(clinicUid).snapshots()
          : null,
      builder: (context, userSnap) {
        List<String> operatingSlots = [];
        List<String> operatingDays = [];
        if (userSnap.hasData && userSnap.data!.exists) {
          final data = userSnap.data!.data() as Map<String, dynamic>?;
          operatingSlots = List<String>.from(data?['operatingTimeSlots'] ?? []);
          operatingDays = List<String>.from(data?['operatingDays'] ?? []);
        }

        final bool isClinicOpenToday = _isDayInActiveSchedule(now, operatingDays);

        operatingSlots.sort((a, b) => _parseTimeToMinutes(a).compareTo(_parseTimeToMinutes(b)));

        return StreamBuilder<List<BookingModel>>(
          stream: clinicUid.isNotEmpty
              ? _bookingService.streamClinicActiveBookings(clinicUid)
              : null,
          builder: (context, bookingSnap) {
            final activeBookings = bookingSnap.data ?? [];

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _paleOak, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Squared Container Header: Day and Date at top middle
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: _almondCream.withAlpha(140),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _paleOak),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          dayNameStr,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _coffeeBean,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateNumMonthYearStr,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _coffeeBean,
                          ),
                        ),
                        if (isClinicOpenToday) ...[
                          const SizedBox(height: 4),
                          Text(
                            "Tap available to lock.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: _fadedCopper,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (!isClinicOpenToday) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        children: [
                          Icon(Icons.door_front_door_outlined, color: Colors.red.shade400, size: 32),
                          const SizedBox(height: 6),
                          Text(
                            "Clinic Closed today",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (operatingSlots.isEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        "No operating time slots configured for today. Please configure Section 3 in Operating Schedule below.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.redAccent, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ] else ...[
                    // 3 Time Slots per row grid (read horizontally, earliest to latest)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1.38,
                      ),
                      itemCount: operatingSlots.length,
                      itemBuilder: (context, index) {
                        final slotStr = operatingSlots[index];
                        final slotDateTime = _parseTimeToTodayDateTime(slotStr);
                        final bool isPast = now.isAfter(slotDateTime.add(const Duration(minutes: 30)));

                        BookingModel? existingBooking;
                        for (var b in activeBookings) {
                          final bool sameDate = b.bookingDate.year == today.year &&
                              b.bookingDate.month == today.month &&
                              b.bookingDate.day == today.day;
                          final bool sameSlot = b.timeSlot.trim().toLowerCase() == slotStr.trim().toLowerCase();
                          if (sameDate && sameSlot) {
                            existingBooking = b;
                            break;
                          }
                        }

                        final bool isBooked = existingBooking != null;
                        final bool isSelfOccupied = isBooked &&
                            (existingBooking.petName == 'Walk-In Patient' ||
                             existingBooking.preferredVet == 'Clinic Occupied' ||
                             existingBooking.notes.contains('Vet Personnel'));

                        // Determine slot styling based on state
                        Color bg;
                        Color borderColor;
                        Color textColor;
                        String badgeText;

                        if (isBooked) {
                          bg = Colors.grey.shade100;
                          borderColor = Colors.grey.shade300;
                          textColor = Colors.grey.shade600;
                          badgeText = isSelfOccupied ? "OCCUPIED" : "BOOKED BY OWNER";
                        } else if (isPast) {
                          bg = Colors.red.shade50;
                          borderColor = Colors.red.shade200;
                          textColor = Colors.red.shade800;
                          badgeText = "PASSED";
                        } else {
                          bg = Colors.white;
                          borderColor = _coffeeBean;
                          textColor = _darkText;
                          badgeText = "AVAILABLE";
                        }

                        Widget slotCard = Container(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor, width: isBooked ? 1 : (isPast ? 1 : 1.5)),
                            boxShadow: (!isBooked && !isPast)
                                ? [BoxShadow(color: _coffeeBean.withAlpha(20), blurRadius: 4, offset: const Offset(0, 2))]
                                : [],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                slotStr,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                badgeText,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.bold,
                                  color: isBooked
                                      ? Colors.grey.shade600
                                      : (isPast ? Colors.red.shade700 : Colors.green.shade700),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (isBooked) {
                          slotCard = CustomPaint(
                            foregroundPainter: DiagonalSlashPainter(color: Colors.red.shade300, strokeWidth: 1.8),
                            child: slotCard,
                          );
                        }

                        return InkWell(
                          onTap: () async {
                            if (isBooked) {
                              if (isSelfOccupied) {
                                // Confirm to release self-occupied slot
                                final bool? unlock = await showDialog<bool>(
                                  context: context,
                                  builder: (dlgCtx) => AlertDialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    title: Text("Unlock Time Slot?", style: TextStyle(fontWeight: FontWeight.bold, color: _darkText)),
                                    content: Text(
                                      "Do you want to release the $slotStr occupied time slot and make it available again for bookings?",
                                      style: TextStyle(color: _fadedCopper, fontSize: 13),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(dlgCtx, false),
                                        child: Text("CANCEL", style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red.shade700,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        onPressed: () => Navigator.pop(dlgCtx, true),
                                        child: const Text("UNLOCK SLOT", style: TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                );

                                if (unlock == true) {
                                  await _bookingService.deleteBooking(clinicUid, existingBooking!.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("✓ $slotStr time slot released and unlocked!"),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                }
                              } else {
                                // Owner Booking details
                                await showDialog(
                                  context: context,
                                  builder: (dlgCtx) => AlertDialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    title: Text("Owner Booking Info", style: TextStyle(fontWeight: FontWeight.bold, color: _darkText)),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Time Slot: $slotStr", style: TextStyle(fontWeight: FontWeight.bold, color: _coffeeBean)),
                                        const SizedBox(height: 6),
                                        Text("Pet Name: ${existingBooking!.petName}", style: TextStyle(color: _darkText, fontSize: 13)),
                                        Text("Species: ${existingBooking.petSpecies}", style: TextStyle(color: _darkText, fontSize: 13)),
                                        Text("Service: ${existingBooking.serviceType}", style: TextStyle(color: _darkText, fontSize: 13)),
                                        Text("Preferred Vet: ${existingBooking.preferredVet}", style: TextStyle(color: _darkText, fontSize: 13)),
                                        Text("Status: ${existingBooking.status}", style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 13)),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(dlgCtx),
                                        child: Text("OK", style: TextStyle(color: _coffeeBean, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            } else {
                              // Unbooked slot tap: prompt to self-occupy / lock
                              final bool? confirmLock = await showDialog<bool>(
                                context: context,
                                builder: (dlgCtx) => AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  title: Text("Occupy Time Slot?", style: TextStyle(fontWeight: FontWeight.bold, color: _darkText)),
                                  content: Text(
                                    "Reserve/lock the $slotStr time slot as occupied?\n\nThis will lock the slot in real-time so pet owners cannot book it.",
                                    style: TextStyle(color: _fadedCopper, fontSize: 13, height: 1.4),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dlgCtx, false),
                                      child: Text("CANCEL", style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _coffeeBean,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      onPressed: () => Navigator.pop(dlgCtx, true),
                                      child: const Text("CONFIRM LOCK", style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmLock == true) {
                                final newBooking = BookingModel(
                                  id: '',
                                  userId: clinicUid,
                                  petId: 'walkin_pet',
                                  petName: 'Walk-In Patient',
                                  petSpecies: 'Walk-In',
                                  clinicId: clinicUid,
                                  clinicName: clinicName,
                                  clinicAddress: 'Clinic Location',
                                  clinicPhone: '',
                                  city: 'Penang',
                                  serviceType: 'Walk-In / Direct Booking',
                                  preferredVet: 'Clinic Occupied',
                                  bookingDate: today,
                                  timeSlot: slotStr,
                                  notes: 'Self-occupied by Vet Personnel',
                                  status: 'CONFIRMED',
                                  createdAt: now,
                                );

                                await _bookingService.createBooking(newBooking);

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("✓ $slotStr slot set to occupied! Real-time synced."),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: slotCard,
                        );
                      },
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  DateTime _parseTimeToTodayDateTime(String timeStr) {
    final now = DateTime.now();
    try {
      final parts = timeStr.trim().split(' ');
      if (parts.length >= 2) {
        final timeParts = parts[0].split(':');
        int hour = int.parse(timeParts[0]);
        int minute = int.parse(timeParts[1]);
        final isPm = parts[1].toUpperCase() == 'PM';
        if (isPm && hour < 12) hour += 12;
        if (!isPm && hour == 12) hour = 0;
        return DateTime(now.year, now.month, now.day, hour, minute);
      }
    } catch (_) {}
    return DateTime(now.year, now.month, now.day, 23, 59);
  }

  // TAB 1: SCHEDULE TAB
  Widget _buildScheduleTab(UserProvider userProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Clinic Availability", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _darkText)),
        const SizedBox(height: 12),
        _buildSchedulePanelCard(userProvider),
        const SizedBox(height: 80),
      ],
    );
  }

  // TAB 2: PATIENTS TAB
  Widget _buildPatientsTab(UserProvider userProvider, String clinicName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Patient Bookings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _darkText)),
        const SizedBox(height: 12),

        // Search Bar
        TextField(
          controller: _patientSearchCtrl,
          onChanged: (val) => setState(() {}),
          decoration: InputDecoration(
            hintText: "Search patient or pet name...",
            hintStyle: TextStyle(color: _fadedCopper, fontSize: 13),
            prefixIcon: Icon(Icons.search_rounded, color: _coffeeBean, size: 20),
            fillColor: Colors.white,
            filled: true,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 12),

        // Status Filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['ALL', 'PENDING', 'CONFIRMED', 'COMPLETED', 'CANCELLED'].map((st) {
              final isSel = _patientStatusFilter == st;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(st, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSel ? Colors.white : _coffeeBean)),
                  selected: isSel,
                  selectedColor: _coffeeBean,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: isSel ? _coffeeBean : _paleOak),
                  ),
                  onSelected: (sel) {
                    if (sel) setState(() => _patientStatusFilter = st);
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

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
            final allBookings = snapshot.data ?? [];
            final String query = _patientSearchCtrl.text.trim().toLowerCase();

            final filtered = allBookings.where((b) {
              final matchesStatus = _patientStatusFilter == 'ALL' || b.status.toUpperCase() == _patientStatusFilter;
              final matchesQuery = query.isEmpty ||
                  b.petName.toLowerCase().contains(query) ||
                  b.petSpecies.toLowerCase().contains(query) ||
                  b.serviceType.toLowerCase().contains(query) ||
                  b.preferredVet.toLowerCase().contains(query);
              return matchesStatus && matchesQuery;
            }).toList();

            if (filtered.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Center(
                  child: Text(
                    "No patient records found.",
                    style: TextStyle(color: _fadedCopper, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              );
            }

            return Column(
              children: filtered.map((b) => _appointmentCard(context, b)).toList(),
            );
          },
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  // TAB 3: SETTINGS TAB
  Widget _buildSettingsTab(UserProvider userProvider, String clinicName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Clinic Profile Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _paleOak),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: _coffeeBean,
                child: const Icon(Icons.local_hospital, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(clinicName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _darkText)),
                    Text(userProvider.email ?? 'clinic@vet.com', style: TextStyle(fontSize: 12, color: _fadedCopper)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
                      child: Text("Verified Vet Organization", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Text("Clinic Portal Settings", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _darkText)),
        const SizedBox(height: 10),

        _settingsTile(Icons.person_outline_rounded, "Edit Clinic Profile", "Update display name and clinic logo", () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
        }),
        _settingsTile(Icons.security_rounded, "Privacy & Service Policies", "SSM compliance, terms & account privacy", () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const VetPrivacySecurityScreen()));
        }),

        const SizedBox(height: 20),

        // Logout
        ElevatedButton.icon(
          onPressed: () => _handleLogout(context),
          icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
          label: const Text("Logout from Vet Portal", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _settingsTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _paleOak),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: _coffeeBean.withAlpha(20), shape: BoxShape.circle),
          child: Icon(icon, color: _coffeeBean, size: 20),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _darkText)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: _fadedCopper)),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _fadedCopper),
      ),
    );
  }

  Widget _buildDashboardScheduleCard(UserProvider userProvider) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseAuth.instance.currentUser?.uid != null
          ? FirebaseFirestore.instance.collection('USERS').doc(FirebaseAuth.instance.currentUser!.uid).snapshots()
          : null,
      builder: (context, userSnap) {
        Map<String, dynamic>? userData;
        if (userSnap.hasData && userSnap.data!.exists) {
          userData = userSnap.data!.data() as Map<String, dynamic>?;
        }
        final String currentHours = userData?['operatingHours'] ?? "";
        final List<String> currentDays = List<String>.from(userData?['operatingDays'] ?? []);
        final bool isAccepting = userData?['isAcceptingBookings'] ?? false;
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
              _scheduleToggle(
                "Accepting Bookings",
                isAccepting,
                (val) => _handleToggleAcceptingBookings(
                  context,
                  val,
                  currentHours: currentHours,
                  currentDays: currentDays,
                  lastUpdatedAt: lastUpdatedAt,
                  currentTimeslots: List<String>.from(userData?['operatingTimeSlots'] ?? []),
                  currentServices: List<String>.from(userData?['services'] ?? []),
                ),
              ),
              const Divider(),
              
              // Operating Days Active Display
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_month_rounded, color: _coffeeBean, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Operating Days: ${currentDays.isNotEmpty ? currentDays.join(', ') : 'Not Set'}",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: currentDays.isNotEmpty ? _darkText : Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Operating Hours Active Display
              Row(
                children: [
                  Icon(Icons.access_time_filled_rounded, color: _coffeeBean, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Operating Hours: ${currentHours.isNotEmpty ? currentHours : 'Not Set (Configured by Vet)'}",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: currentHours.isNotEmpty ? _darkText : Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSchedulePanelCard(UserProvider userProvider) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseAuth.instance.currentUser?.uid != null
          ? FirebaseFirestore.instance.collection('USERS').doc(FirebaseAuth.instance.currentUser!.uid).snapshots()
          : null,
      builder: (context, userSnap) {
        Map<String, dynamic>? userData;
        if (userSnap.hasData && userSnap.data!.exists) {
          userData = userSnap.data!.data() as Map<String, dynamic>?;
        }
        final String currentHours = userData?['operatingHours'] ?? "";
        final List<String> currentDays = List<String>.from(userData?['operatingDays'] ?? []);
        final bool isAccepting = userData?['isAcceptingBookings'] ?? false;
        final Timestamp? lastUpdatedTs = userData?['lastHoursUpdatedAt'] as Timestamp?;
        final DateTime? lastUpdatedAt = lastUpdatedTs?.toDate();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // White Container Box (Operating Info & Accepting Bookings Toggle)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _paleOak, width: 1.5)
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _scheduleToggle(
                    "Accepting Bookings",
                    isAccepting,
                    (val) => _handleToggleAcceptingBookings(
                      context,
                      val,
                      currentHours: currentHours,
                      currentDays: currentDays,
                      lastUpdatedAt: lastUpdatedAt,
                      currentTimeslots: List<String>.from(userData?['operatingTimeSlots'] ?? []),
                      currentServices: List<String>.from(userData?['services'] ?? []),
                    ),
                  ),
                  const Divider(),
                  
                  // Operating Days Active Display
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_month_rounded, color: _coffeeBean, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Operating Days: ${currentDays.isNotEmpty ? currentDays.join(', ') : 'Not Set'}",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: currentDays.isNotEmpty ? _darkText : Colors.redAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Operating Hours Active Display
                  Row(
                    children: [
                      Icon(Icons.access_time_filled_rounded, color: _coffeeBean, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Operating Hours: ${currentHours.isNotEmpty ? currentHours : 'Not Set (Configured by Vet)'}",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: currentHours.isNotEmpty ? _darkText : Colors.redAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3 Management Buttons (Outside & Below White Box)
            // 1. Manage Operating Schedule Button
            OutlinedButton.icon(
              onPressed: () => _showManageOperatingHoursModal(
                context,
                currentHoursStr: currentHours,
                currentDays: currentDays,
                currentTimeSlots: List<String>.from(userData?['operatingTimeSlots'] ?? []),
                lastUpdatedAt: lastUpdatedAt,
              ),
              icon: const Icon(Icons.edit_calendar_rounded, size: 18),
              label: const Text("Manage Operating Schedule", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _coffeeBean,
                side: BorderSide(color: _coffeeBean, width: 1.5),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 10),

            // 2. Manage Offered Services Button
            OutlinedButton.icon(
              onPressed: () => _showManageServicesModal(
                context,
                currentServices: List<String>.from(userData?['services'] ?? ['General Consultation', 'Vaccination', 'Deworming']),
              ),
              icon: const Icon(Icons.medical_services_outlined, size: 18),
              label: const Text("Manage Offered Services", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _coffeeBean,
                side: BorderSide(color: _coffeeBean, width: 1.5),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 10),

            // 3. Manage Vet Availability Button (LOCKED until schedule is configured)
            Builder(
              builder: (context) {
                final bool isScheduleConfigured = currentHours.trim().isNotEmpty && currentDays.isNotEmpty;

                return OutlinedButton.icon(
                  onPressed: isScheduleConfigured
                      ? () => _showManageStaffModal(context)
                      : () {
                          _showWarningDialog(
                            context,
                            title: "Schedule Required",
                            message: "Please configure and save your operating schedule first before managing vet availability.",
                          );
                        },
                  icon: Icon(
                    isScheduleConfigured ? Icons.people_alt_rounded : Icons.lock_rounded,
                    color: isScheduleConfigured ? _coffeeBean : Colors.grey.shade600,
                    size: 18,
                  ),
                  label: Text(
                    isScheduleConfigured ? "Manage Vet Availability" : "Manage Vet Availability (Schedule Required)",
                    style: TextStyle(
                      color: isScheduleConfigured ? _coffeeBean : Colors.grey.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: isScheduleConfigured ? _coffeeBean : Colors.grey.shade600,
                    side: BorderSide(color: isScheduleConfigured ? _coffeeBean : Colors.grey.shade400, width: 1.5),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  DateTime _getAppointmentDateTime(DateTime date, String slotStr) {
    int hour = 9;
    int minute = 0;
    try {
      if (slotStr.isNotEmpty) {
        final parts = slotStr.trim().split(' ');
        if (parts.length >= 2) {
          final timeParts = parts[0].split(':');
          hour = int.parse(timeParts[0]);
          minute = int.parse(timeParts[1]);
          final isPm = parts[1].toUpperCase() == 'PM';
          if (isPm && hour < 12) hour += 12;
          if (!isPm && hour == 12) hour = 0;
        }
      }
    } catch (_) {}
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  Future<bool> _showCancelConfirmationDialog(BuildContext context, BookingModel booking, String dateStr) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 24),
            const SizedBox(width: 8),
            Text("Cancel Booking?", style: TextStyle(color: _darkText, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          "Are you sure you want to cancel the booking request for ${booking.petName} on $dateStr at ${booking.timeSlot}?\n\nThis will notify the pet owner and immediately release the time slot.",
          style: TextStyle(fontSize: 13, color: _darkText, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Keep Booking", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Cancel Booking", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;
  }

  Widget _appointmentCard(BuildContext context, BookingModel booking) {
    final String statusUpper = booking.status.toUpperCase();
    final Color statusColor = statusUpper == 'PENDING'
        ? _toffeeBrown
        : (statusUpper == 'CONFIRMED' ? Colors.green : (statusUpper == 'COMPLETED' ? Colors.blue.shade700 : Colors.red));

    final String dateStr = DateFormat('dd MMM yyyy').format(booking.bookingDate);
    final DateTime apptDateTime = _getAppointmentDateTime(booking.bookingDate, booking.timeSlot);
    final bool isAppointmentTimeReached = DateTime.now().isAfter(apptDateTime) || DateTime.now().isAtSameMomentAs(apptDateTime);

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.petName,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _darkText),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${booking.petSpecies} • ${booking.serviceType}",
                      style: TextStyle(color: _fadedCopper, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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
            const SizedBox(height: 14),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final bool confirmed = await _showCancelConfirmationDialog(context, booking, dateStr);
                    if (!confirmed) return;

                    await BookingService().updateBookingStatus(booking.userId, booking.id, 'CANCELLED');
                    
                    // 1. Log notification for Pet Owner
                    await UserNotificationService().logNotification(
                      userId: booking.userId,
                      title: "Booking Request Cancelled",
                      body: "${booking.clinicName} was unable to accept your booking for ${booking.petName} on $dateStr at ${booking.timeSlot}. The time slot has been released.",
                      type: 'booking',
                    );

                    // 2. Trigger push notification for Pet Owner
                    await NotificationService().showNotification(
                      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                      title: "Booking Cancelled",
                      body: "${booking.clinicName} cancelled booking request for ${booking.petName} on $dateStr at ${booking.timeSlot}.",
                    );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Cancelled booking for ${booking.petName}. Slot released."),
                          backgroundColor: Colors.red.shade700,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.cancel_outlined, size: 16, color: Colors.white),
                  label: const Text("Cancel", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () async {
                    await BookingService().updateBookingStatus(booking.userId, booking.id, 'CONFIRMED');

                    // 1. Log notification for Pet Owner
                    await UserNotificationService().logNotification(
                      userId: booking.userId,
                      title: "Booking Confirmed!",
                      body: "${booking.clinicName} has confirmed your appointment for ${booking.petName} on $dateStr at ${booking.timeSlot}.",
                      type: 'booking',
                    );

                    // 2. Trigger push notification for Pet Owner
                    await NotificationService().showNotification(
                      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                      title: "Booking Confirmed!",
                      body: "${booking.clinicName} confirmed appointment for ${booking.petName} on $dateStr at ${booking.timeSlot}.",
                    );

                    // 3. Schedule 3-days-before push notification for Pet Owner
                    await NotificationService().scheduleBookingReminder(
                      bookingId: booking.id,
                      petName: booking.petName,
                      clinicName: booking.clinicName,
                      serviceType: booking.serviceType,
                      bookingDate: booking.bookingDate,
                      timeSlot: booking.timeSlot,
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
                  icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                  label: const Text("Accept", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _toffeeBrown, 
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ] else if (statusUpper == 'CONFIRMED' && isAppointmentTimeReached) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () async {
                    await BookingService().updateBookingStatus(booking.userId, booking.id, 'COMPLETED');

                    await UserNotificationService().logNotification(
                      userId: booking.userId,
                      title: "Appointment Completed!",
                      body: "Your appointment for ${booking.petName} at ${booking.clinicName} on $dateStr has been completed.",
                      type: 'booking',
                    );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("✓ Appointment for ${booking.petName} marked as COMPLETED!"),
                          backgroundColor: Colors.blue.shade700,
                        ),
                      );
                    }
                  }, 
                  icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                  label: const Text("Mark Completed", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700, 
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
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



  Widget _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: _coffeeBean,
      unselectedItemColor: _fadedCopper,
      backgroundColor: Colors.white,
      currentIndex: _currentNavIndex,
      onTap: (index) {
        setState(() {
          _currentNavIndex = index;
        });
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: "Dashboard"),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: "Schedule"),
        BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: "Patients"),
        BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: "Settings"),
      ],
    );
  }
}

/// CustomPainter that draws a diagonal slash line for closed operating days
class DiagonalSlashPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  DiagonalSlashPainter({
    required this.color,
    this.strokeWidth = 1.8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(size.width - 8, 8), Offset(8, size.height - 8), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
