import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../providers/user_provider.dart';
import '../../providers/nutritional_provider.dart';
import '../../models/pet_model.dart';
import '../../services/pet_service.dart';
import '../../utils/image_helper.dart';
import '../login_screen.dart';
import '../nutrition/nutrition_engine_screen.dart';
import '../nutrition/saved_recipes_screen.dart';
import '../pet/pet_details_screen.dart';
import '../health/health_screen.dart';
import '../booking/booking_screen.dart';
import '../health/vaccination_screen.dart';
import '../widgets/fringe_header.dart';
import '../../models/reminder_model.dart';
import '../../services/reminder_service.dart';
import '../profile/notification_center_screen.dart';
import '../profile/privacy_security_screen.dart';
import '../profile/help_support_screen.dart';

/// UserHomeScreen: Redesigned dashboard for Pet Owners.
/// Features a "Modern Layered" pet passport experience and functional navigation.
class UserHomeScreen extends StatefulWidget {
  final int initialIndex;
  const UserHomeScreen({super.key, this.initialIndex = 0});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  // Official Morandi Natural Palette
  final Color _dustyOlive = const Color(0xFF6B705C);
  final Color _powderPetal = const Color(0xFFFFE8D6);
  final Color _lightBronze = const Color(0xFFCB997E);
  final Color _desertSand = const Color(0xFFDDBEA9);
  final Color _drySage = const Color(0xFFA5A58D);
  final Color _ashGrey = const Color(0xFFB7B7A4);
  final Color _darkCharcoal = const Color(0xFF2D3142);
  final Color _errorCoral = const Color(0xFFB56576);

  final PetService _petService = PetService();
  final ReminderService _reminderService = ReminderService();
  final ImagePicker _picker = ImagePicker();

