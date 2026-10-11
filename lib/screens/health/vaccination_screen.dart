import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/pet_model.dart';
import '../../models/health_model.dart';
import '../../providers/user_provider.dart';
import '../../services/health_service.dart';
import '../widgets/fringe_header.dart';

/// VaccinationScreen: Log past & future vaccine / deworming dosages and set reminders.
class VaccinationScreen extends StatefulWidget {
  final PetProfile pet;
  const VaccinationScreen({super.key, required this.pet});

  @override
  State<VaccinationScreen> createState() => _VaccinationScreenState();
}

class _VaccinationScreenState extends State<VaccinationScreen> {
  final Color _dustyOlive = const Color(0xFF6B705C);
  final Color _powderPetal = const Color(0xFFFFE8D6);
  final Color _desertSand = const Color(0xFFDDBEA9);
  final Color _drySage = const Color(0xFFA5A58D);
  final Color _darkCharcoal = const Color(0xFF2D3142);
  final Color _errorCoral = const Color(0xFFB56576);

  final HealthService _healthService = HealthService();

  void _showAddDoseDialog() {
    final nameCtrl = TextEditingController();
    final vetCtrl = TextEditingController();
    final dosageCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    
    String selectedType = 'Vaccine'; // Vaccine or Deworming
    DateTime dateGiven = DateTime.now();
    DateTime? dueDate = DateTime.now().add(const Duration(days: 180)); // Default 6 months
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
                      "Log Vaccine / Deworming",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _darkCharcoal),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Record dosage details and schedule future reminders for ${widget.pet.name}",
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
                        fillColor: Colors.white,
                        filled: true,
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      style: TextStyle(fontWeight: FontWeight.bold, color: _darkCharcoal),
                    ),
                    const SizedBox(height: 14),

                    // Date Given
                    _buildLabel("DATE ADMINISTERED"),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: dateGiven,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now().add(const Duration(days: 30)),
                          );
                          if (picked != null) setMState(() => dateGiven = picked);
                        },
                        icon: Icon(Icons.calendar_today_rounded, color: _dustyOlive, size: 18),
                        label: Text(
                          DateFormat('dd MMM yyyy').format(dateGiven),
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
                                  hintText: "e.g. Dr. Tan / Paw Clinic",
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
                              _buildLabel("DOSAGE (e.g. 1 ml / 1 tab)"),
                              TextField(
                                controller: dosageCtrl,
                                decoration: InputDecoration(
                                  hintText: "e.g. 1 ml",
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

                    // Future Next Due Date (Reminder)
                    _buildLabel("FUTURE NEXT DUE DATE (REMINDER)"),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: dueDate ?? DateTime.now().add(const Duration(days: 180)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 1095)), // 3 years
                          );
                          if (picked != null) setMState(() => dueDate = picked);
                        },
                        icon: Icon(Icons.notifications_active_rounded, color: _dustyOlive, size: 18),
                        label: Text(
                          dueDate == null ? "Set Future Due Date" : "Next Due: ${DateFormat('dd MMM yyyy').format(dueDate!)}",
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

                    // Notes
                    _buildLabel("NOTES"),
                    TextField(
                      controller: notesCtrl,
                      decoration: InputDecoration(
                        hintText: "Batch no, reaction, notes...",
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
                              id: '',
                              petId: widget.pet.id,
                              type: selectedType,
                              doseName: nameCtrl.text.trim(),
                              dateGiven: dateGiven,
                              vetName: vetCtrl.text.trim().isEmpty ? 'Central Vet' : vetCtrl.text.trim(),
                              dosage: dosageCtrl.text.trim().isEmpty ? '1 dose' : dosageCtrl.text.trim(),
                              dueDate: dueDate,
                              isCompleted: true,
                              notes: notesCtrl.text.trim(),
                            );

                            await _healthService.addVaccination(uid, widget.pet.id, record);
                            if (context.mounted) Navigator.pop(context);
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
                          : const Text("Log Dose & Enable Reminder", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
            title: "Vaccines & Deworming",
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

                final records = snapshot.data ?? [];

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
                              child: Icon(Icons.vaccines_rounded, color: _dustyOlive, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Immunization & Parasite Log", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _darkCharcoal)),
                                  Text("Track vaccinations, dewormers & due dates", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("DOSAGE RECORDS (${records.length})", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.8)),
                          ElevatedButton.icon(
                            onPressed: () => _showAddDoseDialog(),
                            icon: const Icon(Icons.add, size: 16, color: Colors.white),
                            label: const Text("+ Log Dose", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _darkCharcoal,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (records.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(color: Colors.white.withAlpha(200), borderRadius: BorderRadius.circular(20)),
                          child: Column(
                            children: [
                              Icon(Icons.vaccines_rounded, size: 48, color: _dustyOlive),
                              const SizedBox(height: 12),
                              Text("No Dosage Records Yet", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _darkCharcoal)),
                              const SizedBox(height: 4),
                              Text("Tap + Log Dose to record vaccines or dewormers.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: records.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final rec = records[index];
                            final isDueSoon = rec.dueDate != null && rec.dueDate!.isBefore(DateTime.now().add(const Duration(days: 30)));
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
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: rec.type == 'Vaccine' ? Colors.blue.withAlpha(30) : Colors.orange.withAlpha(30),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          rec.type.toUpperCase(),
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: rec.type == 'Vaccine' ? Colors.blue.shade800 : Colors.orange.shade800),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          rec.doseName,
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _darkCharcoal),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete_outline_rounded, size: 18, color: _errorCoral),
                                        onPressed: () async {
                                          await _healthService.deleteVaccination(uid, widget.pet.id, rec.id);
                                        },
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
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
                                  if (rec.dueDate != null) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isDueSoon ? _errorCoral.withAlpha(20) : const Color(0xFFFFE8D6),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: isDueSoon ? _errorCoral : _dustyOlive, width: 1),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.notifications_active_rounded, size: 16, color: isDueSoon ? _errorCoral : _dustyOlive),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              "⏰ Upcoming Reminder: Next Due ${DateFormat('dd MMM yyyy').format(rec.dueDate!)}",
                                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDueSoon ? _errorCoral : _darkCharcoal),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (rec.notes.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(rec.notes, style: TextStyle(fontSize: 12, color: _darkCharcoal, fontStyle: FontStyle.italic)),
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
