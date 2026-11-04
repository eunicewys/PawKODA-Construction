import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/pet_model.dart';
import '../../models/disease_model.dart';
import '../../models/health_model.dart';
import '../../providers/user_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../services/health_service.dart';
import '../../services/pet_service.dart';
import '../../utils/unsaved_changes_dialog.dart';
import '../widgets/fringe_header.dart';
import '../widgets/offline_banner.dart';

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

  String _toTitleCase(String text) {
    if (text.trim().isEmpty) return text;
    return text.trim().split(RegExp(r'\s+')).map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

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

  void _showVetConsultModal(String diseaseName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: _errorCoral.withAlpha(30), shape: BoxShape.circle),
              child: Icon(Icons.local_hospital_rounded, color: _errorCoral, size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Consult Veterinarian",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _darkCharcoal),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 14, color: _darkCharcoal, height: 1.4),
                children: [
                  const TextSpan(text: "For "),
                  TextSpan(
                    text: diseaseName,
                    style: TextStyle(fontWeight: FontWeight.bold, color: _dustyOlive),
                  ),
                  const TextSpan(
                    text: ", please consult a qualified veterinarian for real specialized nutrition intake and clinical advice.\n\n",
                  ),
                  TextSpan(
                    text: "⚠️ Note: ",
                    style: TextStyle(fontWeight: FontWeight.bold, color: _errorCoral),
                  ),
                  const TextSpan(
                    text: "Because this condition requires professional diagnosis, the Nutrition Engine will calculate energy requirements for ",
                  ),
                  TextSpan(
                    text: widget.pet.name,
                    style: TextStyle(fontWeight: FontWeight.bold, color: _darkCharcoal),
                  ),
                  const TextSpan(
                    text: " using normal healthy pet formulas.",
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _dustyOlive,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("Understood", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
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

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: _errorCoral, size: 26),
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
              onPressed: () => Navigator.pop(context),
              child: const Text("OK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddIssueDialog([HealthIssue? existingIssue]) {
    final connectivity = Provider.of<ConnectivityProvider>(context, listen: false);
    if (connectivity.isOffline) {
      ConnectivityProvider.showOfflineReadOnlyDialog(context, action: "Logging or updating medical conditions");
      return;
    }

    final titleCtrl = TextEditingController(text: existingIssue?.title ?? '');
    final notesCtrl = TextEditingController(text: existingIssue?.notes ?? '');
    DateTime selectedDate = existingIssue?.diagnosisDate ?? DateTime.now();
    String? severity = existingIssue?.severity;
    String? status = existingIssue?.status;
    bool isSaving = false;

    // Common Diseases List
    final List<String> commonDiseases = [
      "Obesity / Weight Loss",
      "Chronic Kidney Disease (CKD)",
      "Diabetes Mellitus",
      "Pancreatitis",
      "Urinary Issue",
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
          bool checkUnsavedChanges() {
            if (existingIssue == null) {
              if (selectedCommon != null) return true;
              if (titleCtrl.text.trim().isNotEmpty) return true;
              if (notesCtrl.text.trim().isNotEmpty) return true;
              if (severity != 'Mild') return true;
              if (status != 'Active') return true;
              final now = DateTime.now();
              if (selectedDate.year != now.year || selectedDate.month != now.month || selectedDate.day != now.day) return true;
              return false;
            } else {
              if (titleCtrl.text.trim() != existingIssue.title) return true;
              if (selectedCommon != (isOtherSelected ? "Others" : existingIssue.title)) return true;
              if (severity != existingIssue.severity) return true;
              if (status != existingIssue.status) return true;
              if (notesCtrl.text.trim() != existingIssue.notes) return true;
              if (selectedDate.year != existingIssue.diagnosisDate.year || selectedDate.month != existingIssue.diagnosisDate.month || selectedDate.day != existingIssue.diagnosisDate.day) return true;
              return false;
            }
          }

          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;
              if (isSaving || !checkUnsavedChanges()) {
                Navigator.of(context).pop();
                return;
              }
              final bool shouldDiscard = await showUnsavedChangesDialog(context);
              if (shouldDiscard && context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: Padding(
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
                      existingIssue == null ? "Log Health Issue" : "Edit Health Issue",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _darkCharcoal),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Record diseases or medical conditions for ${widget.pet.name}",
                      style: TextStyle(color: _darkCharcoal.withAlpha(180), fontSize: 13),
                    ),
                    const SizedBox(height: 20),

                    // Condition Title Dropdown
                    _buildLabel("CONDITION / DISEASE NAME", isRequired: true),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCommon,
                      isExpanded: true,
                      decoration: InputDecoration(
                        hintText: "Select condition or disease...",
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal, fontSize: 13),
                        fillColor: Colors.white,
                        filled: true,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      dropdownColor: Colors.white,
                      style: TextStyle(fontWeight: FontWeight.w600, color: _darkCharcoal, fontSize: 13),
                      items: commonDiseases.map((d) => DropdownMenuItem<String>(
                        value: d,
                        child: Text(d, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                      )).toList(),
                      onChanged: (val) {
                        setMState(() {
                          selectedCommon = val;
                          if (val != null && val != "Others") {
                            titleCtrl.text = val;
                          } else {
                            titleCtrl.clear();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    
                    if (selectedCommon == "Others") ...[
                      TextField(
                        controller: titleCtrl,
                        decoration: InputDecoration(
                          hintText: "Specify the disease or issue...",
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal, fontSize: 13),
                          fillColor: Colors.white,
                          filled: true,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        style: TextStyle(fontWeight: FontWeight.w600, color: _darkCharcoal, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                    ] else const SizedBox(height: 4),

                    // Diagnosis Date
                    _buildLabel("DIAGNOSIS DATE", isRequired: true),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
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
                        icon: Icon(Icons.calendar_today_rounded, color: _dustyOlive, size: 16),
                        label: Text(
                          DateFormat('dd MMM yyyy').format(selectedDate),
                          style: TextStyle(color: _darkCharcoal, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: BorderSide(color: _darkCharcoal.withAlpha(50)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Severity Dropdown
                    _buildLabel("SEVERITY LEVEL", isRequired: true),
                    DropdownButtonFormField<String>(
                      initialValue: severity,
                      isExpanded: true,
                      decoration: InputDecoration(
                        hintText: "Select severity...",
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal, fontSize: 13),
                        fillColor: Colors.white,
                        filled: true,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      dropdownColor: Colors.white,
                      style: TextStyle(fontWeight: FontWeight.w600, color: _darkCharcoal, fontSize: 13),
                      items: ['Mild', 'Moderate', 'Severe'].map((sev) => DropdownMenuItem<String>(
                        value: sev,
                        child: Text(sev, style: const TextStyle(fontSize: 13)),
                      )).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setMState(() => severity = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Status (2 Options: Active vs Recovered)
                    _buildLabel("CURRENT STATUS", isRequired: true),
                    Row(
                      children: ['Active', 'Recovered'].map((st) {
                        final isSel = status == st;
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: ChoiceChip(
                            label: Text(
                              st, 
                              style: TextStyle(
                                color: isSel ? Colors.white : _darkCharcoal, 
                                fontWeight: isSel ? FontWeight.bold : FontWeight.w600, 
                                fontSize: 13
                              )
                            ),
                            selected: isSel,
                            selectedColor: st == 'Recovered' ? Colors.green : _dustyOlive,
                            backgroundColor: Colors.white,
                            showCheckmark: false,
                            onSelected: (val) {
                              if (val) setMState(() => status = st);
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide.none,
                            ),
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
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal, fontSize: 13),
                        fillColor: Colors.white,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      style: TextStyle(fontWeight: FontWeight.w600, color: _darkCharcoal, fontSize: 13),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : () async {
                          final String enteredTitle = _toTitleCase(titleCtrl.text);

                          if (selectedCommon == null || selectedCommon!.isEmpty) {
                            _showErrorDialog("Condition Required", "Please select a condition or select 'Others' and specify the disease name.");
                            return;
                          }

                          if (selectedCommon == "Others" && enteredTitle.isEmpty) {
                            _showErrorDialog("Disease Name Required", "Please specify the custom condition or disease name before saving to the Pet Passport.");
                            return;
                          }

                          if (enteredTitle.isEmpty) {
                            _showErrorDialog("Disease Name Required", "Condition / Disease name is required.");
                            return;
                          }

                          if (severity == null || severity!.isEmpty) {
                            _showErrorDialog("Severity Required", "Please select a severity level for this condition.");
                            return;
                          }

                          if (status == null || status!.isEmpty) {
                            _showErrorDialog("Status Required", "Please select the current status (Active or Recovered).");
                            return;
                          }

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
                              title: enteredTitle,
                              diagnosisDate: selectedDate,
                              severity: severity!,
                              status: status!,
                              notes: notesCtrl.text.trim(),
                            );

                            DiseaseType mappedDisease = _mapDiseaseTitleToType(enteredTitle);

                            if (existingIssue == null) {
                              await _healthService.addHealthIssue(uid, widget.pet.id, issue);
                              await PetService().updatePetHealthStatus(uid, widget.pet.id, false, activeDisease: mappedDisease);
                            } else {
                              await _healthService.updateHealthIssue(uid, widget.pet.id, existingIssue.id, issue);
                              await PetService().updatePetHealthStatus(uid, widget.pet.id, false, activeDisease: mappedDisease);
                            }

                            if (context.mounted) {
                              Navigator.pop(context); // Close modal sheet
                              
                              // If disease is outside the 5 clinical diseases, show pop-up dialog warning
                              if (mappedDisease == DiseaseType.none) {
                                _showVetConsultModal(enteredTitle);
                              }
                            }
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
                          : Text(existingIssue == null ? "Save" : "Update Issue", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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

  Widget _buildLabel(String text, {bool isRequired = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text.rich(
      TextSpan(
        text: text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _darkCharcoal, letterSpacing: 0.5),
        children: isRequired
            ? [
                const TextSpan(
                  text: " *",
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ]
            : [],
      ),
    ),
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
                title: "Medical Conditions",
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
                      const OfflineBanner(margin: EdgeInsets.only(bottom: 12)),
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
                                  Text("Health Status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _darkCharcoal)),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: InkWell(
                                          onTap: () async {
                                            final connectivity = Provider.of<ConnectivityProvider>(context, listen: false);
                                            if (connectivity.isOffline) {
                                              ConnectivityProvider.showOfflineReadOnlyDialog(context, action: "Updating health status");
                                              return;
                                            }
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
                                            final connectivity = Provider.of<ConnectivityProvider>(context, listen: false);
                                            if (connectivity.isOffline) {
                                              ConnectivityProvider.showOfflineReadOnlyDialog(context, action: "Updating health status");
                                              return;
                                            }
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
                                  Text("Sync with Pet Passport", style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w500)),
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
                            Text("LOGGED ISSUES (${issues.length})", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.8)),
                            ElevatedButton.icon(
                              onPressed: () => _showAddIssueDialog(),
                              icon: const Icon(Icons.add, size: 14, color: Colors.white),
                              label: const Text("Add Disease", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
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
                              Text("Tap + Add Disease to record health issues", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: issues.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final issue = issues[index];
                            final isRecovered = issue.status == 'Recovered';
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          issue.title,
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _darkCharcoal),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: isRecovered ? Colors.green.withAlpha(30) : _errorCoral.withAlpha(30),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              issue.status.toUpperCase(),
                                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isRecovered ? Colors.green : _errorCoral),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          InkWell(
                                            onTap: () => _showAddIssueDialog(issue),
                                            borderRadius: BorderRadius.circular(6),
                                            child: Padding(
                                              padding: const EdgeInsets.all(3),
                                              child: Icon(Icons.edit_note_rounded, size: 22, color: _dustyOlive),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          InkWell(
                                            onTap: () async {
                                              final connectivity = Provider.of<ConnectivityProvider>(context, listen: false);
                                              if (connectivity.isOffline) {
                                                ConnectivityProvider.showOfflineReadOnlyDialog(context, action: "Deleting medical conditions");
                                                return;
                                              }
                                              bool confirm = await _showDeleteConfirmationDialog(
                                                context,
                                                title: "Delete",
                                                message: "Are you sure you want to delete '${issue.title}'? This action cannot be undone.",
                                              );
                                              if (confirm) {
                                                await _healthService.deleteHealthIssue(uid, currentPet.id, issue.id);
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
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today_rounded, size: 12, color: Colors.grey.shade600),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Diagnosed: ${DateFormat('dd MMM yyyy').format(issue.diagnosisDate)}",
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.warning_amber_rounded, size: 13, color: issue.severity == 'Severe' ? _errorCoral : _dustyOlive),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Severity: ${issue.severity}",
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: issue.severity == 'Severe' ? _errorCoral : _darkCharcoal),
                                      ),
                                    ],
                                  ),
                                  if (issue.notes.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      "Notes: ${issue.notes}",
                                      style: TextStyle(fontSize: 12, color: _darkCharcoal.withAlpha(200), fontStyle: FontStyle.italic),
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