  late int _selectedIndex;
  late PageController _pageController;
  double _currentPage = 0;
  Map<String, dynamic> _breedData = {};

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _loadBreedData();
    _pageController = PageController(viewportFraction: 0.8)
      ..addListener(() {
        if (_pageController.hasClients) {
          setState(() {
            _currentPage = _pageController.page ?? 0;
          });
        }
      });
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
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good morning,";
    if (hour < 18) return "Good afternoon,";
    return "Good evening,";
  }

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

  // --- NUTRITION ROUTING LOGIC ---

  void _handleNutritionTap(List<PetProfile> pets) {
    if (pets.isNotEmpty) {
      _showPetSelectionSheet(pets);
    } else {
      _showQuickInputForm();
    }
  }

  void _showPetSelectionSheet(List<PetProfile> pets) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: _powderPetal,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Select Pet for Nutrition", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _darkCharcoal)),
            const SizedBox(height: 20),
            ...pets.map((pet) => _buildSelectionItem(pet)),
            _buildSelectionItem(null), // "Other" option
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionItem(PetProfile? pet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(pet == null ? Icons.pets : Icons.circle, color: _dustyOlive),
        title: Text(pet?.name ?? "Other (External Pet)", style: TextStyle(fontWeight: FontWeight.bold, color: _darkCharcoal)),
        onTap: () {
          Navigator.pop(context);
          if (pet != null) {
            Provider.of<NutritionalProvider>(context, listen: false).setSelectedPet(pet);
            Navigator.push(context, MaterialPageRoute(builder: (context) => const NutritionEngineScreen()));
          } else {
            _showQuickInputForm();
          }
        },
      ),
    );
  }

  // --- INTERACTIVE DIALOGS ---

  void _showQuickInputForm() {
    final TextEditingController weightCtrl = TextEditingController(text: "1.0");
    final TextEditingController otherAllergenCtrl = TextEditingController();
    
    Species? selectedSpecies;
    Gender? selectedGender;
    String? selectedReproductive; // "Neutered/Spayed" or "Intact"
    bool isPregnant = false;
    bool isNursing = false;
    String? selectedBreed;
    DateTime? selectedBirthDate;
    List<String> selectedAllergens = [];
    bool hasNoAllergies = false;

    final List<String> commonAllergens = ["Chicken", "Beef", "Fish", "Egg", "Grain", "Dairy"];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setMState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: BoxDecoration(
              color: _desertSand,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 25),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text("Quick Calculator", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _darkCharcoal)),
                  const SizedBox(height: 8),
                  Text("Enter details for a temporary calculation.", style: TextStyle(color: _darkCharcoal.withAlpha(200), fontSize: 14)),
                  const SizedBox(height: 32),
                  
                  _buildFormLabel("SPECIES"),
                  Row(
                    children: [
                      _buildSelectionChip("Dog", selectedSpecies == Species.dog, () {
                        setMState(() {
                          selectedSpecies = Species.dog;
                          selectedBreed = null;
                        });
                      }),
                      const SizedBox(width: 12),
                      _buildSelectionChip("Cat", selectedSpecies == Species.cat, () {
                        setMState(() {
                          selectedSpecies = Species.cat;
                          selectedBreed = null;
                        });
                      }),
                    ],
                  ),

                  if (selectedSpecies != null) ...[
                    const SizedBox(height: 20),
                    _buildFormLabel("BREED"),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(180),
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                      _buildSelectionChip("Male", selectedGender == Gender.male, () => setMState(() {
                        selectedGender = Gender.male;
                        isPregnant = false;
                        isNursing = false;
                      })),
                      const SizedBox(width: 12),
                      _buildSelectionChip("Female", selectedGender == Gender.female, () => setMState(() => selectedGender = Gender.female)),
                    ],
                  ),

                  if (selectedGender != null) ...[
                    const SizedBox(height: 20),
                    _buildFormLabel("STATUS"),
                    Row(
                      children: [
                        _buildSelectionChip(selectedGender == Gender.male ? "Neutered" : "Spayed", selectedReproductive == "Neutered/Spayed", () => setMState(() {
                          selectedReproductive = "Neutered/Spayed";
                          isPregnant = false;
                          isNursing = false;
                        })),
                        const SizedBox(width: 12),
                        _buildSelectionChip("Intact", selectedReproductive == "Intact", () => setMState(() => selectedReproductive = "Intact")),
                      ],
                    ),
                    
                    if (selectedGender == Gender.female && selectedReproductive == "Intact") ...[
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        title: const Text("Is Pregnant?", style: TextStyle(fontSize: 14)),
                        value: isPregnant,
                        onChanged: (val) => setMState(() => isPregnant = val!),
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      CheckboxListTile(
                        title: const Text("Is Nursing?", style: TextStyle(fontSize: 14)),
                        value: isNursing,
                        onChanged: (val) => setMState(() => isNursing = val!),
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
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
                          decoration: InputDecoration(
                            fillColor: Colors.white.withAlpha(180),
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
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
                    width: double.infinity,
                    height: 55,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setMState(() => selectedBirthDate = picked);
                      },
                      icon: Icon(Icons.calendar_month, color: _dustyOlive),
                      label: Text(
                        selectedBirthDate == null ? "Choose Date" : DateFormat('dd MMM yyyy').format(selectedBirthDate!), 
                        style: TextStyle(color: _darkCharcoal, fontWeight: FontWeight.bold, fontSize: 16)
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: _darkCharcoal, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  _buildFormLabel("ALLERGIES"),
                  Wrap(
                    children: commonAllergens.map((allergen) => SizedBox(
                      width: MediaQuery.of(context).size.width * 0.4, // Approx half width
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
                        activeColor: _dustyOlive,
                        checkColor: Colors.white,
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    )).toList(),
                  ),
                  CheckboxListTile(
                    title: Row(
                      children: [
                        const Text("Others: ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        Expanded(
                          child: TextField(
                            controller: otherAllergenCtrl,
                            enabled: !hasNoAllergies,
                            decoration: InputDecoration(
                              hintText: "Specify...", 
                              hintStyle: TextStyle(color: _darkCharcoal.withAlpha(120)),
                              isDense: true, 
                              border: InputBorder.none
                            ),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
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
                    activeColor: _dustyOlive,
                    checkColor: Colors.white,
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(100),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: const Text("No Allergies", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                      leading: Radio<bool>(
                        value: true,
                        groupValue: hasNoAllergies,
                        activeColor: _dustyOlive,
                        onChanged: (val) {
                          setMState(() {
                            hasNoAllergies = val!;
                            if (hasNoAllergies) selectedAllergens.clear();
                          });
                        },
                      ),
                      onTap: () {
                        setMState(() {
                          hasNoAllergies = !hasNoAllergies;
                          if (hasNoAllergies) selectedAllergens.clear();
                        });
                      },
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),

                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () {
                        // Validation
                        if (selectedSpecies == null || selectedBreed == null || 
                            selectedGender == null || selectedReproductive == null ||
                            selectedBirthDate == null || (!hasNoAllergies && selectedAllergens.isEmpty && otherAllergenCtrl.text.isEmpty)) {
                          _showPawDialog("Missing Information", "Please fill in all sections to start calculation.", isError: true);
                          return;
                        }

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

                        final tempPet = PetProfile(
                          id: "temp_${DateTime.now().millisecondsSinceEpoch}", 
                          name: "It", // Default as requested
                          species: selectedSpecies!,
                          gender: selectedGender!,
                          weightKg: double.tryParse(weightCtrl.text) ?? 0.0,
                          birthDate: selectedBirthDate!,
                          condition: finalCond,
                          allergens: allergens,
                          breed: selectedBreed!,
                          imageUrl: null,
                        );

                        Provider.of<NutritionalProvider>(context, listen: false).setSelectedPet(tempPet);
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const NutritionEngineScreen()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _dustyOlive,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text("Calculate Now", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          );
        },
      ),
    );
  }



  void _showAddPetDialog() {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController weightCtrl = TextEditingController(text: "1.0");
    final TextEditingController otherAllergenCtrl = TextEditingController();
    
    Species? selectedSpecies;
    Gender? selectedGender;
    String? selectedReproductive; // "Neutered/Spayed" or "Intact"
    bool isPregnant = false;
    bool isNursing = false;
    String? selectedBreed;
    DateTime? selectedBirthDate;
    XFile? petImage;
    List<String> selectedAllergens = [];
    bool hasNoAllergies = false;
    bool isSaving = false; // Added state for double-click prevention

    final List<String> commonAllergens = ["Chicken", "Beef", "Fish", "Egg", "Grain", "Dairy"];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setMState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: BoxDecoration(
              color: _desertSand, // Changed to Desert Sand as requested
              borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 25),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: InkWell(
                      onTap: () async {
                        // Custom Source Selection Sheet
                        _showImageSourceSheet(setMState, (image) => petImage = image);
                      },
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: _ashGrey, width: 2),
                          image: petImage != null 
                            ? DecorationImage(image: FileImage(File(petImage!.path)), fit: BoxFit.cover)
                            : null,
                        ),
                        child: petImage == null ? Icon(Icons.add_a_photo, color: _ashGrey, size: 40) : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text("Add New Pet", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _darkCharcoal)),
                  const SizedBox(height: 8),
                  Text("Create a digital health passport.", style: TextStyle(color: _darkCharcoal.withAlpha(200), fontSize: 14)),
                  const SizedBox(height: 32),
                  
                  _buildFormLabel("PET NAME"),
                  _buildTextField(nameCtrl, "e.g. Buddy"),
                  
                  const SizedBox(height: 20),
                  _buildFormLabel("SPECIES"),
                  Row(
                    children: [
                      _buildSelectionChip("Dog", selectedSpecies == Species.dog, () {
                        setMState(() {
                          selectedSpecies = Species.dog;
                          selectedBreed = null;
                        });
                      }),
                      const SizedBox(width: 12),
                      _buildSelectionChip("Cat", selectedSpecies == Species.cat, () {
                        setMState(() {
                          selectedSpecies = Species.cat;
                          selectedBreed = null;
                        });
                      }),
                    ],
                  ),

                  if (selectedSpecies != null) ...[
                    const SizedBox(height: 20),
                    _buildFormLabel("BREED"),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(180),
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                      _buildSelectionChip("Male", selectedGender == Gender.male, () => setMState(() {
                        selectedGender = Gender.male;
                        isPregnant = false;
                        isNursing = false;
                      })),
                      const SizedBox(width: 12),
                      _buildSelectionChip("Female", selectedGender == Gender.female, () => setMState(() => selectedGender = Gender.female)),
                    ],
                  ),

                  if (selectedGender != null) ...[
                    const SizedBox(height: 20),
                    _buildFormLabel("STATUS"),
                    Row(
                      children: [
                        _buildSelectionChip(selectedGender == Gender.male ? "Neutered" : "Spayed", selectedReproductive == "Neutered/Spayed", () => setMState(() {
                          selectedReproductive = "Neutered/Spayed";
                          isPregnant = false;
                          isNursing = false;
                        })),
                        const SizedBox(width: 12),
                        _buildSelectionChip("Intact", selectedReproductive == "Intact", () => setMState(() => selectedReproductive = "Intact")),
                      ],
                    ),
                    
                    if (selectedGender == Gender.female && selectedReproductive == "Intact") ...[
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        title: const Text("Is Pregnant?", style: TextStyle(fontSize: 14)),
                        value: isPregnant,
                        onChanged: (val) => setMState(() => isPregnant = val!),
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      CheckboxListTile(
                        title: const Text("Is Nursing?", style: TextStyle(fontSize: 14)),
                        value: isNursing,
                        onChanged: (val) => setMState(() => isNursing = val!),
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
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
                          decoration: InputDecoration(
                            fillColor: Colors.white.withAlpha(180),
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
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
                    width: double.infinity,
                    height: 55,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setMState(() => selectedBirthDate = picked);
                      },
                      icon: Icon(Icons.calendar_month, color: _dustyOlive),
                      label: Text(
                        selectedBirthDate == null ? "Choose Date" : DateFormat('dd MMM yyyy').format(selectedBirthDate!), 
                        style: TextStyle(color: _darkCharcoal, fontWeight: FontWeight.bold, fontSize: 16)
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: _darkCharcoal, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  _buildFormLabel("ALLERGIES"),
                  // Two-Column Allergen Layout
                  Wrap(
                    children: commonAllergens.map((allergen) => SizedBox(
                      width: MediaQuery.of(context).size.width * 0.4, // Approx half width
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
                        activeColor: _dustyOlive,
                        checkColor: Colors.white,
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    )).toList(),
                  ),
                  CheckboxListTile(
                    title: Row(
                      children: [
                        const Text("Others: ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        Expanded(
                          child: TextField(
                            controller: otherAllergenCtrl,
                            enabled: !hasNoAllergies,
                            decoration: InputDecoration(
                              hintText: "Specify...", 
                              hintStyle: TextStyle(color: _darkCharcoal.withAlpha(120)),
                              isDense: true, 
                              border: InputBorder.none
                            ),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
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
                    activeColor: _dustyOlive,
                    checkColor: Colors.white,
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 12),
                  // "No Allergies" Radio Button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(100),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: const Text("No Allergies", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                      leading: Radio<bool>(
                        value: true,
                        groupValue: hasNoAllergies,
                        activeColor: _dustyOlive,
                        onChanged: (val) {
                          setMState(() {
                            hasNoAllergies = val!;
                            if (hasNoAllergies) selectedAllergens.clear();
                          });
                        },
                      ),
                      onTap: () {
                        setMState(() {
                          hasNoAllergies = !hasNoAllergies;
                          if (hasNoAllergies) selectedAllergens.clear();
                        });
                      },
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),

                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : () async {
                        // Validation: All sections required
                        if (nameCtrl.text.isEmpty || selectedSpecies == null || selectedBreed == null || 
                            selectedGender == null || selectedReproductive == null ||
                            selectedBirthDate == null || (!hasNoAllergies && selectedAllergens.isEmpty && otherAllergenCtrl.text.isEmpty)) {
                          _showPawDialog("Missing Information", "Please fill in all sections to create a passport.", isError: true);
                          return;
                        }

                        setMState(() => isSaving = true);

                        final uid = Provider.of<UserProvider>(context, listen: false).uid;
                        if (uid == null) {
                          setMState(() => isSaving = false);
                          return;
                        }
                        
                        PetCondition finalCond = selectedReproductive == "Neutered/Spayed" ? PetCondition.neutered : PetCondition.intact;
                        if (isNursing) finalCond = PetCondition.nursing;
                        else if (isPregnant) finalCond = PetCondition.pregnant;

                        List<String> allergens = List.from(selectedAllergens);
                        if (allergens.contains("Other")) {
                          allergens.remove("Other");
                          if (otherAllergenCtrl.text.isNotEmpty) {
                            allergens.add(otherAllergenCtrl.text.trim());
                          }
                        }

                          // Save image to Base64 so it works across devices
                        String? permanentPath;
                        if (petImage != null) {
                          permanentPath = await ImageHelper.imageToBase64(petImage!.path);
                        }

                        final newPet = PetProfile(
                          id: "", 
                          name: nameCtrl.text.trim(),
                          species: selectedSpecies!,
                          gender: selectedGender!,
                          weightKg: double.tryParse(weightCtrl.text) ?? 0.0,
                          birthDate: selectedBirthDate!,
                          condition: finalCond,
                          allergens: allergens,
                          breed: selectedBreed!,
                          imageUrl: permanentPath,
                        );

                        try {
                          await _petService.addPet(uid, newPet);
                          if (context.mounted) Navigator.pop(context);
                        } catch (e) {
                          debugPrint("Error creating pet: $e");
                          if (context.mounted) {
                            setMState(() => isSaving = false);
                            // Show the technical detail to identify if it's permission or connection
                            _showPawDialog(
                              "Creation Error", 
                              "Technical detail: $e", 
                              isError: true
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _dustyOlive,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: isSaving 
                        ? const SizedBox(
                            height: 24, 
                            width: 24, 
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          )
                        : const Text("Create Passport", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showImageSourceSheet(StateSetter setMState, Function(XFile?) onImagePicked) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Choose Photo Source", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
            const SizedBox(height: 30),
            _buildSourceTile(
              icon: Icons.camera_alt_rounded,
              label: "Take a Photo",
              onTap: () async {
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.camera,
                  maxWidth: 512, // Compress image size
                  maxHeight: 512,
                  imageQuality: 70,
                );
                onImagePicked(image);
                setMState(() {});
                if (context.mounted) Navigator.pop(context);
              }
            ),
            _buildSourceTile(
              icon: Icons.photo_library_rounded,
              label: "Choose from Gallery",
              onTap: () async {
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 512, // Compress image size
                  maxHeight: 512,
                  imageQuality: 70,
                );
                onImagePicked(image);
                setMState(() {});
                if (context.mounted) Navigator.pop(context);
              }
            ),
            _buildSourceTile(
              icon: Icons.folder_rounded,
              label: "Browse Files",
              onTap: () async {
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 512,
                  maxHeight: 512,
                  imageQuality: 70,
                ); // Fallback to gallery for browse
                onImagePicked(image);
                setMState(() {});
                if (context.mounted) Navigator.pop(context);
              }
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceTile({required IconData icon, required String label, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: _powderPetal.withAlpha(100), borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: _dustyOlive),
        title: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: _darkCharcoal)),
        onTap: onTap,
      ),
    );
  }

  void _showPawDialog(String title, String message, {required bool isError, VoidCallback? onConfirm}) {
    final Color successColor = const Color(0xFFD4C2AD);
    final Color errorColor = const Color(0xFFB56576); 
    final Color darkText = const Color(0xFF2D3142);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: Column(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: isError ? errorColor : successColor, size: 50),
            const SizedBox(height: 15),
            Text(title, style: TextStyle(color: darkText, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, textAlign: TextAlign.center, style: TextStyle(color: darkText)),
        actions: [
          Center(
            child: SizedBox(
              width: 120,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: isError ? errorColor : successColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                onPressed: () { Navigator.pop(context); if (onConfirm != null) onConfirm(); },
                child: Text("Okay", style: TextStyle(color: isError ? Colors.white : darkText, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePet(BuildContext context, String petId, String petName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Remove Passport?", style: TextStyle(color: _darkCharcoal, fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to remove the passport for $petName? This cannot be undone.", style: TextStyle(color: _darkCharcoal)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: _ashGrey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _errorCoral,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final uid = Provider.of<UserProvider>(context, listen: false).uid;
              Navigator.pop(context); // Close dialog immediately for responsiveness
              if (uid != null) {
                await _petService.deletePet(uid, petId);
              }
            },
            child: const Text("Remove", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildFormLabel(String label) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _darkCharcoal)));
  Widget _buildTextField(TextEditingController ctrl, String hint) => TextField(controller: ctrl, style: TextStyle(color: _darkCharcoal, fontWeight: FontWeight.bold), decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: _darkCharcoal.withAlpha(120)), fillColor: Colors.white.withAlpha(180), filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)));
  
  Widget _buildSelectionChip(String label, bool isSelected, VoidCallback onSelect) {
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
  
  Widget _buildStepperButton(IconData icon, VoidCallback onTap) => Container(width: 50, height: 50, decoration: BoxDecoration(color: _dustyOlive, borderRadius: BorderRadius.circular(12)), child: IconButton(icon: Icon(icon, color: Colors.white, size: 20), onPressed: onTap));

  // --- MAIN BUILD ---

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<UserProvider>().uid ?? "";

    if (uid.isEmpty) {
      debugPrint("DEBUG: User UID is empty, waiting for Provider...");
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<List<PetProfile>>(
      stream: _petService.streamUserPets(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          debugPrint("DEBUG: Stream connecting to USERS/$uid/PETS...");
          return Scaffold(
            backgroundColor: _drySage,
            body: const Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: _drySage,
            body: Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: _errorCoral, size: 50),
                    const SizedBox(height: 16),
                    Text("Profile Incomplete", style: TextStyle(color: _darkCharcoal, fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 8),
                    Text(
                      "${snapshot.error}",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _ashGrey, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => setState(() {}), 
                      style: ElevatedButton.styleFrom(backgroundColor: _dustyOlive),
                      child: const Text("Refresh Dashboard"),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final pets = snapshot.data ?? [];
        debugPrint("DEBUG: uid=$uid, petsCount=${pets.length}");
        final views = [
          _buildDashboard(context, pets),
          HealthScreen(onBackPressed: () => setState(() => _selectedIndex = 0)),
          BookingScreen(onBackPressed: () => setState(() => _selectedIndex = 0)),
          _buildProfileView(context)
        ];
        return Scaffold(backgroundColor: _drySage, body: views[_selectedIndex], bottomNavigationBar: _buildBottomNav());
      }
    );
  }

  Widget _buildDashboard(BuildContext context, List<PetProfile> pets) {
    final userName = context.watch<UserProvider>().displayName ?? 'Friend';
    final healthyCount = pets.where((p) => p.isHealthy == true).length;
    final attentionCount = pets.where((p) => p.isHealthy == false).length;
    return Column(
      children: [
        // Static Top Wave Fringe Header (pinned at top)
        DashboardFringeHeader(
          greeting: _getGreeting(),
          userName: userName,
          onLogout: () => _handleLogout(context),
        ),
        // Scrollable Body Content
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: Colors.white.withAlpha(204), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white, width: 1.5)),
                    child: Row(children: [
                      Icon(Icons.health_and_safety, color: _dustyOlive, size: 24),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text("${pets.length} registered:", style: TextStyle(color: _darkCharcoal, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text("$healthyCount healthy; $attentionCount needs attention", style: TextStyle(color: _darkCharcoal.withAlpha(180), fontSize: 14, fontWeight: FontWeight.w500)),
                      ])),
                    ]),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("My Pet Passports", style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6), 
                          decoration: BoxDecoration(color: _darkCharcoal, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 10)]), 
                          child: InkWell(
                            onTap: _showAddPetDialog, 
                            child: Text("+ Add Pet", style: TextStyle(color: _lightBronze, fontWeight: FontWeight.bold, fontSize: 17)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (pets.isEmpty)
                  Padding(padding: const EdgeInsets.symmetric(vertical: 40), child: Center(child: Text("No pets registered yet.\nTap + Add Pet to start!", textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 16))))
                else
                  SizedBox(height: 350, child: PageView.builder(controller: _pageController, itemCount: pets.length, itemBuilder: (context, index) {
                    double scale = (1 - ((_currentPage - index).abs() * 0.1)).clamp(0.8, 1.0);
                    final pet = pets[index];
                    int y = (pet.ageInMonths / 12).floor(); int m = pet.ageInMonths % 12;
                    return GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PetDetailsScreen(petId: pet.id))),
                      child: _buildPetCard(
                        scale: scale, 
                        id: pet.id,
                        name: pet.name, 
                        species: pet.species.name.toUpperCase(), 
                        breed: pet.breed, 
                        age: "${y}y, ${m}m", 
                        weight: "${pet.weightKg} kg", 
                        isHealthy: pet.isHealthy,  
                        imageUrl: pet.imageUrl,
                        context: context,
                      ),
                    );
                  })),
                const SizedBox(height: 30),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: const Text("Quick Actions", style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Colors.white))),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16), 
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
                    children: [
                      Flexible(child: _buildActionItem(Icons.restaurant, "Nutrition", _desertSand, () => _handleNutritionTap(pets))),
                      Flexible(child: _buildActionItem(Icons.medical_services, "Meds", _powderPetal, () => setState(() => _selectedIndex = 1))),
                      Flexible(child: _buildActionItem(Icons.calendar_today, "Book Vet", _desertSand, () => setState(() => _selectedIndex = 2))),
                      Flexible(child: _buildActionItem(Icons.menu_book_rounded, "Recipes", _powderPetal, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SavedRecipesScreen())))),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                _buildUpcomingRemindersSection(context, context.watch<UserProvider>().uid ?? "", pets),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileView(BuildContext context) {
    final up = context.watch<UserProvider>();
    return Container(
      color: _drySage,
      child: Column(
        children: [
          const FringeHeader(
            title: "My Profile",
            subtitle: "Account & Settings",
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: _powderPetal,
                    child: Text(
                      up.displayName?.isNotEmpty == true
                          ? up.displayName!.substring(0, 1).toUpperCase()
                          : "?",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: _dustyOlive,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    up.displayName ?? "User",
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    up.email ?? "",
                    style: const TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                  const SizedBox(height: 24),
                  _profileTile(
                    Icons.person,
                    "Edit Profile",
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Edit Profile module coming soon!")),
                      );
                    },
                  ),
                  _profileTile(
                    Icons.pets,
                    "Manage My Pets",
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Manage My Pets module coming soon!")),
                      );
                    },
                  ),
                  _profileTile(
                    Icons.notifications,
                    "Notifications",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationCenterScreen(),
                        ),
                      );
                    },
                  ),
                  _profileTile(
                    Icons.security,
                    "Privacy & Security",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrivacySecurityScreen(),
                        ),
                      );
                    },
                  ),
                  _profileTile(
                    Icons.help_outline,
                    "Help & Support",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HelpSupportScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => _handleLogout(context),
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text(
                        "Logout",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _errorCoral,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileTile(IconData i, String t, {VoidCallback? onTap}) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(30),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          onTap: onTap,
          leading: Icon(i, color: Colors.white),
          title: Text(
            t,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 17,
            ),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.white70),
        ),
      );

  Widget _buildPetCard({
    required double scale, 
    required String id, // Added ID for deletion
    required String name, 
    required String species, 
    required String breed, 
    required String age, 
    required String weight, 
    required bool? isHealthy, 
    required String? imageUrl,
    required BuildContext context, // Added context for dialogs
  }) {
    ImageProvider? imgProvider = ImageHelper.getImageProvider(imageUrl);

    return Transform.scale(
      scale: scale, 
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), 
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(32), 
          border: Border.all(color: _ashGrey.withAlpha(50), width: 1.5), 
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 20, offset: const Offset(0, 10))]
        ), 
        child: Column(
          children: [
            Expanded(
              flex: 3, 
              child: Stack(
                children: [
                  Container(
                    width: double.infinity, 
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)), 
                      color: const Color(0xFFF0F0F0),
                      image: imgProvider != null ? DecorationImage(image: imgProvider, fit: BoxFit.cover) : null,
                    ),
                    child: imgProvider == null 
                      ? Center(
                          child: Icon(
                            species.toLowerCase() == 'cat' ? Icons.pets : Icons.pets, 
                            size: 80, 
                            color: _ashGrey.withAlpha(150)
                          ),
                        ) 
                      : null,
                  ), 
                  // Delete Button
                  Positioned(
                    top: 15,
                    left: 15,
                    child: InkWell(
                      onTap: () => _confirmDeletePet(context, id, name),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(200),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.delete_outline_rounded, color: _errorCoral, size: 20),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 20, 
                    right: 20, 
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), 
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(220), 
                        borderRadius: BorderRadius.circular(20), 
                        boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 5)],
                        border: isHealthy == null ? Border.all(color: _ashGrey.withAlpha(100), width: 1.5) : null,
                      ), 
                      child: Row(
                        mainAxisSize: MainAxisSize.min, 
                        children: [
                          if (isHealthy != null)
                            CircleAvatar(radius: 4, backgroundColor: isHealthy ? Colors.green : Colors.red), 
                          if (isHealthy != null)
                            const SizedBox(width: 6), 
                          Text(
                            isHealthy == null ? "Log Health Now" : (isHealthy ? "Healthy" : "Needs Attention"), 
                            style: TextStyle(
                              fontSize: 10, 
                              fontWeight: FontWeight.bold, 
                              color: isHealthy == null ? _darkCharcoal : (isHealthy ? Colors.green : Colors.red)
                            ),
                          ),
                          if (isHealthy == null) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios_rounded, size: 8, color: _darkCharcoal),
                          ]
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2, 
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 6), 
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: 260,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, 
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                          children: [
                            Expanded(
                              child: Text(
                                name, 
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _darkCharcoal),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ), 
                            const SizedBox(width: 8),
                            Text(species, style: TextStyle(color: _ashGrey, fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ), 
                        Text(breed, style: TextStyle(color: _ashGrey, fontSize: 14), overflow: TextOverflow.ellipsis), 
                        const SizedBox(height: 4), 
                        Row(
                          children: [
                            Expanded(child: _buildInfoChip("Age", age)), 
                            const SizedBox(width: 8), 
                            Expanded(child: _buildInfoChip("Weight", weight)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UPCOMING REMINDERS SYNC SECTION ---

  Widget _buildUpcomingRemindersSection(BuildContext context, String uid, List<PetProfile> pets) {
    if (uid.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<List<ReminderItem>>(
      stream: _reminderService.streamUpcomingReminders(uid, pets),
      builder: (context, snapshot) {
        final reminders = snapshot.data ?? [];
        final isLoading = snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Upcoming Reminders",
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  if (reminders.length > 3)
                    GestureDetector(
                      onTap: () => _showAllRemindersBottomSheet(context, reminders, pets),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(40),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "View All (${reminders.length})",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: _dustyOlive),
                      ),
                      const SizedBox(width: 16),
                      Text("Loading upcoming reminders...", style: TextStyle(color: _ashGrey, fontSize: 15)),
                    ],
                  ),
                ),
              )
            else if (reminders.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(8),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _powderPetal,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.event_available_rounded, color: _dustyOlive, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "All Caught Up!",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                    color: _darkCharcoal,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "No pending vet bookings or vaccine/deworm reminders.",
                                  style: TextStyle(color: _ashGrey, fontSize: 13, height: 1.2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => setState(() => _selectedIndex = 2),
                              icon: Icon(Icons.calendar_month_rounded, size: 16, color: _dustyOlive),
                              label: Text("Book Vet", style: TextStyle(color: _dustyOlive, fontWeight: FontWeight.bold, fontSize: 13)),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: _dustyOlive.withAlpha(100)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => setState(() => _selectedIndex = 1),
                              icon: const Icon(Icons.vaccines_rounded, size: 16, color: Colors.white),
                              label: const Text("Vax & Deworm", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _dustyOlive,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: reminders.take(3).map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildReminderCard(context, item, pets),
                    );
                  }).toList(),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildReminderCard(BuildContext context, ReminderItem item, List<PetProfile> pets) {
    IconData iconData;
    Color iconBgColor;
    Color iconColor;
    String badgeText;

    switch (item.type) {
      case ReminderType.booking:
        iconData = Icons.calendar_month_rounded;
        iconBgColor = _dustyOlive.withAlpha(30);
        iconColor = _dustyOlive;
        badgeText = "VET BOOKING";
        break;
      case ReminderType.vaccine:
        iconData = Icons.vaccines_rounded;
        iconBgColor = _lightBronze.withAlpha(35);
        iconColor = _lightBronze;
        badgeText = "VACCINE";
        break;
      case ReminderType.deworming:
        iconData = Icons.medication_liquid_rounded;
        iconBgColor = _desertSand.withAlpha(60);
        iconColor = _darkCharcoal;
        badgeText = "DEWORMS";
        break;
    }

    final isUrgent = item.isUrgent;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      elevation: 0,
      child: InkWell(
        onTap: () => _handleReminderTap(context, item, pets),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isUrgent ? _errorCoral.withAlpha(80) : Colors.black.withAlpha(15),
              width: isUrgent ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(6),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: iconBgColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: iconColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isUrgent ? _errorCoral.withAlpha(25) : _dustyOlive.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.dateStatusText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isUrgent ? _errorCoral : _dustyOlive,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _darkCharcoal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        color: _ashGrey,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: _ashGrey, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  void _handleReminderTap(BuildContext context, ReminderItem item, List<PetProfile> pets) {
    if (item.type == ReminderType.booking) {
      // Switch to Booking tab
      setState(() => _selectedIndex = 2);
    } else {
      // Find matching pet
      PetProfile? pet;
      try {
        pet = pets.firstWhere((p) => p.id == item.petId);
      } catch (_) {
        try {
          pet = pets.firstWhere((p) => p.name.toLowerCase() == item.petName.toLowerCase());
        } catch (_) {
          pet = pets.isNotEmpty ? pets.first : null;
        }
      }

      if (pet != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => VaccinationScreen(pet: pet!)),
        );
      } else {
        setState(() => _selectedIndex = 1);
      }
    }
  }

  void _showAllRemindersBottomSheet(BuildContext context, List<ReminderItem> reminders, List<PetProfile> pets) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: BoxDecoration(
            color: _powderPetal,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _ashGrey.withAlpha(120),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "All Upcoming Reminders (${reminders.length})",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _darkCharcoal,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: _darkCharcoal),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: reminders.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = reminders[index];
                    return _buildReminderCard(context, item, pets);
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(String l, String v) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
    decoration: BoxDecoration(color: _ashGrey.withAlpha(140), borderRadius: BorderRadius.circular(12)), 
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Text(l, style: TextStyle(fontSize: 11, color: _dustyOlive, fontWeight: FontWeight.bold)), 
          Text(v, style: TextStyle(fontSize: 15, color: _darkCharcoal, fontWeight: FontWeight.bold)),
        ],
      ),
    ),
  );
  Widget _buildActionItem(IconData i, String l, Color c, VoidCallback o) => InkWell(onTap: o, borderRadius: BorderRadius.circular(18), child: Column(mainAxisSize: MainAxisSize.min, children: [Container(height: 60, width: 60, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 3))]), child: Icon(i, color: _dustyOlive, size: 26)), const SizedBox(height: 6), Text(l, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis)]));
  Widget _buildBottomNav() => Container(height: 75, decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)), boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 15)]), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_navIcon(Icons.home_filled, "Home", 0), _navIcon(Icons.favorite_border, "Health", 1), _navIcon(Icons.calendar_month_outlined, "Bookings", 2), _navIcon(Icons.person_outline, "Profile", 3)]));
  Widget _navIcon(IconData i, String l, int idx) => InkWell(onTap: () => setState(() => _selectedIndex = idx), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(i, color: _selectedIndex == idx ? _dustyOlive : _ashGrey, size: 26), const SizedBox(height: 4), Text(l, style: TextStyle(fontSize: 10, color: _selectedIndex == idx ? _dustyOlive : _ashGrey, fontWeight: _selectedIndex == idx ? FontWeight.bold : FontWeight.normal))]));
}
