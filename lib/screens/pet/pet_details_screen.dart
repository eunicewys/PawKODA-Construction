import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/pet_model.dart';
import '../../services/pet_service.dart';
import '../../providers/user_provider.dart';
import '../../utils/image_helper.dart';
import '../../models/health_model.dart';
import '../../services/health_service.dart';
import '../health/health_issues_screen.dart';
import '../health/vaccination_screen.dart';

class PetDetailsScreen extends StatefulWidget {
  final String petId;
  const PetDetailsScreen({super.key, required this.petId});

  @override
  State<PetDetailsScreen> createState() => _PetDetailsScreenState();
}

class _PetDetailsScreenState extends State<PetDetailsScreen> {
  // Morandi Palette
  final Color _dustyOlive = const Color(0xFF6B705C);
  final Color _powderPetal = const Color(0xFFFFE8D6);
  final Color _desertSand = const Color(0xFFDDBEA9);
  final Color _drySage = const Color(0xFFA5A58D);
  final Color _ashGrey = const Color(0xFFB7B7A4);
  final Color _darkCharcoal = const Color(0xFF2D3142);
  final Color _errorCoral = const Color(0xFFB56576);

  final HealthService _healthService = HealthService();

  final PetService _petService = PetService();
  final ImagePicker _picker = ImagePicker();
  Map<String, dynamic> _breedData = {};

  @override
  void initState() {
    super.initState();
    _loadBreedData();
  }

