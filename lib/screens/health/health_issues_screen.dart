import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/pet_model.dart';
import '../../models/disease_model.dart';
import '../../models/health_model.dart';
import '../../providers/user_provider.dart';
import '../../services/health_service.dart';
import '../../services/pet_service.dart';
import '../widgets/fringe_header.dart';

/// HealthIssuesScreen: Log & track diseases / medical conditions for a pet.
/// Fully connected with the Pet Passport.
class HealthIssuesScreen extends StatefulWidget {
  final PetProfile pet;
  const HealthIssuesScreen({super.key, required this.pet});

  @override
  State<HealthIssuesScreen> createState() => _HealthIssuesScreenState();
}

class _HealthIssuesScreenState extends State<HealthIssuesScreen> {
  final Color _dustyOlive = const Color(0xFF6B705C);
  final Color _powderPetal = const Color(0xFFFFE8D6);
  final Color _desertSand = const Color(0xFFDDBEA9);
  final Color _drySage = const Color(0xFFA5A58D);
  final Color _darkCharcoal = const Color(0xFF2D3142);
  final Color _errorCoral = const Color(0xFFB56576);

  final HealthService _healthService = HealthService();

  DiseaseType _mapDiseaseTitleToType(String title) {
    String t = title.toLowerCase();
    if (t.contains('obesity') || t.contains('overweight') || t.contains('weight loss')) {
      return DiseaseType.obesity;
    }
    if (t.contains('kidney') || t.contains('ckd') || t.contains('renal')) {
      return DiseaseType.ckd;
    }
    if (t.contains('diabet') || t.contains('sugar')) {
      return DiseaseType.diabetesMellitus;
    }
    if (t.contains('pancreat')) {
      return DiseaseType.pancreatitis;
    }
    if (t.contains('urinary') || t.contains('flutd') || t.contains('urolith') || t.contains('bladder') || t.contains('stone')) {
      return DiseaseType.urinaryHealth;
    }
    return DiseaseType.none;
  }

