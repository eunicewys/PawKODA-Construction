import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/pet_model.dart';
import '../../models/health_model.dart';
import '../../providers/user_provider.dart';
import '../../services/health_service.dart';
import '../../services/notification_service.dart';
import '../../services/user_notification_service.dart';
import '../widgets/fringe_header.dart';

/// VaccinationScreen: Log past immunization records (syncs to Passport)
/// and schedule future upcoming dosage reminders with daily local phone notifications starting 3 days prior at 09:00 AM.
class VaccinationScreen extends StatefulWidget {
  final PetProfile pet;
  const VaccinationScreen({super.key, required this.pet});

  @override
  State<VaccinationScreen> createState() => _VaccinationScreenState();
}

class _VaccinationScreenState extends State<VaccinationScreen> {
  final Color _dustyOlive = const Color(0xFF6B705C);
  final Color _desertSand = const Color(0xFFDDBEA9);
  final Color _drySage = const Color(0xFFA5A58D);
  final Color _darkCharcoal = const Color(0xFF2D3142);
  final Color _errorCoral = const Color(0xFFB56576);
  final Color _sageGreenAlert = const Color(0xFF759C86); // Morandi Sage Green SnackBar color

  final HealthService _healthService = HealthService();

  /// Show iOS/Android Alarm-style scroll wheel picker for Date selection
  Future<DateTime?> _showScrollDatePicker({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    DateTime tempDate = initialDate;
    DateTime? result = initialDate;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext modalContext) {
        return Container(
          height: 280,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(modalContext),
                      child: Text("Cancel", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                    Text(
                      "Set Date",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _darkCharcoal),
                    ),
                    TextButton(
                      onPressed: () {
                        result = tempDate;
                        Navigator.pop(modalContext);
                      },
                      child: Text("Done", style: TextStyle(color: _dustyOlive, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: initialDate.isBefore(firstDate)
                      ? firstDate
                      : (initialDate.isAfter(lastDate) ? lastDate : initialDate),
                  minimumDate: firstDate,
                  maximumDate: lastDate,
                  onDateTimeChanged: (DateTime newDate) {
                    tempDate = newDate;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    return result;
  }

  void _showAddDoseDialog({bool isUpcoming = false, VaccinationRecord? existingRecord}) {
    final nameCtrl = TextEditingController(text: existingRecord?.doseName ?? '');
    final vetCtrl = TextEditingController(text: existingRecord?.vetName ?? '');
    final dosageCtrl = TextEditingController(text: existingRecord?.dosage ?? '');
    final notesCtrl = TextEditingController(text: existingRecord?.notes ?? '');
    
    String selectedType = existingRecord?.type ?? 'Vaccine';
    DateTime selectedDate = existingRecord?.dueDate ?? existingRecord?.dateGiven ?? (
      isUpcoming 
          ? DateTime.now().add(const Duration(days: 1)) 
          : DateTime.now()
    );

    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setMState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.82,
              decoration: BoxDecoration(
                color: _desertSand,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      existingRecord != null 
                          ? (isUpcoming ? "Edit Upcoming Reminder" : "Edit Past Dosage Record")
                          : (isUpcoming ? "Schedule Upcoming Dosage" : "Log Past Dosage Record"),
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _darkCharcoal),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isUpcoming 
                          ? "Set a future reminder for upcoming vaccine or deworming for ${widget.pet.name}"
                          : "Record past dosage details (syncs to Pet Passport for ${widget.pet.name})",
                      style: TextStyle(color: _darkCharcoal.withAlpha(180), fontSize: 13),
                    ),
                    const SizedBox(height: 18),

                    // Type Choice (Vaccine vs Deworming)
                    _buildLabel("DOSE TYPE"),
                    Row(
                      children: ['Vaccine', 'Deworming'].map((t) {
                        final isSel = selectedType == t;
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: ChoiceChip(
                            label: Text(t, style: TextStyle(color: isSel ? Colors.white : _darkCharcoal, fontWeight: FontWeight.bold, fontSize: 14)),
                            selected: isSel,
                            selectedColor: _dustyOlive,
                            backgroundColor: Colors.white,
                            onSelected: (val) {
                              if (val) setMState(() => selectedType = t);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Dose / Vaccine Name
                    _buildLabel("VACCINE / DEWORM NAME"),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        hintText: selectedType == 'Vaccine' ? "e.g. DHPP Core, Rabies..." : "e.g. Bravecto, Drontal...",
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal, fontSize: 13),
                        fillColor: Colors.white,
                        filled: true,
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      style: TextStyle(fontWeight: FontWeight.bold, color: _darkCharcoal),
                    ),
                    const SizedBox(height: 14),

                    // Date Selector (Scroll Wheel Picker)
                    _buildLabel(isUpcoming ? "SCHEDULED DUE DATE" : "DATE ADMINISTERED (PAST OR TODAY)"),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final now = DateTime.now();
                          final firstDate = isUpcoming ? now.add(const Duration(days: 1)) : DateTime(2000);
                          final lastDate = isUpcoming ? now.add(const Duration(days: 3650)) : now;

                          final picked = await _showScrollDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: firstDate,
                            lastDate: lastDate,
                          );
                          if (picked != null) setMState(() => selectedDate = picked);
                        },
                        icon: Icon(
                          isUpcoming ? Icons.notifications_active_rounded : Icons.calendar_today_rounded, 
                          color: _dustyOlive, 
                          size: 18
                        ),
                        label: Text(
                          DateFormat('dd MMM yyyy').format(selectedDate),
                          style: TextStyle(color: _darkCharcoal, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: BorderSide(color: _darkCharcoal.withAlpha(50)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Vet Name & Dosage
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel("VET / CLINIC NAME"),
                              TextField(
                                controller: vetCtrl,
                                decoration: InputDecoration(
                                  hintText: "e.g. Paw Clinic",
                                  hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal, fontSize: 13),
                                  fillColor: Colors.white,
                                  filled: true,
                                  isDense: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel("DOSAGE"),
                              TextField(
                                controller: dosageCtrl,
                                decoration: InputDecoration(
                                  hintText: "e.g. 1 ml / 1 tab",
                                  hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal, fontSize: 13),
                                  fillColor: Colors.white,
                                  filled: true,
                                  isDense: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Notes
                    _buildLabel("NOTES / BATCH NO"),
                    TextField(
                      controller: notesCtrl,
                      decoration: InputDecoration(
                        hintText: "Batch no, reaction, notes...",
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal, fontSize: 13),
                        fillColor: Colors.white,
                        filled: true,
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : () async {
                          if (nameCtrl.text.trim().isEmpty) return;
                          setMState(() => isSaving = true);

                          try {
                            final uid = Provider.of<UserProvider>(context, listen: false).uid
                                ?? FirebaseAuth.instance.currentUser?.uid;

                            if (uid == null || uid.isEmpty) {
                              if (context.mounted) {
                                setMState(() => isSaving = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Error: User session invalid. Please log in again.")),
                                );
                              }
                              return;
                            }

                            final record = VaccinationRecord(
                              id: existingRecord?.id ?? '',
                              petId: widget.pet.id,
                              type: selectedType,
                              doseName: nameCtrl.text.trim(),
                              dateGiven: selectedDate,
                              vetName: vetCtrl.text.trim().isEmpty ? 'Central Vet' : vetCtrl.text.trim(),
                              dosage: dosageCtrl.text.trim().isEmpty ? '1 dose' : dosageCtrl.text.trim(),
                              dueDate: isUpcoming ? selectedDate : null,
                              isCompleted: !isUpcoming,
                              notes: notesCtrl.text.trim(),
                              reminderTime: "09:00",
                            );

                            String recordId = existingRecord?.id ?? '';
                            if (existingRecord == null) {
                              recordId = await _healthService.addVaccination(uid, widget.pet.id, record);
                            } else {
                              await _healthService.updateVaccination(uid, widget.pet.id, existingRecord.id, record);
                            }

                            // Trigger On-Phone Notification Logic
                            final int notificationTagHash = recordId.hashCode;

                            if (isUpcoming) {
                              await NotificationService().scheduleHealthReminder(
                                baseId: notificationTagHash,
                                id: notificationTagHash,
                                petName: widget.pet.name,
                                treatmentName: nameCtrl.text.trim(),
                                type: selectedType,
                                nextDueDate: selectedDate,
                              );

                              await UserNotificationService().logNotification(
                                userId: uid,
                                title: "Health Reminder Set: ${widget.pet.name} 🐾",
                                body: "${selectedType} (${nameCtrl.text.trim()}) scheduled for ${DateFormat('dd MMM yyyy').format(selectedDate)}.",
                                type: selectedType.toLowerCase() == 'deworming' ? 'deworming' : 'vaccine',
                              );
                            } else if (existingRecord != null) {
                              // If converting an upcoming item to completed/past, cancel old notifications
                              await NotificationService().cancelReminder(notificationTagHash);
                            }

                            if (context.mounted) {
                              Navigator.pop(context);

                              if (isUpcoming) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: _sageGreenAlert,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    content: Row(
                                      children: [
                                        const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 20),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            "Reminder set! Daily 9:00 AM alerts enabled starting 3 days before due date.",
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            debugPrint("Error saving vaccination: $e");
                            if (context.mounted) {
                              setMState(() => isSaving = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Failed to save: $e")),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _dustyOlive,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: isSaving
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              existingRecord != null 
                                  ? (isUpcoming ? "Update Reminder" : "Update Record")
                                  : (isUpcoming ? "Enable Upcoming Reminder" : "Save Record to Passport"), 
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                            ),
                      ),
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

  Future<bool> _showDeleteConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: _errorCoral.withAlpha(30), shape: BoxShape.circle),
              child: Icon(Icons.delete_outline_rounded, color: _errorCoral, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _darkCharcoal),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(fontSize: 14, color: _darkCharcoal, height: 1.3),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _errorCoral,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _darkCharcoal, letterSpacing: 0.5)),
  );

  @override
  Widget build(BuildContext context) {
    final uid = Provider.of<UserProvider>(context).uid ?? "";

    return Scaffold(
      backgroundColor: _drySage,
      body: Column(
        children: [
          FringeHeader(
            title: "Vax & Deworm",
            subtitle: "${widget.pet.name} • Dosage Log & Reminders",
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: StreamBuilder<List<VaccinationRecord>>(
              stream: _healthService.streamVaccinations(uid, widget.pet.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }

                final allRecords = snapshot.data ?? [];
                final DateTime now = DateTime.now();

                // Partition Records
                // Past Dosage Records: isCompleted == true OR (dueDate == null && dateGiven <= now)
                final pastRecords = allRecords.where((r) {
                  return r.isCompleted || r.dueDate == null || r.dateGiven.isBefore(now) || (r.dateGiven.year == now.year && r.dateGiven.month == now.month && r.dateGiven.day == now.day);
                }).toList();

                // Upcoming Dosages: isCompleted == false OR (dueDate != null && dueDate > now)
                final upcomingRecords = allRecords.where((r) {
                  return !r.isCompleted && r.dueDate != null && r.dueDate!.isAfter(now);
                }).toList();

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // -----------------------------------------------------------------
                      // SECTION 1: DOSAGE RECORDS (PAST / PASSED DOSES - SYNCS TO PASSPORT)
                      // -----------------------------------------------------------------
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("DOSAGE RECORDS (${pastRecords.length})", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.8)),
                          ElevatedButton.icon(
                            onPressed: () => _showAddDoseDialog(isUpcoming: false),
                            icon: const Icon(Icons.add, size: 14, color: Colors.white),
                            label: const Text("Add Record", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _darkCharcoal,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      if (pastRecords.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(color: Colors.white.withAlpha(200), borderRadius: BorderRadius.circular(20)),
                          child: Column(
                            children: [
                              Icon(Icons.vaccines_rounded, size: 40, color: _dustyOlive),
                              const SizedBox(height: 10),
                              Text("No Past Dosage Records", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _darkCharcoal)),
                              const SizedBox(height: 4),
                              Text("Tap Add Record to log past vaccines or dewormers.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: pastRecords.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final rec = pastRecords[index];
                            bool isVaccine = rec.type.toLowerCase() == 'vaccine';

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: _dustyOlive.withAlpha(80), width: 1.2),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isVaccine ? Colors.blue.withAlpha(30) : Colors.orange.withAlpha(30),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          rec.type.toUpperCase(),
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isVaccine ? Colors.blue.shade800 : Colors.orange.shade800),
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            onTap: () => _showAddDoseDialog(isUpcoming: false, existingRecord: rec),
                                            borderRadius: BorderRadius.circular(6),
                                            child: Padding(
                                              padding: const EdgeInsets.all(3),
                                              child: Icon(Icons.edit_note_rounded, size: 22, color: _dustyOlive),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          InkWell(
                                            onTap: () async {
                                              bool confirm = await _showDeleteConfirmationDialog(
                                                context,
                                                title: "Delete",
                                                message: "Are you sure you want to delete '${rec.doseName}'? This action cannot be undone.",
                                              );
                                              if (confirm) {
                                                await NotificationService().cancelReminder(rec.id.hashCode);
                                                await _healthService.deleteVaccination(uid, widget.pet.id, rec.id);
                                              }
                                            },
                                            borderRadius: BorderRadius.circular(6),
                                            child: Padding(
                                              padding: const EdgeInsets.all(3),
                                              child: Icon(Icons.delete_outline_rounded, size: 20, color: _errorCoral),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    rec.doseName,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _darkCharcoal),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Given: ${DateFormat('dd MMM yyyy').format(rec.dateGiven)}", style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withAlpha(30),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text("✓ PASSED", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green)),
                                      ),
                                    ],
                                  ),
                                  if (rec.vetName.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text("Vet / Clinic: ${rec.vetName} • Dosage: ${rec.dosage}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                  ],
                                  if (rec.notes.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text("Notes: ${rec.notes}", style: TextStyle(fontSize: 12, color: _darkCharcoal, fontStyle: FontStyle.italic)),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 36),

                      // -----------------------------------------------------------------
                      // SECTION 2: UPCOMING DOSAGES & REMINDERS (FUTURE DATES ONLY)
                      // -----------------------------------------------------------------
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("UPCOMING (${upcomingRecords.length})", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.8)),
                          ElevatedButton.icon(
                            onPressed: () => _showAddDoseDialog(isUpcoming: true),
                            icon: const Icon(Icons.add, size: 14, color: Colors.white),
                            label: const Text("Add Reminder", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _darkCharcoal,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      if (upcomingRecords.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(color: Colors.white.withAlpha(200), borderRadius: BorderRadius.circular(20)),
                          child: Column(
                            children: [
                              Icon(Icons.notifications_active_rounded, size: 40, color: _dustyOlive),
                              const SizedBox(height: 10),
                              Text("No Upcoming Reminders", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _darkCharcoal)),
                              const SizedBox(height: 4),
                              Text("Tap Add Reminder to set a future due date alert.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: upcomingRecords.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final rec = upcomingRecords[index];
                            bool isVaccine = rec.type.toLowerCase() == 'vaccine';

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: _errorCoral.withAlpha(120), width: 1.2),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isVaccine ? Colors.blue.withAlpha(30) : Colors.orange.withAlpha(30),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          rec.type.toUpperCase(),
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isVaccine ? Colors.blue.shade800 : Colors.orange.shade800),
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            onTap: () => _showAddDoseDialog(isUpcoming: true, existingRecord: rec),
                                            borderRadius: BorderRadius.circular(6),
                                            child: Padding(
                                              padding: const EdgeInsets.all(3),
                                              child: Icon(Icons.edit_note_rounded, size: 22, color: _dustyOlive),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          InkWell(
                                            onTap: () async {
                                              bool confirm = await _showDeleteConfirmationDialog(
                                                context,
                                                title: "Delete",
                                                message: "Are you sure you want to delete the reminder for '${rec.doseName}'? This action cannot be undone.",
                                              );
                                              if (confirm) {
                                                await NotificationService().cancelReminder(rec.id.hashCode);
                                                await _healthService.deleteVaccination(uid, widget.pet.id, rec.id);
                                              }
                                            },
                                            borderRadius: BorderRadius.circular(6),
                                            child: Padding(
                                              padding: const EdgeInsets.all(3),
                                              child: Icon(Icons.delete_outline_rounded, size: 20, color: _errorCoral),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    rec.doseName,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _darkCharcoal),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFE8D6),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: _dustyOlive, width: 1),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.notifications_active_rounded, size: 16, color: _dustyOlive),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            "Upcoming Reminder: Next Due ${DateFormat('dd MMM yyyy').format(rec.dueDate ?? rec.dateGiven)} (Daily 9:00 AM Alert)",
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _darkCharcoal),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (rec.vetName.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text("Scheduled Vet / Clinic: ${rec.vetName} • Dosage: ${rec.dosage}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                  ],
                                  if (rec.notes.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text("Notes: ${rec.notes}", style: TextStyle(fontSize: 12, color: _darkCharcoal, fontStyle: FontStyle.italic)),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 80),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