  Future<void> _loadBreedData() async {
    try {
      final String response = await rootBundle.loadString('assets/data/breeds.json');
      final dynamic decoded = json.decode(response);
      
      Map<String, List<String>> map = {
        'dog': [],
        'cat': [],
      };

      if (decoded is List) {
        for (var item in decoded) {
          if (item is Map) {
            String species = (item['species'] ?? '').toString().toLowerCase();
            String name = (item['name'] ?? '').toString();
            if (map.containsKey(species) && name.isNotEmpty) {
              map[species]!.add(name);
            }
          }
        }
      } else if (decoded is Map<String, dynamic>) {
        decoded.forEach((key, value) {
          if (value is List) {
            map[key.toLowerCase()] = List<String>.from(value.map((e) => e.toString()));
          }
        });
      }

      setState(() => _breedData = map);
    } catch (e) {
      debugPrint("Error loading breeds: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = Provider.of<UserProvider>(context, listen: false).uid ?? "";

    return StreamBuilder<PetProfile?>(
      stream: _petService.streamPet(uid, widget.petId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final pet = snapshot.data;
        if (pet == null) {
          return Scaffold(
            appBar: AppBar(backgroundColor: _drySage),
            body: const Center(child: Text("Pet passport not found.")),
          );
        }

        return Scaffold(
          backgroundColor: _drySage,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text("Pet Passport Card", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 30),
                onPressed: () => _showEditPetDialog(pet),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(pet),
                const SizedBox(height: 32),
                _buildProfileSection(pet),
                const SizedBox(height: 32),
                _buildAllergySection(pet),
                const SizedBox(height: 32),
                _buildHealthIssuesSection(uid, pet),
                const SizedBox(height: 32),
                _buildHealthRecordsSection(uid, pet),
                const SizedBox(height: 50),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(PetProfile pet) {
    ImageProvider? imgProvider = ImageHelper.getImageProvider(pet.imageUrl);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 20)],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage: imgProvider,
            backgroundColor: const Color(0xFFF5F5F5), // Stonish white
            child: imgProvider == null 
                ? Icon(
                    Icons.pets_rounded, // Universal pet icon as fallback
                    size: 50, 
                    color: _ashGrey.withAlpha(150)
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(pet.name, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _darkCharcoal)),
          Text("${pet.breed} • ${pet.species.name.toUpperCase()}", style: TextStyle(fontSize: 16, color: _ashGrey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          InkWell(
            onTap: pet.isHealthy == null ? () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => HealthIssuesScreen(pet: pet)));
            } : null,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: pet.isHealthy == null 
                    ? Colors.transparent
                    : (pet.isHealthy! ? Colors.green.withAlpha(30) : _errorCoral.withAlpha(30)),
                borderRadius: BorderRadius.circular(20),
                border: pet.isHealthy == null 
                    ? Border.all(color: _ashGrey.withAlpha(100), width: 1.5) 
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (pet.isHealthy != null)
                    CircleAvatar(radius: 4, backgroundColor: pet.isHealthy! ? Colors.green : _errorCoral),
                  if (pet.isHealthy != null)
                    const SizedBox(width: 8),
                  Text(
                    pet.isHealthy == null 
                        ? "LOG HEALTH NOW" 
                        : (pet.isHealthy! ? "HEALTHY" : "NEEDS ATTENTION"),
                    style: TextStyle(
                      fontSize: 12, 
                      fontWeight: FontWeight.bold, 
                      color: pet.isHealthy == null 
                          ? _ashGrey
                          : (pet.isHealthy! ? Colors.green : _errorCoral)
                    ),
                  ),
                  if (pet.isHealthy == null) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios_rounded, size: 10, color: _ashGrey),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(PetProfile pet) {
    int y = (pet.ageInMonths / 12).floor();
    int m = pet.ageInMonths % 12;
    String conditionLabel = pet.condition.name.toUpperCase();
    if (pet.gender == Gender.female && pet.condition == PetCondition.intact) {
      conditionLabel = "INTACT";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("METABOLIC PROFILE"),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.5,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _detailChip("GENDER", pet.gender.name.toUpperCase()),
            _detailChip("WEIGHT", "${pet.weightKg} kg"),
            _detailChip("AGE", "${y}y, ${m}m"),
            _detailChip("STATUS", conditionLabel),
          ],
        ),
      ],
    );
  }

  Widget _buildAllergySection(PetProfile pet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("ALLERGENS & INTOLERANCES"),
        const SizedBox(height: 16),
        pet.allergens.isEmpty
            ? Text("No allergies reported.", style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 16))
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: pet.allergens.map((a) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC5828E).withAlpha(180), // Darkened coral for better contrast
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: Text(a, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                )).toList(),
              ),
      ],
    );
  }

  Widget _buildHealthIssuesSection(String uid, PetProfile pet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionTitle("HEALTH ISSUES"),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HealthIssuesScreen(pet: pet)),
                );
              },
              child: Text("Manage", style: TextStyle(color: _powderPetal, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<HealthIssue>>(
          stream: _healthService.streamHealthIssues(uid, pet.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFFFBFBFB), borderRadius: BorderRadius.circular(24)),
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            final issues = snapshot.data ?? [];

            if (issues.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBFBFB),
                  borderRadius: BorderRadius.circular(24), 
                  border: Border.all(color: Colors.white.withAlpha(50)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.monitor_heart_rounded, size: 36, color: _ashGrey.withAlpha(120)),
                    const SizedBox(height: 10),
                    Text(
                      "No active medical conditions logged.", 
                      textAlign: TextAlign.center, 
                      style: TextStyle(color: _darkCharcoal.withAlpha(180), fontSize: 13, fontWeight: FontWeight.w500)
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => HealthIssuesScreen(pet: pet)),
                        );
                      },
                      icon: const Icon(Icons.add, color: Colors.white, size: 16),
                      label: const Text("Log Medical Condition", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _dustyOlive,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: issues.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final issue = issues[index];
                Color severityColor = Colors.orange;
                if (issue.severity.toLowerCase() == 'mild') severityColor = Colors.teal;
                if (issue.severity.toLowerCase() == 'severe') severityColor = _errorCoral;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBFBFB),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 5)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.healing_rounded, size: 18, color: severityColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              issue.title,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _darkCharcoal),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: severityColor.withAlpha(30),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              issue.severity.toUpperCase(),
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: severityColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Diagnosed: ${DateFormat('dd MMM yyyy').format(issue.diagnosisDate)}",
                            style: TextStyle(fontSize: 12, color: _ashGrey, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Status: ${issue.status}",
                            style: TextStyle(
                              fontSize: 12, 
                              fontWeight: FontWeight.bold, 
                              color: issue.status.toLowerCase() == 'recovered' ? Colors.green : _darkCharcoal
                            ),
                          ),
                        ],
                      ),
                      if (issue.notes.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          issue.notes,
                          style: TextStyle(fontSize: 12, color: _darkCharcoal.withAlpha(180), fontStyle: FontStyle.italic),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildHealthRecordsSection(String uid, PetProfile pet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionTitle("WELLNESS TRACK"),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => VaccinationScreen(pet: pet)),
                );
              },
              child: Text("View All", style: TextStyle(color: _powderPetal, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<VaccinationRecord>>(
          stream: _healthService.streamVaccinations(uid, pet.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFFFBFBFB), borderRadius: BorderRadius.circular(24)),
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            final records = snapshot.data ?? [];
            
            // STRICT FILTER: Pet Passport displays ONLY passed/completed vaccination & deworming records
            final DateTime now = DateTime.now();
            final passedRecords = records.where((r) {
              return r.isCompleted || r.dateGiven.isBefore(now) || (r.dateGiven.year == now.year && r.dateGiven.month == now.month && r.dateGiven.day == now.day);
            }).toList();

            if (passedRecords.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBFBFB),
                  borderRadius: BorderRadius.circular(24), 
                  border: Border.all(color: Colors.white.withAlpha(50)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.history_edu_rounded, size: 36, color: _ashGrey.withAlpha(120)),
                    const SizedBox(height: 10),
                    Text(
                      "No passed vaccination or deworming records logged yet.", 
                      textAlign: TextAlign.center, 
                      style: TextStyle(color: _darkCharcoal.withAlpha(180), fontSize: 13, fontWeight: FontWeight.w500)
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => VaccinationScreen(pet: pet)),
                        );
                      },
                      icon: const Icon(Icons.add, color: Colors.white, size: 16),
                      label: const Text("Log Dose Record", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _dustyOlive,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: passedRecords.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final rec = passedRecords[index];
                bool isVaccine = rec.type.toLowerCase() == 'vaccine';

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBFBFB),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 5)],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isVaccine ? Colors.blue.withAlpha(30) : Colors.orange.withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isVaccine ? Icons.vaccines_rounded : Icons.medication_rounded,
                          color: isVaccine ? Colors.blue.shade800 : Colors.orange.shade800,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    rec.doseName,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _darkCharcoal),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withAlpha(30),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    "✓ PASSED",
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Given: ${DateFormat('dd MMM yyyy').format(rec.dateGiven)} • ${rec.dosage}",
                              style: TextStyle(fontSize: 12, color: _ashGrey, fontWeight: FontWeight.bold),
                            ),
                            if (rec.vetName.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                "Administered at: ${rec.vetName}",
                                style: TextStyle(fontSize: 11, color: _darkCharcoal.withAlpha(160)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) => Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2));

  Widget _detailChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFB), // Creamy white
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: _ashGrey, fontWeight: FontWeight.bold)),
            Text(value, style: TextStyle(fontSize: 15, color: _darkCharcoal, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // --- EDIT DIALOG LOGIC ---

  void _showEditPetDialog(PetProfile pet) {
    final nameCtrl = TextEditingController(text: pet.name);
    final weightCtrl = TextEditingController(text: pet.weightKg.toString());
    final otherAllergenCtrl = TextEditingController();
    
    Species? selectedSpecies = pet.species;
    Gender? selectedGender = pet.gender;
    String? selectedReproductive = pet.condition == PetCondition.neutered ? "Neutered/Spayed" : "Intact";
    bool isPregnant = pet.condition == PetCondition.pregnant;
    bool isNursing = pet.condition == PetCondition.nursing;
    String? selectedBreed = pet.breed;
    DateTime? selectedBirthDate = pet.birthDate;
    XFile? petImage;
    List<String> selectedAllergens = List.from(pet.allergens);
    bool hasNoAllergies = pet.allergens.isEmpty;
    bool isSaving = false;

    final List<String> commonAllergens = ["Chicken", "Beef", "Fish", "Egg", "Grain", "Dairy"];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setMState) {
          bool checkUnsavedChanges() {
            if (nameCtrl.text.trim() != pet.name) return true;
            if (selectedSpecies != pet.species) return true;
            if (selectedBreed != pet.breed) return true;
            if (selectedGender != pet.gender) return true;
            if ((double.tryParse(weightCtrl.text) ?? 0.0) != pet.weightKg) return true;
            if (selectedBirthDate != pet.birthDate) return true;
            if (petImage != null) return true;

            PetCondition finalCond = selectedReproductive == "Neutered/Spayed" ? PetCondition.neutered : PetCondition.intact;
            if (isNursing) {
              finalCond = PetCondition.nursing;
            } else if (isPregnant) {
              finalCond = PetCondition.pregnant;
            }
            if (finalCond != pet.condition) return true;

            List<String> allergens = List.from(selectedAllergens);
            if (allergens.contains("Other") && otherAllergenCtrl.text.isNotEmpty) {
              allergens.remove("Other");
              allergens.add(otherAllergenCtrl.text.trim());
            }
            if (allergens.length != pet.allergens.length) return true;
            for (var a in allergens) {
              if (!pet.allergens.contains(a)) return true;
            }
            return false;
          }

          return PopScope(
            canPop: false,
            onPopInvoked: (didPop) async {
              if (didPop) return;
              if (isSaving || !checkUnsavedChanges()) {
                Navigator.of(context).pop();
                return;
              }
              final bool? shouldPop = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  title: Text("Unsaved Changes", style: TextStyle(color: _darkCharcoal, fontWeight: FontWeight.bold)),
                  content: const Text("You have unsaved changes. Are you sure you want to discard them?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text("Keep Editing", style: TextStyle(color: _dustyOlive, fontWeight: FontWeight.bold)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text("Discard", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
              if (shouldPop == true && context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: Container(
              height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(color: _desertSand, borderRadius: const BorderRadius.vertical(top: Radius.circular(40))),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 25),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: InkWell(
                    onTap: () async {
                      _showImageSourceSheet(setMState, (image) => petImage = image);
                    },
                    child: Container(
                      width: 110, height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle, border: Border.all(color: _ashGrey, width: 2),
                        image: petImage != null 
                            ? DecorationImage(image: FileImage(File(petImage!.path)), fit: BoxFit.cover)
                            : (pet.imageUrl != null ? DecorationImage(image: ImageHelper.getImageProvider(pet.imageUrl)!, fit: BoxFit.cover) : null),
                      ),
                      child: (petImage == null && pet.imageUrl == null) ? Icon(Icons.add_a_photo, color: _ashGrey, size: 40) : null,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text("Edit Passport", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _darkCharcoal)),
                const SizedBox(height: 32),
                
                _buildFormLabel("PET NAME"),
                _buildTextField(nameCtrl, "e.g. Buddy"),
                
                const SizedBox(height: 20),
                _buildFormLabel("SPECIES"),
                Row(
                  children: [
                    _buildSpeciesChip("Dog", Species.dog, selectedSpecies, (s) {
                      setMState(() { selectedSpecies = s; selectedBreed = null; });
                    }),
                    const SizedBox(width: 12),
                    _buildSpeciesChip("Cat", Species.cat, selectedSpecies, (s) {
                      setMState(() { selectedSpecies = s; selectedBreed = null; });
                    }),
                  ],
                ),

                if (selectedSpecies != null) ...[
                  const SizedBox(height: 20),
                  _buildFormLabel("BREED"),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: Colors.white.withAlpha(180), borderRadius: BorderRadius.circular(12)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedBreed, isExpanded: true, 
                        hint: Text("Select Breed", style: TextStyle(color: _darkCharcoal.withAlpha(120))),
                        items: (_breedData[selectedSpecies!.name] as List<dynamic>?)?.map((b) => DropdownMenuItem<String>(
                          value: b.toString(),
                          child: Text(b.toString()),
                        )).toList() ?? [],
                        onChanged: (val) => setMState(() => selectedBreed = val),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                _buildFormLabel("GENDER"),
                Row(
                  children: [
                    _buildChoiceChip("Male", selectedGender == Gender.male, () => setMState(() { selectedGender = Gender.male; isPregnant = false; isNursing = false; })),
                    const SizedBox(width: 12),
                    _buildChoiceChip("Female", selectedGender == Gender.female, () => setMState(() => selectedGender = Gender.female)),
                  ],
                ),

                if (selectedGender != null) ...[
                  const SizedBox(height: 20),
                  _buildFormLabel("STATUS"),
                  Row(
                    children: [
                      _buildChoiceChip(selectedGender == Gender.male ? "Neutered" : "Spayed", selectedReproductive == "Neutered/Spayed", () => setMState(() {
                        selectedReproductive = "Neutered/Spayed";
                        isPregnant = false;
                        isNursing = false;
                      })),
                      const SizedBox(width: 12),
                      _buildChoiceChip("Intact", selectedReproductive == "Intact", () => setMState(() => selectedReproductive = "Intact")),
                    ],
                  ),
                  
                  if (selectedGender == Gender.female && selectedReproductive == "Intact") ...[
                    const SizedBox(height: 12),
                    _buildCheckbox("Is Pregnant?", isPregnant, (v) => setMState(() => isPregnant = v!)),
                    _buildCheckbox("Is Nursing?", isNursing, (v) => setMState(() => isNursing = v!)),
                  ],
                ],

                const SizedBox(height: 20),
                _buildFormLabel("WEIGHT (KG)"),
                Row(
                  children: [
                    _buildStepperButton(Icons.remove, () {
                      double val = double.tryParse(weightCtrl.text) ?? 0.0;
                      if (val > 1.0) setMState(() => weightCtrl.text = (val - 1.0).toStringAsFixed(1));
                    }),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: weightCtrl,
                        textAlign: TextAlign.center,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(fillColor: Colors.white.withAlpha(180), filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                        style: TextStyle(fontWeight: FontWeight.bold, color: _darkCharcoal, fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildStepperButton(Icons.add, () {
                      double val = double.tryParse(weightCtrl.text) ?? 0.0;
                      setMState(() => weightCtrl.text = (val + 1.0).toStringAsFixed(1));
                    }),
                  ],
                ),

                const SizedBox(height: 20),
                _buildFormLabel("BIRTHDATE"),
                SizedBox(
                  width: double.infinity, height: 55,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(context: context, initialDate: selectedBirthDate ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime.now());
                      if (picked != null) setMState(() => selectedBirthDate = picked);
                    },
                    icon: Icon(Icons.calendar_month, color: _dustyOlive),
                    label: Text(selectedBirthDate == null ? "Choose Date" : DateFormat('dd MMM yyyy').format(selectedBirthDate!), style: TextStyle(color: _darkCharcoal, fontWeight: FontWeight.bold, fontSize: 16)),
                    style: OutlinedButton.styleFrom(side: BorderSide(color: _darkCharcoal, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ),

                const SizedBox(height: 32),
                _buildFormLabel("ALLERGIES"),
                Wrap(
                  children: commonAllergens.map((allergen) => SizedBox(
                    width: MediaQuery.of(context).size.width * 0.4,
                    child: CheckboxListTile(
                      title: Text(allergen, style: TextStyle(color: _darkCharcoal, fontSize: 16, fontWeight: FontWeight.w600)),
                      value: selectedAllergens.contains(allergen) && !hasNoAllergies,
                      onChanged: hasNoAllergies ? null : (val) {
                        setMState(() { 
                          if (val!) {
                            selectedAllergens.add(allergen); 
                          } else {
                            selectedAllergens.remove(allergen);
                          }
                        });
                      },
                      activeColor: _dustyOlive, checkColor: Colors.white, controlAffinity: ListTileControlAffinity.leading, dense: true, contentPadding: EdgeInsets.zero,
                    ),
                  )).toList(),
                ),
                CheckboxListTile(
                  title: Row(children: [const Text("Others: ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)), Expanded(child: TextField(controller: otherAllergenCtrl, enabled: !hasNoAllergies, decoration: InputDecoration(hintText: "Specify...", hintStyle: TextStyle(color: _darkCharcoal.withAlpha(120)), isDense: true, border: InputBorder.none), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)))]),
                  value: selectedAllergens.contains("Other") && !hasNoAllergies,
                  onChanged: hasNoAllergies ? null : (val) {
                    setMState(() { 
                      if (val!) {
                        selectedAllergens.add("Other"); 
                      } else {
                        selectedAllergens.remove("Other");
                      }
                    });
                  },
                  activeColor: _dustyOlive, checkColor: Colors.white, controlAffinity: ListTileControlAffinity.leading, dense: true, contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 12),
                _buildNoAllergyOption(hasNoAllergies, (v) => setMState(() { hasNoAllergies = v!; if (hasNoAllergies) selectedAllergens.clear(); })),

                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity, height: 60,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : () async {
                      if (nameCtrl.text.isEmpty || selectedSpecies == null || selectedBreed == null || selectedGender == null || selectedReproductive == null || selectedBirthDate == null || (!hasNoAllergies && selectedAllergens.isEmpty && otherAllergenCtrl.text.isEmpty)) {
                        _showErrorDialog("Missing Information", "Please fill in all sections.");
                        return;
                      }

                      setMState(() => isSaving = true);
                      final uid = Provider.of<UserProvider>(context, listen: false).uid;
                      
                      PetCondition finalCond = selectedReproductive == "Neutered/Spayed" ? PetCondition.neutered : PetCondition.intact;
                      if (isNursing) {
                        finalCond = PetCondition.nursing;
                      } else if (isPregnant) {
                        finalCond = PetCondition.pregnant;
                      }

                      List<String> allergens = List.from(selectedAllergens);
                      if (allergens.contains("Other") && otherAllergenCtrl.text.isNotEmpty) {
                        allergens.remove("Other");
                        allergens.add(otherAllergenCtrl.text.trim());
                      }

                      // Save image to Base64 so it syncs across devices
                      String? permanentPath = pet.imageUrl;
                      if (petImage != null) {
                        permanentPath = await ImageHelper.imageToBase64(petImage!.path);
                      }

                      final updatedPet = PetProfile(
                        id: pet.id, name: nameCtrl.text.trim(), species: selectedSpecies!, gender: selectedGender!,
                        weightKg: double.tryParse(weightCtrl.text) ?? 0.0, birthDate: selectedBirthDate!,
                        condition: finalCond, allergens: allergens, breed: selectedBreed!, imageUrl: permanentPath,
                      );

                      try {
                        await _petService.updatePet(uid!, pet.id, updatedPet);
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        debugPrint("Error updating pet: $e");
                        if (context.mounted) {
                          setMState(() => isSaving = false);
                          _showErrorDialog("Update Error", "Technical detail: $e");
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: _dustyOlive, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: isSaving 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : const Text("Save Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ); // PopScope
      }, // StatefulBuilder builder
      ), // StatefulBuilder
    ); // showModalBottomSheet
  }

  void _showImageSourceSheet(StateSetter setMState, Function(XFile?) onImagePicked) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Choose Photo Source", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
            const SizedBox(height: 30),
            _sourceTile(Icons.camera_alt_rounded, "Take a Photo", () async {
              final image = await _picker.pickImage(
                source: ImageSource.camera,
                maxWidth: 512,
                maxHeight: 512,
                imageQuality: 70,
              );
              onImagePicked(image); 
              setMState(() {}); 
              if (context.mounted) Navigator.pop(context);
            }),
            _sourceTile(Icons.photo_library_rounded, "Choose from Gallery", () async {
              final image = await _picker.pickImage(
                source: ImageSource.gallery,
                maxWidth: 512,
                maxHeight: 512,
                imageQuality: 70,
              );
              onImagePicked(image); 
              setMState(() {}); 
              if (context.mounted) Navigator.pop(context);
            }),
            const SizedBox(height: 10),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16))),
          ],
        ),
      ),
    );
  }

  Widget _sourceTile(IconData i, String l, VoidCallback t) => Container(margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: _powderPetal.withAlpha(100), borderRadius: BorderRadius.circular(16)), child: ListTile(leading: Icon(i, color: _dustyOlive), title: Text(l, style: TextStyle(fontWeight: FontWeight.bold, color: _darkCharcoal)), onTap: t));

  Widget _buildFormLabel(String label, {bool isRequired = true}) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text.rich(
      TextSpan(
        text: label,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _darkCharcoal),
        children: isRequired
            ? [
                const TextSpan(
                  text: " *",
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ]
            : [],
      ),
    ),
  );
  Widget _buildTextField(TextEditingController ctrl, String hint) => TextField(controller: ctrl, style: TextStyle(color: _darkCharcoal, fontWeight: FontWeight.bold), decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: _darkCharcoal.withAlpha(120)), fillColor: Colors.white.withAlpha(180), filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)));
  Widget _buildChoiceChip(String label, bool isSelected, VoidCallback onSelect) {
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : _darkCharcoal, fontWeight: FontWeight.bold, fontSize: 15)),
      selected: isSelected,
      selectedColor: _dustyOlive,
      backgroundColor: Colors.white.withAlpha(150),
      showCheckmark: false,
      avatar: isSelected ? const Icon(Icons.check_circle, color: Colors.white, size: 22) : null,
      onSelected: (v) => onSelect(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide.none),
    );
  }

  Widget _buildSpeciesChip(String label, Species species, Species? selected, Function(Species) onSelect) {
    bool isSelected = selected == species;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : _darkCharcoal, fontWeight: FontWeight.bold, fontSize: 15)),
      selected: isSelected,
      selectedColor: _dustyOlive,
      backgroundColor: Colors.white.withAlpha(150),
      showCheckmark: false,
      avatar: isSelected ? const Icon(Icons.check_circle, color: Colors.white, size: 22) : null,
      onSelected: (v) => onSelect(species),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide.none),
    );
  }
  Widget _buildCheckbox(String l, bool v, Function(bool?) o) => CheckboxListTile(title: Text(l, style: const TextStyle(fontSize: 14)), value: v, onChanged: o, controlAffinity: ListTileControlAffinity.leading, dense: true, contentPadding: EdgeInsets.zero);
  Widget _buildStepperButton(IconData i, VoidCallback t) => Container(width: 50, height: 50, decoration: BoxDecoration(color: _dustyOlive, borderRadius: BorderRadius.circular(12)), child: IconButton(icon: Icon(i, color: Colors.white, size: 20), onPressed: t));
  Widget _buildNoAllergyOption(bool v, Function(bool?) o) => Container(decoration: BoxDecoration(color: Colors.white.withAlpha(100), borderRadius: BorderRadius.circular(12)), child: ListTile(title: const Text("No Allergies", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)), leading: Radio<bool>(value: true, groupValue: v, activeColor: _dustyOlive, onChanged: o), contentPadding: const EdgeInsets.symmetric(horizontal: 8)));

  void _showErrorDialog(String t, String m) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(t, style: TextStyle(color: _darkCharcoal, fontWeight: FontWeight.bold)),
        content: Text(m),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("Okay", style: TextStyle(color: _dustyOlive, fontWeight: FontWeight.bold)))],
      ),
    );
  }
}
