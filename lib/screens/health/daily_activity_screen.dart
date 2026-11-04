import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/pet_model.dart';
import '../../models/health_model.dart';
import '../../providers/user_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../services/health_service.dart';
import '../../utils/unsaved_changes_dialog.dart';
import '../widgets/fringe_header.dart';
import '../widgets/offline_banner.dart';

/// DailyActivityScreen: Daily Wellbeing & Activity Log module.
/// Supports timeline filtering: "Past 3 days", "Past 7 days", "Past 14 days", "Past 30 days", "All time".
class DailyActivityScreen extends StatefulWidget {
  final PetProfile pet;
  const DailyActivityScreen({super.key, required this.pet});

  @override
  State<DailyActivityScreen> createState() => _DailyActivityScreenState();
}

class _DailyActivityScreenState extends State<DailyActivityScreen> {
  static const Color _dustyOlive = Color(0xFF6B705C);
  static const Color _desertSand = Color(0xFFDDBEA9);
  static const Color _drySage = Color(0xFFA5A58D);
  static const Color _darkCharcoal = Color(0xFF2D3142);
  static const Color _errorCoral = Color(0xFFB56576);

  final HealthService _healthService = HealthService();
  String _selectedFilter = 'Past 7 days';

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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

  void _showDialogAlert(BuildContext ctx, String title, String message, IconData icon) {
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Icon(icon, color: _errorCoral, size: 26),
            const SizedBox(width: 8),
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
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _dustyOlive,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text("OK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDiaryDialog(List<DailyActivityLog> existingLogs, [DailyActivityLog? existingLog]) {
    final connectivity = Provider.of<ConnectivityProvider>(context, listen: false);
    if (connectivity.isOffline) {
      ConnectivityProvider.showOfflineReadOnlyDialog(context, action: "Logging daily activity");
      return;
    }

    DateTime logDate = existingLog?.date ?? DateTime.now();
    String? appetite = existingLog?.appetite;
    String? stool = existingLog?.stool;
    String? waterIntake = existingLog?.waterIntake;
    String? activityLevel = existingLog?.activityLevel;
    bool wentForWalk = existingLog?.wentForWalk ?? false;
    final notesCtrl = TextEditingController(text: existingLog?.notes ?? '');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => StatefulBuilder(
        builder: (stContext, setMState) {
          bool checkUnsavedChanges() {
            if (existingLog == null) {
              if (appetite != null || stool != null || waterIntake != null || activityLevel != null || wentForWalk) return true;
              if (notesCtrl.text.trim().isNotEmpty) return true;
              final now = DateTime.now();
              if (logDate.year != now.year || logDate.month != now.month || logDate.day != now.day) return true;
              return false;
            } else {
              if (appetite != existingLog.appetite) return true;
              if (stool != existingLog.stool) return true;
              if (waterIntake != existingLog.waterIntake) return true;
              if (activityLevel != existingLog.activityLevel) return true;
              if (wentForWalk != existingLog.wentForWalk) return true;
              if (notesCtrl.text.trim() != existingLog.notes) return true;
              if (logDate.year != existingLog.date.year || logDate.month != existingLog.date.month || logDate.day != existingLog.date.day) return true;
              return false;
            }
          }

          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;
              if (isSaving || !checkUnsavedChanges()) {
                Navigator.of(stContext).pop();
                return;
              }
              final bool shouldDiscard = await showUnsavedChangesDialog(stContext);
              if (shouldDiscard && stContext.mounted) {
                Navigator.of(stContext).pop();
              }
            },
            child: Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(stContext).viewInsets.bottom),
              child: Container(
                height: MediaQuery.of(stContext).size.height * 0.85,
                decoration: BoxDecoration(
                  color: _desertSand,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: _darkCharcoal.withAlpha(80),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Text(
                        existingLog == null ? "Daily Activity" : "Edit Daily Activity", 
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _darkCharcoal)
                      ),
                      const SizedBox(height: 4),
                      Text(
                        existingLog == null 
                            ? "Record ${widget.pet.name}'s daily appetite, stool, water & energy"
                            : "Update ${widget.pet.name}'s recorded activity entry", 
                        style: TextStyle(color: _darkCharcoal.withAlpha(180), fontSize: 13)
                      ),
                      const SizedBox(height: 18),

                      // Log Date
                      _buildLabel("DIARY DATE", isRequired: true),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: stContext,
                              initialDate: logDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) setMState(() => logDate = picked);
                          },
                          icon: Icon(Icons.calendar_month_rounded, color: _dustyOlive, size: 18),
                          label: Text(
                            DateFormat('EEEE, dd MMM yyyy').format(logDate),
                            style: TextStyle(color: _darkCharcoal, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: BorderSide(color: _darkCharcoal.withAlpha(50)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Appetite
                      _buildLabel("APPETITE", isRequired: true),
                      _buildDropdownField(
                        value: appetite,
                        options: const ['Good', 'Normal', 'Poor'],
                        onChanged: (val) => setMState(() => appetite = val),
                      ),
                      const SizedBox(height: 16),

                      // Stool
                      _buildLabel("STOOL CONDITION", isRequired: true),
                      _buildDropdownField(
                        value: stool,
                        options: const ['Normal', 'Soft', 'Hard', 'None'],
                        onChanged: (val) => setMState(() => stool = val),
                      ),
                      const SizedBox(height: 16),

                      // Water Intake
                      _buildLabel("WATER INTAKE", isRequired: true),
                      _buildDropdownField(
                        value: waterIntake,
                        options: const ['Good', 'Normal', 'Low'],
                        onChanged: (val) => setMState(() => waterIntake = val),
                      ),
                      const SizedBox(height: 16),

                      // Activity Level
                      _buildLabel("ACTIVITY / ENERGY LEVEL", isRequired: true),
                      _buildDropdownField(
                        value: activityLevel,
                        options: const ['Active', 'Normal', 'Lethargic'],
                        onChanged: (val) => setMState(() => activityLevel = val),
                      ),
                      const SizedBox(height: 16),

                      // Walk Checkbox
                      CheckboxListTile(
                        title: Text("Went for a walk / outdoor exercise?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _darkCharcoal)),
                        value: wentForWalk,
                        activeColor: _dustyOlive,
                        onChanged: (val) => setMState(() => wentForWalk = val ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                      const SizedBox(height: 12),

                      // Notes
                      _buildLabel("DAILY NOTES / DIARY ENTRY"),
                      TextField(
                        controller: notesCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: "e.g. Ate full bowl, played in park, slept early...",
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal, fontSize: 13),
                          fillColor: Colors.white,
                          filled: true,
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
                            if (appetite == null || stool == null || waterIntake == null || activityLevel == null) {
                              _showDialogAlert(
                                stContext,
                                "Selection Required",
                                "Please select options for Appetite, Stool Condition, Water Intake, and Activity Level before saving.",
                                Icons.warning_amber_rounded,
                              );
                              return;
                            }

                            // Duplicate Date Check (Avoid overlapping logs on same day)
                            bool alreadyLoggedForDate = existingLogs.any((log) => 
                              _isSameDay(log.date, logDate) && (existingLog == null || log.id != existingLog.id)
                            );
                            if (alreadyLoggedForDate) {
                              _showDialogAlert(
                                stContext,
                                "Entry Already Exists",
                                "A daily activity entry has already been logged for ${widget.pet.name} on ${DateFormat('EEEE, dd MMM yyyy').format(logDate)}.\n\nTo avoid overlapping logs, you cannot log duplicate entries for the same day.",
                                Icons.event_busy_rounded,
                              );
                              return;
                            }

                            setMState(() => isSaving = true);

                            try {
                              final uid = Provider.of<UserProvider>(stContext, listen: false).uid
                                  ?? FirebaseAuth.instance.currentUser?.uid;

                              if (uid == null || uid.isEmpty) {
                                if (stContext.mounted) {
                                  setMState(() => isSaving = false);
                                  ScaffoldMessenger.of(stContext).showSnackBar(
                                    const SnackBar(content: Text("Error: User session invalid. Please log in again.")),
                                  );
                                }
                                return;
                              }

                              final diary = DailyActivityLog(
                                id: existingLog?.id ?? '',
                                petId: widget.pet.id,
                                date: logDate,
                                appetite: appetite!,
                                stool: stool!,
                                waterIntake: waterIntake!,
                                activityLevel: activityLevel!,
                                wentForWalk: wentForWalk,
                                notes: notesCtrl.text.trim(),
                              );

                              if (existingLog == null) {
                                await _healthService.addDailyActivityLog(uid, widget.pet.id, diary);
                              } else {
                                await _healthService.updateDailyActivityLog(uid, widget.pet.id, existingLog.id, diary);
                              }

                              if (stContext.mounted) Navigator.pop(bottomSheetContext);
                            } catch (e) {
                              debugPrint("Error saving daily activity log: $e");
                              if (stContext.mounted) {
                                setMState(() => isSaving = false);
                                ScaffoldMessenger.of(stContext).showSnackBar(
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
                              : Text(existingLog == null ? "Save Daily Entry" : "Update Entry", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String?>(
      initialValue: value,
      decoration: InputDecoration(
        hintText: "-- Please Select --",
        hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal, fontSize: 13),
        fillColor: Colors.white,
        filled: true,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
      dropdownColor: Colors.white,
      style: TextStyle(fontWeight: FontWeight.bold, color: _darkCharcoal, fontSize: 14),
      items: [
        DropdownMenuItem<String?>(
          value: null,
          child: Text(
            "-- Please Select --",
            style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal, fontSize: 13, fontStyle: FontStyle.italic),
          ),
        ),
        ...options.map((opt) => DropdownMenuItem<String?>(
          value: opt,
          child: Text(opt, style: TextStyle(fontWeight: FontWeight.bold, color: _darkCharcoal)),
        )),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildLabel(String text, {bool isRequired = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text.rich(
      TextSpan(
        text: text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _darkCharcoal, letterSpacing: 0.5),
        children: isRequired
            ? [
                const TextSpan(
                  text: " *",
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ]
            : [],
      ),
    ),
  );

  List<DailyActivityLog> _filterLogs(List<DailyActivityLog> logs) {
    final now = DateTime.now();
    if (_selectedFilter == 'Past 3 days') {
      final cutoff = now.subtract(const Duration(days: 3));
      return logs.where((l) => l.date.isAfter(cutoff)).toList();
    } else if (_selectedFilter == 'Past 7 days') {
      final cutoff = now.subtract(const Duration(days: 7));
      return logs.where((l) => l.date.isAfter(cutoff)).toList();
    } else if (_selectedFilter == 'Past 14 days') {
      final cutoff = now.subtract(const Duration(days: 14));
      return logs.where((l) => l.date.isAfter(cutoff)).toList();
    } else if (_selectedFilter == 'Past 30 days') {
      final cutoff = now.subtract(const Duration(days: 30));
      return logs.where((l) => l.date.isAfter(cutoff)).toList();
    }
    return logs;
  }

  @override
  Widget build(BuildContext context) {
    final uid = Provider.of<UserProvider>(context).uid ?? "";

    return Scaffold(
      backgroundColor: _drySage,
      body: Column(
        children: [
          FringeHeader(
            title: "Daily Activity",
            subtitle: "${widget.pet.name} • Wellbeing Log",
            onBack: () => Navigator.pop(context),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(40),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withAlpha(80), width: 1),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedFilter,
                  dropdownColor: _dustyOlive,
                  icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white, size: 16),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                  isDense: true,
                  items: const ['Past 3 days', 'Past 7 days', 'Past 14 days', 'Past 30 days', 'All time']
                      .map((f) => DropdownMenuItem<String>(
                            value: f,
                            child: Text(f),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedFilter = val);
                    }
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<DailyActivityLog>>(
              stream: _healthService.streamDailyActivityLogs(uid, widget.pet.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }

                final allLogs = snapshot.data ?? [];
                final filteredLogs = _filterLogs(allLogs);

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const OfflineBanner(margin: EdgeInsets.only(bottom: 12)),
                      // Add Diary Button
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: () => _showAddDiaryDialog(allLogs),
                          icon: const Icon(Icons.add, size: 18, color: Colors.white),
                          label: const Text("Add Diary", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _darkCharcoal,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (filteredLogs.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(color: Colors.white.withAlpha(200), borderRadius: BorderRadius.circular(20)),
                          child: Column(
                            children: [
                              Icon(Icons.event_note_rounded, size: 48, color: _dustyOlive),
                              const SizedBox(height: 12),
                              Text(
                                _selectedFilter.startsWith("Past")
                                    ? "No Diary for $_selectedFilter"
                                    : "No Diary Logged Yet", 
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _darkCharcoal),
                              ),
                              const SizedBox(height: 4),
                              Text("Tap Add Diary to create a daily wellbeing entry.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredLogs.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final log = filteredLogs[index];
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
                                      Expanded(
                                        child: Text(
                                          DateFormat('EEEE, dd MMM yyyy').format(log.date),
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _darkCharcoal),
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.edit_note_rounded, size: 20, color: _dustyOlive),
                                            onPressed: () => _showAddDiaryDialog(allLogs, log),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            tooltip: "Edit Entry",
                                          ),
                                          const SizedBox(width: 4),
                                          IconButton(
                                            icon: Icon(Icons.delete_outline_rounded, size: 18, color: _errorCoral),
                                            onPressed: () async {
                                              final connectivity = Provider.of<ConnectivityProvider>(context, listen: false);
                                              if (connectivity.isOffline) {
                                                ConnectivityProvider.showOfflineReadOnlyDialog(context, action: "Deleting daily activity logs");
                                                return;
                                              }
                                              String dateStr = DateFormat('EEEE, dd MMM yyyy').format(log.date);
                                              bool confirm = await _showDeleteConfirmationDialog(
                                                context,
                                                title: "Delete",
                                                message: "Are you sure you want to delete the daily activity log for $dateStr? This action cannot be undone.",
                                              );
                                              if (confirm) {
                                                await _healthService.deleteDailyActivityLog(uid, widget.pet.id, log.id);
                                              }
                                            },
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            tooltip: "Delete Entry",
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _badgeTile("Appetite", log.appetite, _dustyOlive),
                                      _badgeTile("Stool", log.stool, _dustyOlive),
                                      _badgeTile("Water", log.waterIntake, _dustyOlive),
                                      _badgeTile("Activity", log.activityLevel, _dustyOlive),
                                      _badgeTile("Walk", log.wentForWalk ? "Yes" : "No", log.wentForWalk ? Colors.green.shade800 : Colors.grey),
                                    ],
                                  ),
                                  if (log.notes.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Text(
                                      "Notes: ${log.notes}",
                                      style: TextStyle(fontSize: 12, color: _darkCharcoal, fontStyle: FontStyle.italic),
                                    ),
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

  Widget _badgeTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(60), width: 1),
      ),
      child: Text(
        "$label: $value",
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
// timestamp update: 1740000001