  void _showAddIssueDialog([HealthIssue? existingIssue]) {
    final titleCtrl = TextEditingController(text: existingIssue?.title ?? '');
    final notesCtrl = TextEditingController(text: existingIssue?.notes ?? '');
    DateTime selectedDate = existingIssue?.diagnosisDate ?? DateTime.now();
    String severity = existingIssue?.severity ?? 'Mild';
    String status = existingIssue?.status ?? 'Active';
    bool isSaving = false;

    // Common Diseases List
    final List<String> commonDiseases = [
      "Obesity / Weight Loss",
      "Chronic Kidney Disease (CKD)",
      "Diabetes Mellitus",
      "Pancreatitis",
      "Urinary Issue / FLUTD",
      "Ear Infection",
      "Skin Allergies",
      "Dental Disease",
      "Arthritis",
      "Fleas / Ticks",
      "Others"
    ];

    bool isOtherSelected = existingIssue != null && !commonDiseases.contains(existingIssue.title) && existingIssue.title.isNotEmpty;
    if (isOtherSelected) {
      titleCtrl.text = existingIssue.title;
    }

    String? selectedCommon = isOtherSelected ? "Others" : (existingIssue != null && existingIssue.title.isNotEmpty ? existingIssue.title : null);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setMState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.75,
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
                      existingIssue == null ? "Log Health Issue" : "Edit Health Issue",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _darkCharcoal),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Record diseases or medical conditions for ${widget.pet.name}",
                      style: TextStyle(color: _darkCharcoal.withAlpha(180), fontSize: 13),
                    ),
                    const SizedBox(height: 20),

                    // Condition Title
                    _buildLabel("CONDITION / DISEASE NAME"),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: commonDiseases.map((disease) {
                        final isSel = selectedCommon == disease;
                        return ChoiceChip(
                          label: Text(disease, style: TextStyle(color: isSel ? Colors.white : _darkCharcoal, fontWeight: FontWeight.bold, fontSize: 13)),
                          selected: isSel,
                          selectedColor: _dustyOlive,
                          backgroundColor: Colors.white,
                          onSelected: (val) {
                            setMState(() {
                              if (val) {
                                selectedCommon = disease;
                                if (disease != "Others") {
                                  titleCtrl.text = disease;
                                } else {
                                  titleCtrl.clear();
                                }
                              } else {
                                selectedCommon = null;
                                titleCtrl.clear();
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    
                    if (selectedCommon == "Others") ...[
                      TextField(
                        controller: titleCtrl,
                        decoration: InputDecoration(
                          hintText: "Specify the disease or issue...",
                          fillColor: Colors.white,
                          filled: true,
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        style: TextStyle(fontWeight: FontWeight.bold, color: _darkCharcoal),
                      ),
                      const SizedBox(height: 16),
                    ] else const SizedBox(height: 4),

                    // Diagnosis Date
                    _buildLabel("DIAGNOSIS DATE"),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) setMState(() => selectedDate = picked);
                        },
                        icon: Icon(Icons.calendar_today_rounded, color: _dustyOlive, size: 18),
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
                    const SizedBox(height: 16),

                    // Severity
                    _buildLabel("SEVERITY LEVEL"),
                    Row(
                      children: ['Mild', 'Moderate', 'Severe'].map((sev) {
                        final isSel = severity == sev;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(sev, style: TextStyle(color: isSel ? Colors.white : _darkCharcoal, fontWeight: FontWeight.bold, fontSize: 13)),
                            selected: isSel,
                            selectedColor: sev == 'Severe' ? _errorCoral : _dustyOlive,
                            backgroundColor: Colors.white,
                            onSelected: (val) {
                              if (val) setMState(() => severity = sev);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Status
                    _buildLabel("CURRENT STATUS"),
                    Row(
                      children: ['Active', 'Ongoing', 'Recovered'].map((st) {
                        final isSel = status == st;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(st, style: TextStyle(color: isSel ? Colors.white : _darkCharcoal, fontWeight: FontWeight.bold, fontSize: 13)),
                            selected: isSel,
                            selectedColor: st == 'Recovered' ? Colors.green : _dustyOlive,
                            backgroundColor: Colors.white,
                            onSelected: (val) {
                              if (val) setMState(() => status = st);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    _buildLabel("ADDITIONAL NOTES / SYMPTOMS"),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "Prescribed meds, vet instructions, symptoms...",
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : () async {
                          if (titleCtrl.text.trim().isEmpty) return;
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

                            final issue = HealthIssue(
                              id: existingIssue?.id ?? '',
                              petId: widget.pet.id,
                              title: titleCtrl.text.trim(),
                              diagnosisDate: selectedDate,
                              severity: severity,
                              status: status,
                              notes: notesCtrl.text.trim(),
                            );

                            DiseaseType mappedDisease = _mapDiseaseTitleToType(titleCtrl.text.trim());

                            if (existingIssue == null) {
                              await _healthService.addHealthIssue(uid, widget.pet.id, issue);
                              await PetService().updatePetHealthStatus(uid, widget.pet.id, false, activeDisease: mappedDisease);
                            } else {
                              await _healthService.updateHealthIssue(uid, widget.pet.id, existingIssue.id, issue);
                              await PetService().updatePetHealthStatus(uid, widget.pet.id, false, activeDisease: mappedDisease);
                            }

                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            debugPrint("Error saving health issue: $e");
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
                          : Text(existingIssue == null ? "Save to Passport" : "Update Issue", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
      body: StreamBuilder<PetProfile?>(
        stream: PetService().streamPet(uid, widget.pet.id),
        builder: (context, petSnapshot) {
          if (petSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          final currentPet = petSnapshot.data ?? widget.pet;

          return Column(
            children: [
              FringeHeader(
                title: "Health Issues",
                subtitle: "${currentPet.name} • Passport Synced",
                onBack: () => Navigator.pop(context),
              ),
              Expanded(
                child: StreamBuilder<List<HealthIssue>>(
                  stream: _healthService.streamHealthIssues(uid, currentPet.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.white));
                    }

                final issues = snapshot.data ?? [];

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
                              child: Icon(Icons.healing_rounded, color: _dustyOlive, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Overall Passport Status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _darkCharcoal)),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: InkWell(
                                          onTap: () async {
                                            await PetService().updatePetHealthStatus(uid, currentPet.id, true);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                            decoration: BoxDecoration(
                                              color: currentPet.isHealthy == true ? Colors.green.withAlpha(40) : Colors.grey.withAlpha(20),
                                              border: Border.all(color: currentPet.isHealthy == true ? Colors.green : Colors.transparent, width: 2),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Center(child: Text("Healthy", style: TextStyle(fontWeight: FontWeight.bold, color: currentPet.isHealthy == true ? Colors.green : Colors.grey.shade600))),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: InkWell(
                                          onTap: () async {
                                            await PetService().updatePetHealthStatus(uid, currentPet.id, false);
                                            _showAddIssueDialog();
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                            decoration: BoxDecoration(
                                              color: currentPet.isHealthy == false ? _errorCoral.withAlpha(40) : Colors.grey.withAlpha(20),
                                              border: Border.all(color: currentPet.isHealthy == false ? _errorCoral : Colors.transparent, width: 2),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Center(child: Text("Has Diseases", style: TextStyle(fontWeight: FontWeight.bold, color: currentPet.isHealthy == false ? _errorCoral : Colors.grey.shade600))),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text("This syncs directly with the Pet Passport top right badge.", style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (currentPet.isHealthy == false) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("LOGGED CONDITIONS (${issues.length})", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.8)),
                            ElevatedButton.icon(
                              onPressed: () => _showAddIssueDialog(),
                              icon: const Icon(Icons.add, size: 16, color: Colors.white),
                              label: const Text("+ Log Issue", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _darkCharcoal,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                      if (issues.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(color: Colors.white.withAlpha(200), borderRadius: BorderRadius.circular(20)),
                          child: Column(
                            children: [
                              Icon(Icons.check_circle_outline_rounded, size: 48, color: _dustyOlive),
                              const SizedBox(height: 12),
                              Text("No Active Health Issues", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _darkCharcoal)),
                              const SizedBox(height: 4),
                              Text("Tap + Log Issue to record diseases or allergies.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: issues.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final issue = issues[index];
                            final isRecovered = issue.status == 'Recovered';
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isRecovered ? Colors.green.withAlpha(100) : (issue.severity == 'Severe' ? _errorCoral : _dustyOlive.withAlpha(100)),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          issue.title,
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: _darkCharcoal),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isRecovered ? Colors.green.withAlpha(30) : _errorCoral.withAlpha(30),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          issue.status.toUpperCase(),
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isRecovered ? Colors.green : _errorCoral),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 18),
                                        onPressed: () => _showAddIssueDialog(issue),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: Icon(Icons.delete_outline_rounded, size: 18, color: _errorCoral),
                                        onPressed: () async {
                                          await _healthService.deleteHealthIssue(uid, currentPet.id, issue.id);
                                        },
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today_rounded, size: 12, color: Colors.grey.shade600),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Diagnosed: ${DateFormat('dd MMM yyyy').format(issue.diagnosisDate)}",
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(Icons.warning_amber_rounded, size: 12, color: issue.severity == 'Severe' ? _errorCoral : _dustyOlive),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Severity: ${issue.severity}",
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: issue.severity == 'Severe' ? _errorCoral : _darkCharcoal),
                                      ),
                                    ],
                                  ),
                                  if (issue.notes.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      issue.notes,
                                      style: TextStyle(fontSize: 13, color: _darkCharcoal, fontStyle: FontStyle.italic),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ], // Close the if block
                      const SizedBox(height: 80),
                    ],
                  ),
                );
              },
            ),
          ),
            ],
          );
        },
      ),
    );
  }
}
