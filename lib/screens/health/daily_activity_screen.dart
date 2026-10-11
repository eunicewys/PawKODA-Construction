import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/pet_model.dart';
import '../../models/health_model.dart';
import '../../providers/user_provider.dart';
import '../../services/health_service.dart';
import '../widgets/fringe_header.dart';

/// DailyActivityScreen: Daily Wellbeing & Activity Diary for a pet.
/// Includes timeline filtering: "Past 3 days", "Past 7 days", "Past 14 days", "Past 30 days", "All time".
class DailyActivityScreen extends StatefulWidget {
  final PetProfile pet;
  const DailyActivityScreen({super.key, required this.pet});

  @override
  State<DailyActivityScreen> createState() => _DailyActivityScreenState();
}

class _DailyActivityScreenState extends State<DailyActivityScreen> {
  final Color _dustyOlive = const Color(0xFF6B705C);
  final Color _powderPetal = const Color(0xFFFFE8D6);
  final Color _desertSand = const Color(0xFFDDBEA9);
  final Color _drySage = const Color(0xFFA5A58D);
  final Color _darkCharcoal = const Color(0xFF2D3142);
  final Color _errorCoral = const Color(0xFFB56576);

  final HealthService _healthService = HealthService();
  String _selectedFilter = 'Past 7 days'; // Past 3 days, Past 7 days, Past 14 days, Past 30 days, All time

  void _showAddDiaryDialog() {
    DateTime logDate = DateTime.now();
    String appetite = 'Good';
    String stool = 'Normal';
    String waterIntake = 'Good';
    String activityLevel = 'Active';
    bool wentForWalk = true;
    final notesCtrl = TextEditingController();
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
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: _desertSand,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Daily Activity Diary Log", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _darkCharcoal)),
                    const SizedBox(height: 4),
                    Text("Record ${widget.pet.name}'s daily appetite, stool, water & energy", style: TextStyle(color: _darkCharcoal.withAlpha(180), fontSize: 13)),
                    const SizedBox(height: 18),

                    // Log Date
                    _buildLabel("DIARY DATE"),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
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
                    _buildLabel("APPETITE"),
                    _buildChoiceRow(['Good', 'Normal', 'Poor'], appetite, (val) => setMState(() => appetite = val)),
                    const SizedBox(height: 16),

                    // Stool
                    _buildLabel("STOOL CONDITION"),
                    _buildChoiceRow(['Normal', 'Soft', 'Hard', 'None'], stool, (val) => setMState(() => stool = val)),
                    const SizedBox(height: 16),

                    // Water Intake
                    _buildLabel("WATER INTAKE"),
                    _buildChoiceRow(['Good', 'Normal', 'Low'], waterIntake, (val) => setMState(() => waterIntake = val)),
                    const SizedBox(height: 16),

                    // Activity Level
                    _buildLabel("ACTIVITY / ENERGY LEVEL"),
                    _buildChoiceRow(['Active', 'Normal', 'Lethargic'], activityLevel, (val) => setMState(() => activityLevel = val)),
                    const SizedBox(height: 16),

                    // Walk Checkbox
                    CheckboxListTile(
                      title: Text("Went for a walk / outdoor exercise?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _darkCharcoal)),
                      value: wentForWalk,
                      activeColor: _dustyOlive,
                      onChanged: (val) => setMState(() => wentForWalk = val!),
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

                            final diary = DailyActivityLog(
                              id: '',
                              petId: widget.pet.id,
                              date: logDate,
                              appetite: appetite,
                              stool: stool,
                              waterIntake: waterIntake,
                              activityLevel: activityLevel,
                              wentForWalk: wentForWalk,
                              notes: notesCtrl.text.trim(),
                            );

                            await _healthService.addDailyActivityLog(uid, widget.pet.id, diary);
                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            debugPrint("Error saving daily activity log: $e");
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
                          : const Text("Save Daily Entry", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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

  Widget _buildChoiceRow(List<String> options, String current, Function(String) onSelect) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((opt) {
          final isSel = current == opt;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(opt, style: TextStyle(color: isSel ? Colors.white : _darkCharcoal, fontWeight: FontWeight.bold, fontSize: 13)),
              selected: isSel,
              selectedColor: opt == 'Poor' || opt == 'Lethargic' ? _errorCoral : _dustyOlive,
              backgroundColor: Colors.white,
              onSelected: (val) {
                if (val) onSelect(opt);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _darkCharcoal, letterSpacing: 0.5)),
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
    return logs; // All time
  }

  @override
  Widget build(BuildContext context) {
    final uid = Provider.of<UserProvider>(context).uid ?? "";

    return Scaffold(
      backgroundColor: _drySage,
      body: Column(
        children: [
          FringeHeader(
            title: "Daily Activity Diary",
            subtitle: "${widget.pet.name} • Wellbeing Log",
            onBack: () => Navigator.pop(context),
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
                      // Header Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10)],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: _powderPetal, shape: BoxShape.circle),
                              child: Icon(Icons.edit_note_rounded, color: _dustyOlive, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Daily Wellbeing Diary", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _darkCharcoal)),
                                  Text("Track appetite, stool, water & walk activity", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Time Filters
                      const Text("TIMELINE FILTER", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 0.8)),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['Past 3 days', 'Past 7 days', 'Past 14 days', 'Past 30 days', 'All time'].map((f) {
                            final isSel = _selectedFilter == f;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(f, style: TextStyle(color: isSel ? Colors.white : _darkCharcoal, fontWeight: FontWeight.bold, fontSize: 12)),
                                selected: isSel,
                                selectedColor: _dustyOlive,
                                backgroundColor: Colors.white.withAlpha(200),
                                showCheckmark: false,
                                onSelected: (val) {
                                  if (val) setState(() => _selectedFilter = f);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("DIARY ENTRIES (${filteredLogs.length})", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.8)),
                          ElevatedButton.icon(
                            onPressed: () => _showAddDiaryDialog(),
                            icon: const Icon(Icons.add, size: 16, color: Colors.white),
                            label: const Text("+ Log Today", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _darkCharcoal,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (filteredLogs.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(color: Colors.white.withAlpha(200), borderRadius: BorderRadius.circular(20)),
                          child: Column(
                            children: [
                              Icon(Icons.event_note_rounded, size: 48, color: _dustyOlive),
                              const SizedBox(height: 12),
                              Text("No Diary Entries for $_selectedFilter", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _darkCharcoal)),
                              const SizedBox(height: 4),
                              Text("Tap + Log Today to create a daily wellbeing entry.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
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
                                      Text(
                                        DateFormat('EEEE, dd MMM yyyy').format(log.date),
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _darkCharcoal),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete_outline_rounded, size: 18, color: _errorCoral),
                                        onPressed: () async {
                                          await _healthService.deleteDailyActivityLog(uid, widget.pet.id, log.id);
                                        },
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
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
                                      _badgeTile("Walk", log.wentForWalk ? "Yes 🐾" : "No", log.wentForWalk ? Colors.green.shade800 : Colors.grey),
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
